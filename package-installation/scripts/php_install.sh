#!/bin/bash
# php_install.sh

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" >> "$LOGFILE"
}

install_php() {
    local VERSION="$1"
    local LOGFILE="$2"
    local DOWNLOADS_DIR="$3"
    local TEMP_DIR="$4"
    
    cd "$TEMP_DIR"
    
    log "Installing PHP dependencies"
    sudo apt-get install -y libsqlite3-dev >> "$LOGFILE" 2>&1
    
    log "Downloading PHP version $VERSION"
    wget -q "https://www.php.net/distributions/php-$VERSION.tar.gz" -O php.tar.gz
    
    log "Extracting PHP"
    tar -xzf php.tar.gz
    
    log "Configuring PHP"
    cd php-$VERSION
    ./configure --enable-fpm --with-openssl --with-curl --with-zlib --enable-mbstring --with-pdo-mysql >> "$LOGFILE" 2>&1
    
    log "Compiling PHP"
    make >> "$LOGFILE" 2>&1
    
    log "Installing PHP"
    sudo make install >> "$LOGFILE" 2>&1
    
    log "Verifying PHP installation"
    php -v >> "$LOGFILE" 2>&1
    
    # Clean up
    cd "$TEMP_DIR"
    rm -rf php-$VERSION php.tar.gz
}

install_php "$1" "$2" "$3" "$4"