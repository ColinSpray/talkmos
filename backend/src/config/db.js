const mongoose = require('mongoose');
const logger = require('../utils/logger');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI, {
      dbName: 'talkmos',
      autoIndex: process.env.MONGO_AUTO_INDEX === 'true',
      maxPoolSize: parseInt(process.env.MONGO_POOL_SIZE || '15', 10),
    });
    logger.info('MongoDB Connected successfully.');
  } catch (error) {
    logger.error(`MongoDB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = { connectDB };
