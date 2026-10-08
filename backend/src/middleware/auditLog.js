const AuditLog = require('../models/AuditLog');
const logger = require('../utils/logger');

const auditLog = (req, res, next) => {
  res.on('finish', async () => {
    try {
      await AuditLog.create({
        adminId: req.user?._id,
        adminEmail: req.user?.email || req.user?.phone,
        method: req.method,
        path: req.originalUrl,
        body: req.body,
        params: req.params,
        query: req.query,
        statusCode: res.statusCode,
        ipAddress: req.ip,
      });
    } catch (err) {
      logger.error(`[AUDIT] Failed to write audit log: ${err.message}`);
    }
  });
  next();
};

module.exports = auditLog;
