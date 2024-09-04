#!/bin/bash
# docker_install.sh

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" >> "$LOGFILE"
}

install_docker() {
    local VERSION="$1"
    local LOGFILE="$2"
    local DOWNLOADS_DIR="$3"
    local TEMP_DIR="$4"
    
    cd "$TEMP_DIR"
    
    log "Downloading Docker version $VERSION"
    wget -q "https://download.docker.com/linux/static/stable/aarch64/docker-$VERSION.tgz" -O docker.tgz
    
    log "Extracting Docker"
    tar -xzf docker.tgz
    
    log "Installing Docker"
    chmod +x docker/*
    sudo cp docker/* /usr/bin/
    
    log "Starting Docker daemon"
    sudo dockerd &
    
    log "Verifying Docker installation"
    docker --version >> "$LOGFILE" 2>&1
    
    # Clean up
    rm -rf docker docker.tgz
}

install_docker "$1" "$2" "$3" "$4"