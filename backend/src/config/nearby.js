const num = (name, fallback) => {
  const raw = process.env[name];
  if (raw === undefined || raw === '') return fallback;
  const parsed = Number(raw);
  // A typo in a .env must not silently become NaN and propagate into a Redis
  // radius or a TTL, where it would fail far from its cause.
  if (!Number.isFinite(parsed)) {
    throw new Error(`[config] ${name} must be a number, got "${raw}"`);
  }
  return parsed;
};

module.exports = {
  PRESENCE_TTL_SECONDS: num('NEARBY_PRESENCE_TTL_SECONDS', 30 * 60),

  GRID_DECIMALS: num('NEARBY_GRID_DECIMALS', 3),

  DEFAULT_RADIUS_M: num('NEARBY_DEFAULT_RADIUS_M', 500),
  MAX_RADIUS_M: num('NEARBY_MAX_RADIUS_M', 2000),
  MAX_RESULTS: num('NEARBY_MAX_RESULTS', 60),

  LAST_KNOWN_MAX_AGE_SECONDS: num('NEARBY_LAST_KNOWN_MAX_AGE_SECONDS', 6 * 60 * 60),

  TIER_RIGHT_HERE_M: num('NEARBY_TIER_RIGHT_HERE_M', 120),
  TIER_VERY_CLOSE_M: num('NEARBY_TIER_VERY_CLOSE_M', 350),

  LOCATE_COOLDOWN_SECONDS: num('NEARBY_LOCATE_COOLDOWN_SECONDS', 5 * 60),
};
