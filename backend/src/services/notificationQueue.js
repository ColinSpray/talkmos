const amqp = require('amqplib');
const logger = require('../utils/logger');

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://guest:guest@localhost:5672/';
const EXCHANGE = 'notifications';

let channelPromise = null;

const getChannel = () => {
  if (channelPromise) return channelPromise;

  channelPromise = (async () => {
    const conn = await amqp.connect(RABBITMQ_URL);
    conn.on('error', (err) => {
      logger.error(`[notificationQueue] connection error: ${err.message}`);
      channelPromise = null;
    });
    conn.on('close', () => {
      channelPromise = null;
    });

    const ch = await conn.createChannel();
    await ch.assertExchange(EXCHANGE, 'topic', { durable: true });
    return ch;
  })();

  channelPromise.catch(() => {
    channelPromise = null;
  });

  return channelPromise;
};

const publish = async (routingKey, payload) => {
  try {
    const ch = await getChannel();
    return ch.publish(EXCHANGE, routingKey, Buffer.from(JSON.stringify(payload)), {
      contentType: 'application/json',
      persistent: true,
    });
  } catch (err) {
    logger.error(`[notificationQueue] publish to ${routingKey} failed: ${err.message}`);
    return false;
  }
};

/** @param {{token: string, title: string, body: string, data?: Record<string,string>}} job */
const publishFCM = (job) => publish('notification.fcm', job);

/** @param {{to: string, subject: string, body: string, isHtml?: boolean}} job */
const publishMail = (job) => publish('notification.mail', job);

/** @param {{to: string, message: string}} job */
const publishSMS = (job) => publish('notification.sms', job);

module.exports = { publishFCM, publishMail, publishSMS };
