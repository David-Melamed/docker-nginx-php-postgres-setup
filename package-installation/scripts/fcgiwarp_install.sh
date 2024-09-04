#!/bin/bash
# fcgiwrap_install.sh

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" >> "$LOGFILE"
}

install_fcgiwrap() {
    local VERSION="$1"
    local LOGFILE="$2"
    local DOWNLOADS_DIR="$3"
    local TEMP_DIR="$4"
    
    log "Installing fcgiwrap dependencies"
    sudo apt-get install -y autoconf automake libtool >> "$LOGFILE" 2>&1
    
    log "Installing fcgiwrap"
    sudo apt-get install -y fcgiwrap >> "$LOGFILE" 2>&1
    
    log "Verifying fcgiwrap installation"
    dpkg -s fcgiwrap | grep Version >> "$LOGFILE" 2>&1
}

install_fcgiwrap "$1" "$2" "$3" "$4"