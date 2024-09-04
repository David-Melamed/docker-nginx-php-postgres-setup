#!/bin/bash

# main.sh

set -e

SCRIPT_DIR=$(pwd)
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
DOWNLOADS_DIR="$SCRIPT_DIR/downloads"
TEMP_DIR="$SCRIPT_DIR/temp"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOG_DIR="$SCRIPT_DIR/logs/setup_$TIMESTAMP"
MAIN_LOGFILE="$LOG_DIR/main_script.log"

# Create necessary directories
mkdir -p "$LOG_DIR" "$DOWNLOADS_DIR" "$TEMP_DIR"

# Simple logging function
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" | tee -a "${2:-$MAIN_LOGFILE}"
}

# Function to display a loading animation
show_loading() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r%s %s" "$message" "${spin:$i:1}" | tee -a "$MAIN_LOGFILE"
        sleep .1
    done
    printf "\r%s Done!   \n" "$message" | tee -a "$MAIN_LOGFILE"
}

# Function to install a package
install_package() {
    local package=$1
    local version=$2
    local script_file="$SCRIPTS_DIR/${package}_install.sh"
    local package_logfile="$LOG_DIR/${package}_install.log"

    if [ ! -f "$script_file" ]; then
        log "Error: Installation script for $package not found"
        return 1
    fi

    log "Installing $package version $version"
    bash "$script_file" "$version" "$package_logfile" "$DOWNLOADS_DIR" "$TEMP_DIR" 2>&1 | tee -a "$package_logfile" &
    show_loading $! "Installing $package"
    wait $!
    if [ $? -eq 0 ]; then
        log "$package installation successful"
    else
        log "Error: $package installation failed. Check $package_logfile for details."
        return 1
    fi
}

# Function to update system
update_system() {
    log "Updating system"
    sudo apt update >> "$MAIN_LOGFILE" 2>&1 &
    show_loading $! "Updating system"
    wait $!
    if [ $? -eq 0 ]; then
        log "System update successful"
    else
        log "Error: System update failed"
        return 1
    fi
}

main() {
    log "Starting server setup"
    log "Log directory created at: $LOG_DIR"

    # Load package versions
    source "$SCRIPT_DIR/versions.conf"

    # Prompt for server type
    read -p "Is this a master or node server? (master/node): " SERVER_TYPE
    while [[ ! "$SERVER_TYPE" =~ ^(master|node)$ ]]; do
        read -p "Invalid input. Please enter 'master' or 'node': " SERVER_TYPE
    done
    log "Server type selected: $SERVER_TYPE"

    # Prompt for installation type
    read -p "Do you want to install all packages or perform a custom installation? (all/custom): " INSTALL_TYPE
    while [[ ! "$INSTALL_TYPE" =~ ^(all|custom)$ ]]; do
        read -p "Invalid input. Please enter 'all' or 'custom': " INSTALL_TYPE
    done
    log "Installation type selected: $INSTALL_TYPE"

    # Array to store packages to install
    declare -A PACKAGES_TO_INSTALL

    if [[ "$INSTALL_TYPE" == "all" ]]; then
        # Install all packages with default versions
        for script in "$SCRIPTS_DIR"/*_install.sh; do
            package=$(basename "$script" _install.sh)
            version_var="${package^^}_VERSION"
            version=${!version_var:-latest}
            PACKAGES_TO_INSTALL[$package]=$version
        done
    else
        # Gather information about packages to install
        for script in "$SCRIPTS_DIR"/*_install.sh; do
            package=$(basename "$script" _install.sh)
            read -p "Install $package? (y/n): " install_choice
            if [[ "$install_choice" =~ ^[Yy]$ ]]; then
                version_var="${package^^}_VERSION"
                version=${!version_var:-latest}
                read -p "Enter $package version (or press enter for $version): " custom_version
                PACKAGES_TO_INSTALL[$package]=${custom_version:-$version}
            fi
        done
    fi

    # Display summary of packages to be installed
    log "The following packages will be installed:"
    for package in "${!PACKAGES_TO_INSTALL[@]}"; do
        log "$package: ${PACKAGES_TO_INSTALL[$package]}"
    done

    # Confirm installation
    read -p "Do you want to proceed with the installation? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Installation cancelled by user"
        exit 0
    fi

    # Perform system update
    update_system || exit 1

    # Install packages
    for package in "${!PACKAGES_TO_INSTALL[@]}"; do
        install_package "$package" "${PACKAGES_TO_INSTALL[$package]}" || exit 1
    done

    log "Server setup completed"
    log "Logs are available in $LOG_DIR"
}

# Export logging function and directories so they can be used in package scripts
export LOG_DIR DOWNLOADS_DIR TEMP_DIR
export -f log

# Run the main function
main