FROM node:26-alpine

WORKDIR /app

# NODE_ENV before the install so anything that keys off it behaves the same at
# build time as at runtime.
ENV NODE_ENV=production

COPY package*.json ./

# --omit=dev: artillery and nodemon are development tooling and have no reason
# to ship in a production image.
RUN npm ci --omit=dev

# .dockerignore keeps the host's node_modules, .env and credentials/ out of
# this copy — without it they would land on top of the install above.
COPY . .

EXPOSE 5000

# Health endpoint reports process liveness plus Mongo/Redis reachability, so a
# worker that is running but cannot reach its datastores is reported unhealthy
# rather than being left in rotation.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:5000/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "src/cluster.js"]
