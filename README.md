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
sudo ./packages-installation.sh
```

When prompted, use these default versions or specify your own:

- **instance-type**: master (for master-instance) or node (for node-instance)
- **Docker**: 27.2.0
- **Nginx**: 1.18.0
- **PHP**: 4.2.22
- **PostgreSQL**: 14.13
- **Redis**: 7.2.5

## Create the directory and the PHP file:
Run the following command to create the necessary directory and add the info.php file with the phpinfo() function:

   ```bash
   sudo mkdir -p /var/www/html && sudo sh -c "echo '<?php phpinfo(); ?>' > /var/www/html/info.php"
   ```

## Docker Setup

### Master Instance

1. Ensure `Dockerfile` and `index.html` are in the same directory.
2. Build the Docker image:
   ```bash
   sudo docker build -t my-nginx-site .
   ```
3. Run the container:
   ```bash
   sudo docker run -d -p 8081:80 -v $(pwd)/index.html:/usr/share/nginx/html/index.html my-nginx-site
   ```

### Node Instance

1. Copy the Dockerfile to the node instance:
   ```bash
   scp Dockerfile user@node-instance-ip:~/
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
     http://<MASTER-IP>/query-postgres
     ```
   - This should list all databases in the node instance's PostgreSQL container