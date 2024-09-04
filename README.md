This project provides automation scripts and configurations for setting up a multi-node server environment with Docker, Nginx, PHP, PostgreSQL, and Redis.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Setup](#setup)
  - [1. Launch Virtual Machines](#1-launch-virtual-machines)
  - [2. Connect to Instances](#2-connect-to-instances)
  - [3. Install Prerequisites](#3-install-prerequisites)
  - [4. Run Unified Installer](#4-run-unified-installer)
- [Docker Setup](#docker-setup)
  - [Master Instance](#master-instance)
  - [Node Instance](#node-instance)
- [Nginx Deployment](#nginx-deployment)
- [Connectivity Tests](#connectivity-tests)

## Prerequisites

- [Multipass](https://multipass.run/) for launching virtual machines locally
- Ubuntu 22.04 LTS
- Sufficient system resources (at least 8GB RAM and 100GB storage recommended)

## Setup

### 1. Launch Virtual Machines

Launch two Ubuntu 22.04 instances using Multipass:

```bash
multipass launch 22.04 -n primary -c 2 -m 4G -d 50G --name master-instance
multipass launch 22.04 -n primary -c 2 -m 4G -d 50G --name node-instance
```

### 2. Connect to Instances

Open two terminal windows and connect to each instance:

```bash
multipass shell master-instance  # Master instance
multipass shell node-instance    # Node instance
```

### 3. Install Prerequisites

Clone this repository and run the `packages-installation.sh` script on both instances:

```bash
git clone https://github.com/David-Melamed/docker-nginx-php-postgres-setup.git
cd docker-nginx-php-postgres-setup
chmod +x packages-installation.sh
```

Before running the installation script, make sure to review and update the versions.conf file in the package-installation
directory to specify the desired versions for each package. If no version is specified, the latest version will be used.


To start the installation process, run the main.sh script:
```bash
chmod +x main.sh
sudo ./main.sh
```

During the installation process, you will be prompted to:

1. Specify whether the current instance is a master or node server.
2. Choose between installing all packages or performing a custom installation.
   * If you select "all", all packages will be installed with their default versions specified in versions.conf.
   * If you select "custom", you will be prompted to choose which packages to install and optionally provide custom versions for each package.


Note: The package-installation directory contains the following subdirectories:

downloads/: Stores downloaded package files during the installation process.
logs/: Stores log files generated during the server setup and package installation.
temp/: Stores temporary files used during the package installation process.
scripts/: Contains individual package installation scripts.


## Create the directory and the PHP file:
Run the following command to create the necessary directory and add the info.php file with the phpinfo() function:

   ```bash
   sudo mkdir -p /var/www/html && sudo sh -c "echo '<?php phpinfo(); ?>' > /var/www/html/info.php"
   ```

## Docker Setup

### Master Instance

1. Copy the files to the master instance:
   ```bash
   scp -r master/Docker/* user@master-instance-ip:~/
   ```
2. Build the Docker image:
   ```bash
   sudo docker build -t my-nginx-site .
   ```
3. Run the container:
   ```bash
   sudo docker run -d -p 8081:80 -v $(pwd)/index.html:/usr/share/nginx/html/index.html my-nginx-site
   ```

### Node Instance

1. Copy the files to the node instance:
   ```bash
   scp -r node/Docker/* user@node-instance-ip:~/
   ```
2. Build the Docker image:
   ```bash
   sudo docker build -t my_nginx_postgres .
   ```
3. Run the container:
   ```bash
   sudo docker run -d -p 8081:80 -p 5432:5432 -v /var/run/postgresql:/tmp --user root --name postgres my_nginx_postgres
   ```

## Nginx Deployment

1. Copy the Nginx configuration:
   ```bash
   sudo cp master/nginx/sites-enabled/default /etc/nginx/sites-enabled/default
   OR
   sudo cp node/nginx/sites-enabled/default /etc/nginx/sites-enabled/default
   ```
2. Validate Nginx configuration:
   ```bash
   sudo nginx -t
   ```
3. Restart Nginx:
   ```bash
   sudo systemctl restart nginx
   ```

## Connectivity Tests

1. **Docker connectivity between master and node instances**
   - Access `http://<MASTER-IP>/info-node1.php` to display PHP info from the node instance's Docker container

2. **PostgreSQL on the node instance**
   - Send requests from the master instance to the PostgreSQL container on the node instance:
     ```
     http://<MASTER-IP>/server2-postgres-tables
     ```
   - This should list all databases in the node instance's PostgreSQL container