#!/bin/bash
# postgres_install.sh

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" >> "$LOGFILE"
}

install_postgres() {
    local VERSION="$1"
    local LOGFILE="$2"
    local DOWNLOADS_DIR="$3"
    local TEMP_DIR="$4"
    
    cd "$TEMP_DIR"
    
    if [ "$VERSION" = "latest" ]; then
        VERSION=$(wget -qO- https://www.postgresql.org/ftp/source/ | grep -oP 'v\d+\.\d+\.\d+' | sort -V | tail -n1 | tr -d 'v')
        log "Latest PostgreSQL version is $VERSION"
    fi
    
    log "Downloading PostgreSQL version $VERSION"
    wget -q "https://ftp.postgresql.org/pub/source/v$VERSION/postgresql-$VERSION.tar.gz" -O postgresql.tar.gz
    
    log "Extracting PostgreSQL"
    tar -xzf postgresql.tar.gz
    
    log "Configuring PostgreSQL"
    cd postgresql-$VERSION
    ./configure >> "$LOGFILE" 2>&1
    
    log "Compiling PostgreSQL"
    make >> "$LOGFILE" 2>&1
    
    log "Installing PostgreSQL"
    sudo make install >> "$LOGFILE" 2>&1

    log "Adding PostgreSQL bin directory to PATH"
    echo 'export PATH=/usr/local/pgsql/bin:$PATH' | sudo tee -a /etc/profile.d/pgsql.sh > /dev/null
    
    log "Reloading system configuration"
    source /etc/profile.d/pgsql.sh
        
    log "Verifying PostgreSQL installation"
    psql --version >> "$LOGFILE" 2>&1
    
    # Clean up
    cd "$TEMP_DIR"
    rm -rf postgresql-$VERSION postgresql.tar.gz
}

install_postgres "$1" "$2" "$3" "$4"