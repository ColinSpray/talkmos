const isEmailFormat = require('validator/lib/isEmail');
const isUrlFormat = require('validator/lib/isURL');

const OBJECT_ID_RE = /^[a-f\d]{24}$/i;
const USERNAME_RE = /^[a-zA-Z0-9._-]+$/;
const PHONE_RE = /^\+?[0-9][0-9\s\-().]{5,19}$/;
const DIGITS_RE = /^[0-9]+$/;
const MIME_RE = /^[\w.+-]+\/[\w.+-]+$/;

// Thrown by a rule, caught by runSchema — never escapes to the caller. `field`
// carries the nested path so an error inside an object or array is reported
// against the exact key that caused it, not its container.
const fail = (message, field) => {
  const err = new Error(message);
  err.isValidation = true;
  if (field) err.field = field;
  throw err;
};

const missing = (value) => value === undefined || value === null;

// Copies only the fields the schema declares, so unknown keys can never reach
// a model and set something the route never meant to expose.
const runSchema = (schema, source, prefix = '') => {
  const value = {};
  const errors = [];

  for (const [field, rule] of Object.entries(schema)) {
    const path = prefix ? `${prefix}.${field}` : field;
    const raw = source[field];

    if (missing(raw)) {
      if (rule.required) {
        errors.push({ field: path, message: `${path} is required` });
      } else if (rule.default !== undefined) {
        value[field] = typeof rule.default === 'function' ? rule.default() : rule.default;
      }
      continue;
    }

    try {
      value[field] = rule.validate(raw, path);
    } catch (err) {
      if (!err.isValidation) throw err;
      errors.push({ field: err.field || path, message: err.message });
    }
  }

  return { value, errors };
};

const str = (opts = {}) => {
  const required = !!opts.required;
  const min = opts.min !== undefined ? opts.min : (required ? 1 : 0);
  const max = opts.max !== undefined ? opts.max : 500;

  return {
    required,
    default: opts.default,
    validate: (raw, field) => {
      if (typeof raw !== 'string') fail(`${field} must be a string`);
      let out = opts.trim === false ? raw : raw.trim();
      if (opts.lower) out = out.toLowerCase();

      if (out.length < min) {
        fail(min === 1 ? `${field} is required` : `${field} must be at least ${min} characters`);
      }
      if (out.length > max) fail(opts.maxMessage || `${field} must be ${max} characters or fewer`);
      if (opts.values && !opts.values.includes(out)) {
        fail(`${field} must be one of: ${opts.values.join(', ')}`);
      }
      // An empty optional string means "clear this field", so a format rule
      // has nothing to check.
      if (opts.pattern && out.length > 0 && !opts.pattern.test(out)) {
        fail(`${field} ${opts.message || 'is not valid'}`);
      }
      return out;
    },
  };
};

const objectId = (opts = {}) => ({
  required: !!opts.required,
  default: opts.default,
  validate: (raw, field) => {
    if (typeof raw !== 'string' || !OBJECT_ID_RE.test(raw)) fail(`${field} must be a valid id`);
    return raw;
  },
});

const bool = (opts = {}) => ({
  required: !!opts.required,
  default: opts.default,
  validate: (raw, field) => {
    if (typeof raw === 'boolean') return raw;
    if (raw === 'true' || raw === '1') return true;
    if (raw === 'false' || raw === '0') return false;
    return fail(`${field} must be true or false`);
  },
});

// `clamp` pins an out-of-range value to the bound instead of rejecting it —
// used for pagination limits, where a too-large page size is not a client error.
const num = (opts = {}) => ({
  required: !!opts.required,
  default: opts.default,
  validate: (raw, field) => {
    const parsed = typeof raw === 'string' ? Number(raw.trim()) : raw;
    if (typeof parsed !== 'number' || !Number.isFinite(parsed)) fail(`${field} must be a number`);
    if (opts.integer && !Number.isInteger(parsed)) fail(`${field} must be a whole number`);

    let out = parsed;
    if (opts.min !== undefined && out < opts.min) {
      if (!opts.clamp) fail(`${field} must be ${opts.min} or greater`);
      out = opts.min;
    }
    if (opts.max !== undefined && out > opts.max) {
      if (!opts.clamp) fail(`${field} must be ${opts.max} or less`);
      out = opts.max;
    }
    return out;
  },
});

const arr = (opts = {}) => {
  const required = !!opts.required;
  const min = opts.min !== undefined ? opts.min : 0;
  const max = opts.max !== undefined ? opts.max : 100;

  return {
    required,
    default: opts.default,
    validate: (raw, field) => {
      if (!Array.isArray(raw)) fail(`${field} must be an array`);
      if (raw.length < min) {
        fail(min === 1 ? `${field} must not be empty` : `${field} must have at least ${min} items`);
      }
      if (raw.length > max) fail(`${field} must have ${max} items or fewer`);
      if (!opts.of) return raw;
      return raw.map((item, index) => {
        const path = `${field}[${index}]`;
        if (missing(item)) fail(`${path} is required`, path);
        try {
          return opts.of.validate(item, path);
        } catch (err) {
          throw err.isValidation ? fail(err.message, err.field || path) : err;
        }
      });
    },
  };
};

const obj = (opts = {}) => ({
  required: !!opts.required,
  default: opts.default,
  validate: (raw, field) => {
    if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) {
      fail(`${field} must be an object`);
    }
    if (!opts.shape) return raw;
    const { value, errors } = runSchema(opts.shape, raw, field);
    if (errors.length > 0) fail(errors[0].message, errors[0].field);
    return value;
  },
});

// Free-form payload (Mongoose Mixed). Bounded by serialized size so a client
// cannot store an arbitrarily large blob through a metadata field.
const json = (opts = {}) => {
  const maxBytes = opts.maxBytes !== undefined ? opts.maxBytes : 4096;
  return {
    required: !!opts.required,
    default: opts.default,
    validate: (raw, field) => {
      if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) {
        fail(`${field} must be an object`);
      }
      let serialized;
      try {
        serialized = JSON.stringify(raw);
      } catch {
        fail(`${field} must be serializable`);
      }
      if (serialized.length > maxBytes) fail(`${field} must be ${maxBytes} bytes or fewer`);
      return raw;
    },
  };
};

const email = (opts = {}) => {
  const base = str({ ...opts, lower: true, max: opts.max !== undefined ? opts.max : 254 });
  return {
    ...base,
    validate: (raw, field) => {
      const value = base.validate(raw, field);
      if (value && !isEmailFormat(value)) fail(`${field} must be a valid email address`);
      return value;
    },
  };
};

const phone = (opts = {}) =>
  str({
    ...opts,
    max: opts.max !== undefined ? opts.max : 20,
    pattern: PHONE_RE,
    message: 'must be a valid phone number',
  });

const username = (opts = {}) =>
  str({
    ...opts,
    min: opts.min !== undefined ? opts.min : 3,
    max: opts.max !== undefined ? opts.max : 30,
    pattern: USERNAME_RE,
    message: 'may only contain letters, numbers, dots, dashes and underscores',
  });

const otpCode = (opts = {}) =>
  str({
    ...opts,
    min: 4,
    max: 8,
    pattern: DIGITS_RE,
    message: 'must be 4 to 8 digits',
  });

const mimeType = (opts = {}) =>
  str({
    ...opts,
    max: opts.max !== undefined ? opts.max : 128,
    pattern: MIME_RE,
    message: 'must be a valid MIME type',
  });

// Empty is allowed unless the field is required, so a client can clear an
// avatar or a group image by sending "".
const url = (opts = {}) => {
  const base = str({ ...opts, max: opts.max !== undefined ? opts.max : 2048 });
  return {
    ...base,
    validate: (raw, field) => {
      const value = base.validate(raw, field);
      if (!value) return value;
      if (!isUrlFormat(value, {
        protocols: ['http', 'https'],
        require_protocol: true,
        require_tld: false,
      })) {
        fail(`${field} must be a valid http(s) URL`);
      }
      return value;
    },
  };
};

// Kept as the caller's string: downstream code builds its own Date from it.
const isoDate = (opts = {}) => ({
  required: !!opts.required,
  default: opts.default,
  validate: (raw, field) => {
    if (typeof raw !== 'string' && typeof raw !== 'number') {
      fail(`${field} must be a date`);
    }
    if (Number.isNaN(new Date(raw).getTime())) fail(`${field} must be a valid date`);
    return raw;
  },
});

module.exports = {
  OBJECT_ID_RE,
  runSchema,
  str,
  objectId,
  bool,
  num,
  arr,
  obj,
  json,
  email,
  phone,
  username,
  otpCode,
  mimeType,
  url,
  isoDate,
};
