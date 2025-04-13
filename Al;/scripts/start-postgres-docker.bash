#!/bin/bash

# Script to launch a standalone PostgreSQL Docker container
# Data is persisted in /Users/ajoslin/Development/A2A/Al;/postgres

# Configuration variables
POSTGRES_CONTAINER_NAME="a2a_postgres"
POSTGRES_VERSION="15"
POSTGRES_USER="a2a_user"
POSTGRES_PASSWORD="a2a_password"
POSTGRES_DB="a2a_db"
POSTGRES_PORT="5432"
DATA_DIR="/Users/ajoslin/Development/A2A/Al;/postgres"

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Check if container is already running
if docker ps -q --filter "name=$POSTGRES_CONTAINER_NAME" | grep -q .; then
    echo "PostgreSQL container is already running."
    echo "To stop it, run: docker stop $POSTGRES_CONTAINER_NAME"
    echo "To view logs, run: docker logs $POSTGRES_CONTAINER_NAME"
    exit 0
fi

# Check if container exists but is stopped
if docker ps -aq --filter "name=$POSTGRES_CONTAINER_NAME" | grep -q .; then
    echo "PostgreSQL container exists but is not running."
    echo "Starting existing container..."
    docker start $POSTGRES_CONTAINER_NAME
    echo "PostgreSQL container started!"
    echo "To connect: psql -h localhost -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB"
    exit 0
fi

# Launch new PostgreSQL container
echo "Creating and starting new PostgreSQL container..."
docker run --name $POSTGRES_CONTAINER_NAME \
    -e POSTGRES_USER=$POSTGRES_USER \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -e POSTGRES_DB=$POSTGRES_DB \
    -p $POSTGRES_PORT:5432 \
    -v $DATA_DIR:/var/lib/postgresql/data \
    -d postgres:$POSTGRES_VERSION

echo "PostgreSQL container has been started!"
echo
echo "Container name: $POSTGRES_CONTAINER_NAME"
echo "PostgreSQL version: $POSTGRES_VERSION"
echo "Database: $POSTGRES_DB"
echo "User: $POSTGRES_USER"
echo "Password: $POSTGRES_PASSWORD"
echo "Port: $POSTGRES_PORT -> 5432 (in container)"
echo "Data directory: $DATA_DIR"
echo
echo "Connection information:"
echo "  From host: psql -h localhost -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB"
echo "  From Docker: docker exec -it $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB"
echo
echo "Management commands:"
echo "  Stop container:    docker stop $POSTGRES_CONTAINER_NAME"
echo "  Start container:   docker start $POSTGRES_CONTAINER_NAME"
echo "  Remove container:  docker rm $POSTGRES_CONTAINER_NAME (must be stopped first)"
echo "  View logs:         docker logs $POSTGRES_CONTAINER_NAME"
echo "  Shell access:      docker exec -it $POSTGRES_CONTAINER_NAME bash"
