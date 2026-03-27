#!/bin/bash
set -e

export PGUSER=testuser
export PGPASSWORD=testpass
export PGDATABASE=fitwithfriends
export FWF_ADMIN_AUTH_SECRET=some_admin_secret

cd "$(dirname "$0")/../WebService"

echo "Starting Docker backend for UI tests..."
docker compose -f docker-compose-local-testing.yml up -d --build

echo "Waiting for backend to be ready..."
until curl -sf http://localhost:3000 > /dev/null 2>&1; do
    sleep 2
done

echo "Backend is ready at http://localhost:3000"
