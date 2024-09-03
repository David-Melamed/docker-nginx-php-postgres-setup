#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    exit 1
}

# Function to start PostgreSQL
start_postgresql() {
    log "Starting PostgreSQL..."
    
    # Ensure the data directory exists
    if [ ! -d "${POSTGRES_DATA_PATH}" ]; then
        handle_error "PostgreSQL data directory does not exist: ${POSTGRES_DATA_PATH}"
    fi
    
    # Ensure log directory exists and has correct permissions
    log "Creating log directory: $(dirname "${POSTGRES_LOG_FILE}")"
    mkdir -p "$(dirname "${POSTGRES_LOG_FILE}")"
    chown postgres:postgres "$(dirname "${POSTGRES_LOG_FILE}")"
    chmod 755 "$(dirname "${POSTGRES_LOG_FILE}")"
    
    # Start PostgreSQL
    log "Running pg_ctl to start PostgreSQL"
    su - postgres -c "${POSTGRES_BIN_PATH}/pg_ctl -D ${POSTGRES_DATA_PATH} -l ${POSTGRES_LOG_FILE} start"
    
    # Wait for PostgreSQL to start
    for i in $(seq 1 "${MAX_RETRIES:-30}"); do
        if su - postgres -c "${POSTGRES_BIN_PATH}/pg_isready" >/dev/null 2>&1; then
            log "PostgreSQL started successfully"
            return 0
        fi
        log "Waiting for PostgreSQL to start... (Attempt $i/${MAX_RETRIES:-30})"
        sleep "${RETRY_INTERVAL:-1}"
    done
    
    handle_error "PostgreSQL failed to start after ${MAX_RETRIES:-30} attempts"
}

# Function to start Nginx
start_nginx() {
    log "Starting Nginx..."
    nginx -g 'daemon off;' &
}

# Main execution
main() {
    log "Container started"
    
    start_postgresql
    start_nginx
    
    log "All services started. Container is now running."
    
    # Keep the container running
    tail -f /dev/null
}

# Trap errors
trap 'handle_error "An unexpected error occurred"' ERR

# Run main function
main