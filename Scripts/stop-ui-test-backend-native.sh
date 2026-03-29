#!/bin/bash

echo "Stopping Node.js server..."
if [ -f /tmp/fwf-backend.pid ]; then
    kill "$(cat /tmp/fwf-backend.pid)" || true
    rm /tmp/fwf-backend.pid
fi

echo "Stopping PostgreSQL..."
export PATH="$(brew --prefix postgresql@17)/bin:$PATH"
brew services stop postgresql@17

echo "Backend stopped."
