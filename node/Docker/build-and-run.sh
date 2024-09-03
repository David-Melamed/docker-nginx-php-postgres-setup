#!/bin/bash

# Load variables from .env file
set -a
source .env
set +a

# Build the Docker image
docker build \
  --build-arg POSTGRES_VERSION=$POSTGRES_VERSION \
  --build-arg POSTGRES_BIN_PATH=$POSTGRES_BIN_PATH \
  --build-arg POSTGRES_DATA_PATH=$POSTGRES_DATA_PATH \
  -t my-nginx-postgres-image .

# Run the Docker container
docker run -d \
  -p 8080:80 \
  -p 5432:5432 \
  -v /var/run/postgresql:/tmp \
  -e POSTGRES_VERSION=$POSTGRES_VERSION \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$POSTGRES_DB \
  -e POSTGRES_BIN_PATH=$POSTGRES_BIN_PATH \
  -e POSTGRES_DATA_PATH=$POSTGRES_DATA_PATH \
  -e POSTGRES_LOG_FILE=$POSTGRES_LOG_FILE \
  -e MAX_RETRIES=$MAX_RETRIES \
  -e RETRY_INTERVAL=$RETRY_INTERVAL \
  my-nginx-postgres-image

echo "Container started. Nginx is accessible on http://localhost:8080"
echo "PostgreSQL is accessible on localhost:5432"