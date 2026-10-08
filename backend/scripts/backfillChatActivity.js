/**
 * Backfills the two denormalized fields the chat read paths now depend on:
 *
 *   Chat.lastMessageAt              — newest message's timestamp, the sort key
 *                                     for the conversation list
 *   UserChatPreference.lastReadAt   — lastReadMessage's timestamp, the read
 *                                     cursor the unread counts compare against
 *
 * Both are derived, so this is safe to re-run: it recomputes from messages
 * rather than incrementing anything.
 *
 * Until it has run, existing chats keep the schema default for lastMessageAt
 * (their creation time), so the conversation list orders by chat age instead
 * of by recent activity, and every unread count reads as if nothing has been
 * read. New messages and new reads self-correct from the moment the code
 * deploys — this only fixes history.
 *
 * Usage:
 *   node scripts/backfillChatActivity.js          # dry run: report, change nothing
 *   node scripts/backfillChatActivity.js --apply  # execute
 */

require('dotenv').config();
const mongoose = require('mongoose');

const Chat = require('../src/models/Chat');
const Message = require('../src/models/Message');
const UserChatPreference = require('../src/models/UserChatPreference');
const User = require('../src/models/User');
const FriendRequest = require('../src/models/FriendRequest');

const APPLY = process.argv.includes('--apply');
const BATCH = 1000;

const flush = async (model, ops) => {
  if (!APPLY || ops.length === 0) return;
  await model.bulkWrite(ops, { ordered: false });
};

const backfillLastMessageAt = async () => {
  console.log('── Chat.lastMessageAt');

  // One pass over messages, grouped per chat, rather than a query per chat.
  // allowDiskUse because the group set is unbounded on a large deployment.
  const cursor = Message.aggregate([
    { $group: { _id: '$chatId', last: { $max: '$createdAt' } } },
  ])
    .allowDiskUse(true)
    .cursor();

  let ops = [];
  let matched = 0;

  for await (const row of cursor) {
    if (!row._id) continue;
    matched += 1;
    ops.push({
      updateOne: {
        filter: { _id: row._id },
        update: { $set: { lastMessageAt: row.last } },
      },
    });
    if (ops.length >= BATCH) {
      await flush(Chat, ops);
      ops = [];
      process.stdout.write(`    ${matched} chats\r`);
    }
  }
  await flush(Chat, ops);

  // Chats that never received a message keep their creation time, so they
  // still sort sensibly instead of falling to the bottom as nulls.
  const emptyFilter = { lastMessageAt: null };
  const empty = await Chat.countDocuments(emptyFilter);
  if (APPLY && empty > 0) {
    await Chat.updateMany(emptyFilter, [{ $set: { lastMessageAt: '$createdAt' } }]);
  }

  console.log(`    ${matched} chats with messages, ${empty} without (fall back to createdAt)`);
};

const backfillLastReadAt = async () => {
  console.log('── UserChatPreference.lastReadAt');

  const filter = { lastReadMessage: { $ne: null } };
  const total = await UserChatPreference.countDocuments(filter);

  const cursor = UserChatPreference.find(filter)
    .select('_id lastReadMessage')
    .lean()
    .cursor();

  let batch = [];
  let resolved = 0;
  let dangling = 0;

  const processBatch = async () => {
    if (batch.length === 0) return;

    // Resolve the whole batch's timestamps in one query instead of per row.
    const ids = batch.map((p) => p.lastReadMessage);
    const messages = await Message.find({ _id: { $in: ids } })
      .select('_id createdAt')
      .lean();
    const timeById = new Map(messages.map((m) => [String(m._id), m.createdAt]));

    const ops = [];
    for (const pref of batch) {
      const at = timeById.get(String(pref.lastReadMessage));
      // The referenced message can be gone — hard-deleted, or from a chat that
      // was cleared. Leaving lastReadAt null is the honest answer: those chats
      // read as fully unread rather than silently swallowing messages.
      if (!at) {
        dangling += 1;
        continue;
      }
      resolved += 1;
      ops.push({
        updateOne: { filter: { _id: pref._id }, update: { $set: { lastReadAt: at } } },
      });
    }

    await flush(UserChatPreference, ops);
    batch = [];
  };

  for await (const pref of cursor) {
    batch.push(pref);
    if (batch.length >= BATCH) {
      await processBatch();
      process.stdout.write(`    ${resolved}/${total}\r`);
    }
  }
  await processBatch();

  console.log(
    `    ${resolved} of ${total} preferences resolved` +
      (dangling ? `, ${dangling} pointed at a missing message (left null)` : '')
  );
};

const backfillPhoneSuffix = async () => {
  console.log('── User.phoneSuffix');

  const filter = { phone: { $ne: null } };
  const total = await User.countDocuments(filter);

  const cursor = User.find(filter).select('_id phone').lean().cursor();

  let ops = [];
  let resolved = 0;
  let tooShort = 0;

  for await (const user of cursor) {
    const suffix = User.phoneSuffixOf(user.phone);
    // Numbers with fewer than ten digits cannot produce a full suffix, and a
    // partial one would match strangers. They stay null and simply never
    // match a contact.
    if (!suffix) {
      tooShort += 1;
      continue;
    }
    resolved += 1;
    ops.push({ updateOne: { filter: { _id: user._id }, update: { $set: { phoneSuffix: suffix } } } });
    if (ops.length >= BATCH) {
      await flush(User, ops);
      ops = [];
      process.stdout.write(`    ${resolved}/${total}\r`);
    }
  }
  await flush(User, ops);

  console.log(
    `    ${resolved} of ${total} users indexed` +
      (tooShort ? `, ${tooShort} with too few digits (left null)` : '')
  );
};

/**
 * Populates FriendRequest.pairKey and resolves any reciprocal duplicates.
 *
 * Must run BEFORE scripts/syncIndexes.js: the unique index on pairKey cannot
 * build while two rows describe the same relationship, which is exactly the
 * situation this field exists to prevent going forward.
 *
 * Where a pair has more than one row, one is kept by this rule — an accepted
 * friendship outranks a pending request, which outranks a rejected one, and
 * the newest wins a tie. That preserves the strongest established state
 * rather than whichever row happened to be written last.
 */
const RANK = { accepted: 3, pending: 2, rejected: 1 };

const backfillFriendPairKey = async () => {
  console.log('── FriendRequest.pairKey');

  const rows = await FriendRequest.find({})
    .select('_id sender receiver status createdAt')
    .lean();

  const byPair = new Map();
  for (const r of rows) {
    const key = FriendRequest.pairKeyOf(r.sender, r.receiver);
    if (!key) continue;
    if (!byPair.has(key)) byPair.set(key, []);
    byPair.get(key).push(r);
  }

  const ops = [];
  const deletions = [];
  let duplicatePairs = 0;

  for (const [key, group] of byPair) {
    if (group.length > 1) {
      duplicatePairs += 1;
      group.sort((a, b) => {
        const byStatus = (RANK[b.status] || 0) - (RANK[a.status] || 0);
        if (byStatus !== 0) return byStatus;
        return new Date(b.createdAt) - new Date(a.createdAt);
      });
    }
    const [keep, ...drop] = group;
    ops.push({ updateOne: { filter: { _id: keep._id }, update: { $set: { pairKey: key } } } });
    for (const d of drop) deletions.push(d._id);
  }

  for (let i = 0; i < ops.length; i += BATCH) {
    await flush(FriendRequest, ops.slice(i, i + BATCH));
  }
  if (APPLY && deletions.length > 0) {
    await FriendRequest.deleteMany({ _id: { $in: deletions } });
  }

  console.log(
    `    ${ops.length} relationships keyed` +
      (duplicatePairs
        ? `, ${duplicatePairs} duplicate pair(s) resolved (${deletions.length} row(s) removed)`
        : ', no duplicates found')
  );
};

const run = async () => {
  if (!process.env.MONGO_URI) {
    console.error('MONGO_URI is not set — check your .env');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGO_URI, { dbName: 'talkmos' });
  console.log(`Connected to "talkmos"${APPLY ? '' : '  (DRY RUN — no writes)'}\n`);

  await backfillLastMessageAt();
  await backfillLastReadAt();
  await backfillPhoneSuffix();
  await backfillFriendPairKey();

  if (!APPLY) console.log('\nRe-run with --apply to write.');
  await mongoose.disconnect();
};

run().catch(async (err) => {
  console.error(`\nbackfill failed: ${err.message}`);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
