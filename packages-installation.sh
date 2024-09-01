#!/bin/bash

set -e

# Unified Server Setup Script

# Set up logging
LOGFILE="setup_$(date +'%Y%m%d_%H%M%S').log"

# Function to log messages to both console and file
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Function to log verbose messages only to file
log_verbose() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# Function to check if a command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        log_verbose "Success: $1"
    else
        log "Error: $1 failed"
        exit 1
    fi
}

# Create temporary directory
TEMP_DIR=$(mktemp -d)
log_verbose "Created temporary directory: $TEMP_DIR"

# Function to download and extract tar files
download_and_extract() {
    local url=$1
    local filename=$(basename $url)
    local dirname=${filename%.tar.gz}

    log "Downloading and extracting $filename"
    log_verbose "Downloading $filename"
    wget -P "$TEMP_DIR" $url >> "$LOGFILE"
    check_success "Download $filename"

    log_verbose "Extracting $filename"
    tar -xzf "$TEMP_DIR/$filename" -C "$TEMP_DIR" >> "$LOGFILE"
    check_success "Extract $filename"

    # Special case for Docker, which doesn't create a subdirectory
    if [[ $filename != docker* ]]; then
        cd "$TEMP_DIR/$dirname"
    else
        cd "$TEMP_DIR"
    fi
    log_verbose "Changed directory to $(pwd)"
}

# Function to install dependencies
install_dependencies() {
    log "Installing dependencies: $@"
    sudo apt install -y $@ >> "$LOGFILE"
    check_success "Install dependencies"
}

# Prompt for server type
read -p "Is this a master or node server? (master/node): " SERVER_TYPE
while [[ ! "$SERVER_TYPE" =~ ^(master|node)$ ]]; do
    read -p "Invalid input. Please enter 'master' or 'node': " SERVER_TYPE
done
log_verbose "Server type selected: $SERVER_TYPE"

# Prompt for versions
read -p "Enter Docker version (or press enter for 27.2.0): " DOCKER_VERSION
read -p "Enter Nginx version (or press enter for 1.18.0): " NGINX_VERSION
read -p "Enter PHP version (or press enter for 8.2.23): " PHP_VERSION
read -p "Enter PostgreSQL version (or press enter for 14.13): " POSTGRES_VERSION
read -p "Enter Redis version (or press enter for 7.2.5): " REDIS_VERSION

# Set default versions if not provided
DOCKER_VERSION=${DOCKER_VERSION:-27.2.0}
NGINX_VERSION=${NGINX_VERSION:-1.18.0}
PHP_VERSION=${PHP_VERSION:-8.2.23}
POSTGRES_VERSION=${POSTGRES_VERSION:-14.13}
REDIS_VERSION=${REDIS_VERSION:-7.2.5}

log_verbose "Versions selected:"
log_verbose "Docker: $DOCKER_VERSION"
log_verbose "Nginx: $NGINX_VERSION"
log_verbose "PHP: $PHP_VERSION"
log_verbose "PostgreSQL: $POSTGRES_VERSION"
log_verbose "Redis: $REDIS_VERSION"

log "Starting server setup for $SERVER_TYPE server"

# Update system
log "Updating system"
sudo apt update >> "$LOGFILE"
check_success "System update"

# Install common dependencies
log "Installing common dependencies"
install_dependencies wget build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libgd-dev libxml2-dev libcurl4-openssl-dev libonig-dev pkg-config libreadline-dev net-tools

# Docker installation
log "Installing Docker"
download_and_extract "https://download.docker.com/linux/static/stable/aarch64/docker-$DOCKER_VERSION.tgz"
chmod +x docker/* >> "$LOGFILE"
sudo cp docker/* /usr/bin/ >> "$LOGFILE"
log_verbose "Docker binaries copied to /usr/bin/"
sudo dockerd & >> "$LOGFILE" 2>&1
log_verbose "Docker daemon started"
check_success "Docker installation"

# Nginx installation
log "Installing Nginx"
sudo apt install nginx -y >> "$LOGFILE"
# download_and_extract "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"
# ./configure >> "$LOGFILE"
# log_verbose "Nginx configured"
# make >> "$LOGFILE"
# log_verbose "Nginx compiled"
# sudo make install >> "$LOGFILE"
# log_verbose "Nginx installed"
check_success "Nginx installation"

# PHP installation
log "Installing PHP"
install_dependencies libsqlite3-dev
download_and_extract "https://www.php.net/distributions/php-$PHP_VERSION.tar.gz"
./configure --enable-fpm --with-openssl --with-curl --with-zlib --enable-mbstring --with-pdo-mysql >> "$LOGFILE"
log_verbose "PHP configured"
make >> "$LOGFILE"
log_verbose "PHP compiled"
sudo make install >> "$LOGFILE"
log_verbose "PHP installed"
check_success "PHP installation"

# PostgreSQL installation
log "Installing PostgreSQL"
download_and_extract "https://ftp.postgresql.org/pub/source/v$POSTGRES_VERSION/postgresql-$POSTGRES_VERSION.tar.gz"
./configure >> "$LOGFILE"
log_verbose "PostgreSQL configured"
make >> "$LOGFILE"
log_verbose "PostgreSQL compiled"
sudo make install >> "$LOGFILE"
log_verbose "PostgreSQL installed"
check_success "PostgreSQL installation"

if [ "$SERVER_TYPE" = "node" ]; then
    # fcgiwrap installation
    log "Installing fcgiwrap"
    install_dependencies autoconf automake libtool
    sudo apt-get install fcgiwrap -y >> "$LOGFILE"
    log_verbose "fcgiwrap installed"
    check_success "fcgiwrap installation"

    # Redis installation
    log "Installing Redis"
    download_and_extract "https://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"
    cd "$TEMP_DIR/redis-$REDIS_VERSION"
    make >> "$LOGFILE"
    log_verbose "Redis compiled"
    sudo make install >> "$LOGFILE"
    log_verbose "Redis installed"
    check_success "Redis installation"

    # Start Redis
    log "Starting Redis server"
    redis-server --daemonize yes >> "$LOGFILE"
    log_verbose "Redis server started"
fi

log "Server setup completed successfully"
log "Full log available in $LOGFILE"

# Log installed versions
{
    echo "--- Installed Versions ---"
    echo "Docker: $DOCKER_VERSION"
    echo "Nginx: $NGINX_VERSION"
    echo "PHP: $PHP_VERSION"
    echo "PostgreSQL: $POSTGRES_VERSION"
    [ "$SERVER_TYPE" = "node" ] && echo "Redis: $REDIS_VERSION"
    echo "--- End Installed Versions ---"
} >> "$LOGFILE"

# Log completion time
echo "Script completed at $(date)" >> "$LOGFILE"