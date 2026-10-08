const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');
const { getSessionCheck } = require('../services/deviceSessionCache');
const { getUser } = require('../services/userCache');

const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      if (decoded.deviceId) {
        const device = await getSessionCheck(decoded.id, decoded.deviceId);
        if (!device.found || !device.isActive || device.tokenVersion !== decoded.tokenVersion) {
          return res.status(401).json({ success: false, code: 'SESSION_REVOKED', message: 'This session has been logged out' });
        }
        req.deviceId = decoded.deviceId;
      }

      req.user = {
        _id: decoded.id,
        id: decoded.id,
        role: decoded.role, // only works if `role` was signed into the token at login
      };

      return next();
    } catch (error) {
      logger.error(error);
      return res.status(401).json({ success: false, message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    return res.status(401).json({ success: false, message: 'Not authorized, no token provided' });
  }
};

const adminOnly = async (req, res, next) => {
  try {
    const user = await getUser(req.user?.id);
    if (user && user.role === 'admin') {
      req.user.role = user.role;
      return next();
    }
    return res.status(403).json({ success: false, message: 'Access denied: Administrative privileges required' });
  } catch (error) {
    logger.error(error);
    return res.status(403).json({ success: false, message: 'Access denied: Administrative privileges required' });
  }
};

module.exports = { protect, adminOnly };
