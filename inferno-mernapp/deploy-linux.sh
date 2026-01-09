set -e
if [ -z "${MONGO_URI:-}" ] || [ -z "${JWT_SECRET:-}" ]; then echo "MONGO_URI and JWT_SECRET required"; exit 1; fi
PORT="${PORT:-5000}"
CLIENT_ORIGIN="${CLIENT_ORIGIN:-http://52.143.185.128}"
if ! command -v curl >/dev/null 2>&1; then sudo apt-get update -y; sudo apt-get install -y curl; fi
if ! command -v node >/dev/null 2>&1; then curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -; sudo apt-get install -y nodejs; fi
sudo npm i -g pm2
cd "$(dirname "$0")/frontend"
npm ci || npm install
npm run build
cd ../backend
npm ci || npm install
PORT="$PORT" CLIENT_ORIGIN="$CLIENT_ORIGIN" MONGO_URI="$MONGO_URI" JWT_SECRET="$JWT_SECRET" NODE_ENV=production pm2 start server.js --name inferno --update-env
sudo pm2 save
sudo pm2 startup systemd -u "$USER" --hp "$HOME"
echo "inferno running on port $PORT"
