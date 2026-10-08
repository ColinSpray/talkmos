# Talkmos Docker calling & Backend Stack

This directory contains the Docker configuration to run the complete Talkmos backend API services, MongoDB database, and a Coturn STUN/TURN server enabling NAT traversal for WebRTC audio/video calls.

## Architecture Components

1. **Backend Service (`talkmos-backend`)**:
   - The Node.js Express application running Socket.io WebRTC signaling.
   - Exposed on port `5000`.
2. **Database Service (`talkmos-mongo`)**:
   - MongoDB database instance containing user profiles, community channels, and call logs.
   - Bound to `127.0.0.1:27017` — loopback only.
   - Runs as a **single-node replica set** (`rs0`), which is what makes transactions
     available; `createConversation` and `createCommunity` both need them. It buys no
     redundancy — one node is still one node.
   - Two one-shot helpers support it: `talkmos-mongo-keyfile` generates the internal-auth
     keyfile (required once auth and replication are on together) into the `mongo_keyfile`
     volume, and `talkmos-mongo-init` runs `rs.initiate()` on first boot and exits. Both
     are idempotent — later boots re-run them and they no-op.
   - `MONGO_URI` must carry `replicaSet=rs0`, and the member is registered as `mongo:27017`,
     which only resolves inside the Compose network. From the host, connect **without**
     `replicaSet=` (e.g. `mongosh "mongodb://root:<password>@127.0.0.1:27017/talkmos?authSource=admin&directConnection=true"`)
     or the driver will chase a hostname it cannot reach.
3. **STUN/TURN Service (`talkmos-coturn`)**:
   - Coturn server used for NAT traversal in WebRTC connections.
   - Exposed on port `3478` (UDP/TCP) and relay ports `49152-49170` (UDP).

---

## Getting Started

### Prerequisites
Make sure you have [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) installed.

### Setup and Running

1. **Prepare Environment Variables**:
   Ensure you have a `.env` file in the `backend/` directory (copied from `.env.example`). The `MONGO_URI` is automatically overridden in `docker-compose.yml` to point to the internal `mongodb` service container.

2. **Start the Stack**:
   Run the following command from the `backend/` directory:
   ```bash
   docker compose up --build -d
   ```

3. **Stop the Stack**:
   To stop the services and retain data volumes:
   ```bash
   docker compose down
   ```

---

## WebRTC Client calling Configuration

For WebRTC calling to function correctly (especially across different networks or behind routers/NATs), the Flutter client application must be configured to use this STUN/TURN server.

### 1. Client STUN/TURN configuration

In your WebRTC connection options on the client, configure the `iceServers` array:

```dart
List<Map<String, dynamic>> iceServers = [
  // STUN Service
  {
    'urls': 'stun:<YOUR_SERVER_IP>:3478',
  },
  // TURN Service
  {
    'urls': 'turn:<YOUR_SERVER_IP>:3478',
    'username': 'talkmos',
    'credential': 'talkmossecret',
  }
];
```

*Note: Replace `<YOUR_SERVER_IP>` with the public IP address of your host machine.*

---
W
## Production Security Notes

Before deploying to production:
1. **Change Default Credentials**:
   Modify the default user credentials (`talkmos:talkmossecret`) in `turnserver.conf`.
2. **Open Firewall Ports**:
   Ensure the following ports are open in your host/cloud provider's security group/firewall:
   - `3478` (UDP and TCP) — STUN/TURN listener.
   - `49152-49170` (UDP) — TURN dynamic allocation port range.
3. **Configure External IP**:
   Uncomment and configure the `external-ip` flag in `turnserver.conf` if your server is behind a NAT or has a public IP address different from the local interface IP.


curl -X POST https://stage-api.talkmos.com/api/v1/apk/upload \
  -F "apk=@build/app/outputs/flutter-apk/app-release.apk" \
  -F "versionName=1.1.1" \
  -F "versionCode=10" \
  -F "minRequiredVersionCode=1" \
  -F "releaseNotes=Fix the Dark mode color" \
  -F "isForceUpdate=false"