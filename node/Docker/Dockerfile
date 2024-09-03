# This Dockerfile sets up an environment with Nginx and PostgreSQL

# Start from the official Nginx image as our base
FROM nginx:latest

# Install necessary dependencies for building PostgreSQL
RUN apt-get update && \
    apt-get install -y wget gcc build-essential zlib1g-dev libreadline6-dev libicu-dev pkg-config sudo
    
# Copy a custom index.html file into the default Nginx public directory
COPY index.html /usr/share/nginx/html/index.html

# Copy the .env file into the root of the container
# This file will be used by the entrypoint script to set up environment variables
COPY .env /.env

# Set the working directory for PostgreSQL installation
WORKDIR /postgresql

# Define build arguments for PostgreSQL configuration
# These will be provided during the build process
ARG POSTGRES_VERSION
ARG POSTGRES_BIN_PATH
ARG POSTGRES_DATA_PATH

# Download and extract the PostgreSQL source code
RUN wget https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.bz2 && \
    tar -xvf postgresql-${POSTGRES_VERSION}.tar.bz2

# Change working directory to the extracted PostgreSQL source
WORKDIR /postgresql/postgresql-${POSTGRES_VERSION}

# Configure, compile, and install PostgreSQL from source
RUN ./configure && \
    make && make install

# Create a PostgreSQL user and add it to the sudo group
RUN sudo useradd -m -d /home/postgres -s /bin/bash postgres && \
    sudo usermod -aG sudo postgres

# Add PostgreSQL binaries to the PATH for the postgres user
RUN echo "export PATH=\$PATH:/usr/local/pgsql/bin" >> /home/postgres/.bash_profile && \
    bash -c "source /home/postgres/.bash_profile"
        
# Switch to the postgres user for database initialization
USER postgres

# Initialize the PostgreSQL database
RUN ${POSTGRES_BIN_PATH}/initdb -D ${POSTGRES_DATA_PATH}

# Configure PostgreSQL to accept connections from all addresses
RUN echo "listen_addresses = '*'" >> ${POSTGRES_DATA_PATH}/postgresql.conf && \
    echo "port = 5432" >> ${POSTGRES_DATA_PATH}/postgresql.conf && \
    echo "host all all 0.0.0.0/0 md5" >> ${POSTGRES_DATA_PATH}/pg_hba.conf

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh

# Switch back to root user to set permissions on the entrypoint script
USER root
RUN chmod +x /entrypoint.sh

# Expose ports for Nginx (80) and PostgreSQL (5432)
EXPOSE 80 5432

# Set the entrypoint script to run when the container starts
ENTRYPOINT ["/entrypoint.sh"]