const mongoose = require('mongoose');

const AuditLogSchema = new mongoose.Schema(
  {
    adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    adminEmail: { type: String },
    method: { type: String, required: true },
    path: { type: String, required: true },
    body: { type: mongoose.Schema.Types.Mixed },
    params: { type: mongoose.Schema.Types.Mixed },
    query: { type: mongoose.Schema.Types.Mixed },
    statusCode: { type: Number },
    ipAddress: { type: String },
  },
  { timestamps: true }
);

// Admin log viewer: find().sort({ createdAt: -1 }).skip().limit()
AuditLogSchema.index({ createdAt: -1 });

module.exports = mongoose.model('AuditLog', AuditLogSchema);
