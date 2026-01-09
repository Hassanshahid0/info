#!/usr/bin/env bash
set -e
if [ -z "${MONGO_URI:-}" ] || [ -z "${JWT_SECRET:-}" ]; then echo "MONGO_URI and JWT_SECRET required"; exit 1; fi
PORT="${PORT:-5000}"
FRONT_PORT="${FRONT_PORT:-5173}"
CLIENT_ORIGIN="${CLIENT_ORIGIN:-http://4.251.118.253:${FRONT_PORT}}"
API_BASE="${VITE_API_BASE:-http://4.251.118.253:${PORT}}"
if ! command -v curl >/dev/null 2>&1; then sudo apt-get update -y; sudo apt-get install -y curl; fi
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2 serve
cd "$(dirname "$0")/backend"
npm ci || npm install
cat > .env <<EOL
PORT=$PORT
MONGO_URI=$MONGO_URI
JWT_SECRET=$JWT_SECRET
CLIENT_ORIGIN=$CLIENT_ORIGIN
EOL
cd ../frontend
npm ci || npm install
cat > .env <<EOL
VITE_API_BASE=$API_BASE
EOL
npm run build
pm2 stop all || true
pm2 delete all || true
cd ../backend
NODE_ENV=production pm2 start server.js --name snapshare-backend --update-env
cd ../frontend
pm2 start serve --name snapshare-frontend -- -s dist -l "$FRONT_PORT"
pm2 save
sudo pm2 startup systemd -u "$USER" --hp "$HOME"
echo "Backend: http://4.251.118.253:$PORT"
echo "Frontend: http://4.251.118.253:$FRONT_PORT"
