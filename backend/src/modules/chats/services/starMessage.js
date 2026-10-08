const StarredMessage = require('../../../models/StarredMessage');

const starMessage = async ({ messageId, userId, isStarred }) => {
  if (!isStarred) {
    await StarredMessage.deleteOne({ messageId, userId });
    return { status: 'unstarred' };
  }

  const star = await StarredMessage.findOneAndUpdate(
    { messageId, userId },
    {},
    { upsert: true, new: true }
  );

  return { status: 'starred', star };
};

module.exports = starMessage;
