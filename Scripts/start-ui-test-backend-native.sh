#!/bin/bash
set -e

PGUSER=testuser
PGPASSWORD=testpass
PGDATABASE=fitwithfriends
FWF_ADMIN_AUTH_SECRET=some_admin_secret

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBSERVICE_DIR="$SCRIPT_DIR/../WebService"
APP_DIR="$WEBSERVICE_DIR/FitWithFriends"

echo "Installing PostgreSQL 17..."
brew install postgresql@17
export PATH="$(brew --prefix postgresql@17)/bin:$PATH"

echo "Starting PostgreSQL..."
brew services start postgresql@17

echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h localhost -p 5432; do
    sleep 1
done

echo "Setting up database..."
psql -h localhost -d postgres -c "CREATE USER $PGUSER WITH PASSWORD '$PGPASSWORD' SUPERUSER;"
createdb -h localhost -U $PGUSER $PGDATABASE
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -f "$WEBSERVICE_DIR/CreateDatabaseTables.sql"
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -f "$WEBSERVICE_DIR/SetupTestData.sql"

echo "Generating SSL keypair..."
openssl req -x509 -newkey rsa:4096 \
    -keyout "$APP_DIR/fwfAuthKey.pem" \
    -out "$APP_DIR/fwfAuthCert.pem" \
    -days 365 -nodes -subj "/CN=localhost"

echo "Building Node.js app..."
cd "$APP_DIR"
npm install
npm run build

echo "Starting Node.js server..."
PGHOST=localhost \
PGPORT=5432 \
PGUSER=$PGUSER \
PGPASSWORD=$PGPASSWORD \
PGDATABASE=$PGDATABASE \
PGUSESSL=0 \
FWF_AUTH_USE_LOCAL_KEYPAIR=1 \
FWF_AUTH_PRIVATE_KEY_PATH=./fwfAuthKey.pem \
FWF_AUTH_PUBLIC_KEY_PATH=./fwfAuthCert.pem \
FWF_ADMIN_AUTH_SECRET=$FWF_ADMIN_AUTH_SECRET \
NODE_ENV=test \
node dist/app &

echo $! > /tmp/fwf-backend.pid

echo "Waiting for backend to be ready..."
until curl -sf http://localhost:3000 > /dev/null 2>&1; do
    sleep 2
done

echo "Backend is ready at http://localhost:3000"
