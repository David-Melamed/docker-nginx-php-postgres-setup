#!/bin/bash
# nginx_install.sh

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" >> "$LOGFILE"
}

install_nginx() {
    local VERSION="$1"
    local LOGFILE="$2"
    local DOWNLOADS_DIR="$3"
    local TEMP_DIR="$4"
    
    cd "$TEMP_DIR"
    
    log "Downloading Nginx version $VERSION"
    wget -q "https://nginx.org/download/nginx-$VERSION.tar.gz" -O nginx.tar.gz
    
    log "Extracting Nginx"
    tar -xzf nginx.tar.gz
    
    log "Configuring Nginx"
    cd nginx-$VERSION
    ./configure >> "$LOGFILE" 2>&1
    
    log "Compiling Nginx"
    make >> "$LOGFILE" 2>&1
    
    log "Installing Nginx"
    sudo make install >> "$LOGFILE" 2>&1
    
    log "Verifying Nginx installation"
    nginx -v >> "$LOGFILE" 2>&1
    
    # Clean up
    cd "$TEMP_DIR"
    rm -rf nginx-$VERSION nginx.tar.gz
}

install_nginx "$1" "$2" "$3" "$4"