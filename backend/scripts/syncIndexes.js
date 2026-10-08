/**
 * Reconciles the indexes in MongoDB with the ones declared on the schemas.
 *
 * Mongoose's autoIndex only ever *creates* indexes. It never drops one you
 * deleted from a schema, and it cannot change the options on an existing one:
 * re-declaring the same key pattern with different options (sparse -> partial,
 * say) makes MongoDB reject the build with IndexOptionsConflict, and Mongoose
 * swallows that as a model-level 'index' event. The stale index just stays.
 *
 * syncIndexes() closes both gaps — it drops indexes present in the database
 * but absent from the schema, then builds whatever is missing.
 *
 * Usage:
 *   node scripts/syncIndexes.js            # dry run: report the plan, change nothing
 *   node scripts/syncIndexes.js --apply    # execute it
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

const APPLY = process.argv.includes('--apply');
const MODELS_DIR = path.join(__dirname, '..', 'src', 'models');

// Index builds hold no collection-level lock in a modern replica set, but a
// rebuild on a large collection still costs real I/O. Reported so an operator
// can pick the window rather than be surprised by it.
const HEAVY_COLLECTIONS = new Set(['messages', 'chats', 'chatmembers']);

const keyOf = (spec) => JSON.stringify(spec);

const loadModels = () =>
  fs
    .readdirSync(MODELS_DIR)
    .filter((f) => f.endsWith('.js'))
    .map((f) => require(path.join(MODELS_DIR, f)))
    .filter((m) => m && m.schema && typeof m.collection?.name === 'string');

const planFor = async (model) => {
  const collection = model.collection;

  let live = [];
  try {
    live = await collection.indexes();
  } catch (err) {
    // Collection does not exist yet — nothing to drop, everything to create.
    if (err.codeName !== 'NamespaceNotFound') throw err;
  }

  // What the schema asks for, in the same shape listIndexes() returns.
  const declared = model.schema.indexes().map(([spec, opts]) => ({ spec, opts }));

  const drops = live
    .filter((idx) => idx.name !== '_id_')
    .filter((idx) => {
      const match = declared.find((d) => keyOf(d.spec) === keyOf(idx.key));
      if (!match) return true; // no longer declared

      // Same keys — drop when the options changed, since MongoDB will not
      // rebuild an existing index in place.
      const wantUnique = !!match.opts.unique;
      const wantSparse = !!match.opts.sparse;
      const wantPartial = keyOf(match.opts.partialFilterExpression || null);
      const wantTtl = match.opts.expireAfterSeconds;

      return (
        wantUnique !== !!idx.unique ||
        wantSparse !== !!idx.sparse ||
        wantPartial !== keyOf(idx.partialFilterExpression || null) ||
        wantTtl !== idx.expireAfterSeconds
      );
    })
    .map((idx) => ({ name: idx.name, key: idx.key }));

  const liveKeys = new Set(live.map((i) => keyOf(i.key)));
  const droppedKeys = new Set(drops.map((d) => keyOf(d.key)));
  const creates = declared.filter(
    (d) => !liveKeys.has(keyOf(d.spec)) || droppedKeys.has(keyOf(d.spec))
  );

  return { collection: collection.name, drops, creates };
};

const run = async () => {
  if (!process.env.MONGO_URI) {
    console.error('MONGO_URI is not set — check your .env');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGO_URI, { dbName: 'talkmos' });
  console.log(`Connected to "talkmos"${APPLY ? '' : '  (DRY RUN — no changes)'}\n`);

  const models = loadModels();
  let totalDrops = 0;
  let totalCreates = 0;
  const heavy = [];

  for (const model of models) {
    const { collection, drops, creates } = await planFor(model);
    if (!drops.length && !creates.length) continue;

    console.log(`── ${model.modelName}  (${collection})`);
    for (const d of drops) {
      console.log(`    DROP    ${d.name}  ${keyOf(d.key)}`);
    }
    for (const c of creates) {
      const flags = [
        c.opts.unique && 'unique',
        c.opts.sparse && 'sparse',
        c.opts.partialFilterExpression && 'partial',
        c.opts.expireAfterSeconds !== undefined && 'ttl',
      ].filter(Boolean);
      console.log(
        `    CREATE  ${keyOf(c.spec)}${flags.length ? `  [${flags.join(',')}]` : ''}`
      );
    }

    totalDrops += drops.length;
    totalCreates += creates.length;
    if (HEAVY_COLLECTIONS.has(collection) && creates.length) heavy.push(collection);

    if (APPLY) {
      // syncIndexes performs exactly the drop-then-create reconciliation
      // reported above, in one round trip per collection.
      await model.syncIndexes();
      console.log('    ✓ synced');
    }
    console.log();
  }

  if (!totalDrops && !totalCreates) {
    console.log('Indexes already match the schemas — nothing to do.');
  } else {
    console.log(`${totalDrops} to drop, ${totalCreates} to create.`);
    if (heavy.length) {
      console.log(
        `\nNote: builds on ${[...new Set(heavy)].join(', ')} scan the full ` +
          `collection. Run these off-peak on a large dataset.`
      );
    }
    if (!APPLY) console.log('\nRe-run with --apply to execute.');
  }

  await mongoose.disconnect();
};

run().catch(async (err) => {
  console.error(`\nsyncIndexes failed: ${err.message}`);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
