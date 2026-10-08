const { runSchema, OBJECT_ID_RE } = require('../utils/validators');

const respond = (res, errors) =>
  res.status(400).json({
    success: false,
    message: errors[0].message,
    errors,
  });

const isPlainObject = (value) =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

/**
 * Validates and rewrites req.body / req.query / req.params from a schema.
 *
 * Options:
 *   body, query, params — field-name -> rule maps (see utils/validators)
 *   allowUnknown        — keep undeclared body keys instead of dropping them
 *   maxBytes            — cap on the serialized body
 *   check               — cross-field rules: fn(req) -> error string | null
 */
const validate = (options = {}) => {
  const { body, query, params, allowUnknown = false, maxBytes, check } = options;

  return (req, res, next) => {
    const errors = [];

    if (body || maxBytes) {
      const source = req.body === undefined ? {} : req.body;
      if (!isPlainObject(source)) {
        return respond(res, [{ field: 'body', message: 'Request body must be a JSON object' }]);
      }
      if (maxBytes && JSON.stringify(source).length > maxBytes) {
        return respond(res, [{ field: 'body', message: `Request body must be ${maxBytes} bytes or fewer` }]);
      }
      if (body) {
        const result = runSchema(body, source);
        errors.push(...result.errors);
        req.body = allowUnknown ? { ...source, ...result.value } : result.value;
      }
    }

    if (query) {
      const result = runSchema(query, req.query || {});
      errors.push(...result.errors);
      req.query = result.value;
    }

    if (params) {
      const result = runSchema(params, req.params || {});
      errors.push(...result.errors);
      Object.assign(req.params, result.value);
    }

    if (errors.length > 0) return respond(res, errors);

    if (check) {
      const rules = Array.isArray(check) ? check : [check];
      for (const rule of rules) {
        const message = rule(req);
        if (message) return respond(res, [{ field: 'body', message }]);
      }
    }

    return next();
  };
};

/** router.param handler: rejects a path segment that is not an ObjectId. */
const objectIdParam = (name) => (req, res, next, value) => {
  if (typeof value !== 'string' || !OBJECT_ID_RE.test(value)) {
    return respond(res, [{ field: name, message: `${name} must be a valid id` }]);
  }
  return next();
};

/** router.param handler for a free-form segment (device ids, codes). */
const stringParam = (name, { max = 128, pattern } = {}) => (req, res, next, value) => {
  if (typeof value !== 'string' || value.length === 0 || value.length > max) {
    return respond(res, [{ field: name, message: `${name} must be 1 to ${max} characters` }]);
  }
  if (pattern && !pattern.test(value)) {
    return respond(res, [{ field: name, message: `${name} is not valid` }]);
  }
  return next();
};

/** Registers the id-shaped params every router shares. */
const registerIdParams = (router, names = ['id', 'userId', 'chatId']) => {
  for (const name of names) router.param(name, objectIdParam(name));
  return router;
};

module.exports = { validate, objectIdParam, stringParam, registerIdParams };
