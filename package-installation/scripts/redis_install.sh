#!/bin/bash
# redis_install.sh

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" >> "$LOGFILE"
}

install_redis() {
    local VERSION="$1"
    local LOGFILE="$2"
    local DOWNLOADS_DIR="$3"
    local TEMP_DIR="$4"
    
    cd "$TEMP_DIR"
    
    log "Downloading Redis version $VERSION"
    wget -q "https://download.redis.io/releases/redis-$VERSION.tar.gz" -O redis.tar.gz
    
    log "Extracting Redis"
    tar -xzf redis.tar.gz
    
    log "Compiling Redis"
    cd redis-$VERSION
    make >> "$LOGFILE" 2>&1
    
    log "Installing Redis"
    sudo make install >> "$LOGFILE" 2>&1
    
    log "Starting Redis server"
    redis-server --daemonize yes
    
    log "Verifying Redis installation"
    redis-cli --version >> "$LOGFILE" 2>&1
    
    # Clean up
    cd "$TEMP_DIR"
    rm -rf redis-$VERSION redis.tar.gz
}

install_redis "$1" "$2" "$3" "$4"