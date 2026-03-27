#!/bin/bash
set -e

export PGUSER=testuser
export PGPASSWORD=testpass
export PGDATABASE=fitwithfriends

cd "$(dirname "$0")/../WebService"

echo "Stopping Docker backend..."
docker compose -f docker-compose-local-testing.yml down -v

echo "Backend stopped."
