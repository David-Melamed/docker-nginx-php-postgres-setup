# Start from the Nginx official image
FROM nginx:latest

# Install dependencies and PostgreSQL
RUN apt-get update && \
    apt-get install -y postgresql postgresql-contrib && \
    service postgresql start 

# Copy your custom index.html into the image
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 for Nginx and 5432 for PostgreSQL
EXPOSE 80 5432


# Command to run when the container starts
# Start from the Nginx official image
FROM nginx:latest

# Install dependencies and PostgreSQL
RUN apt-get update && \
    apt-get install -y wget gcc build-essential zlib1g-dev libreadline6-dev libicu-dev pkg-config sudo
    
# Copy your custom index.html into the image
COPY index.html /usr/share/nginx/html/index.html

WORKDIR /postgresql

ARG POSTGRES_VERSION=16.1

# Download and extract PostgreSQL source
RUN wget https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.bz2 && \
    tar -xvf postgresql-${POSTGRES_VERSION}.tar.bz2

WORKDIR /postgresql/postgresql-${POSTGRES_VERSION}

# Build and install PostgreSQL from source
RUN ./configure && \
    make && make install

#Create postgresql user
RUN sudo useradd -m -d /home/postgres -s /bin/bash postgres && \
    sudo usermod -aG sudo postgres

RUN echo "export PATH=\$PATH:/usr/local/pgsql/bin" >> /home/postgres/.bash_profile && \
    bash -c "source /home/postgres/.bash_profile"
        
USER postgres

ARG POSTGRES_BIN_PATH=/usr/local/pgsql/bin
ARG POSTGRES_DATA_PATH=/home/postgres/.postgres/data

# Initialize the database
RUN ${POSTGRES_BIN_PATH}/initdb -D ${POSTGRES_DATA_PATH}

RUN echo "listen_addresses = '*'" >> ${POSTGRES_DATA_PATH}/postgresql.conf && \
    echo "port = 5432" >> ${POSTGRES_DATA_PATH}/postgresql.conf && \
    echo "host all all 0.0.0.0/0 md5" >> ${POSTGRES_DATA_PATH}/pg_hba.conf

# Start the PostgreSQL server, create the database, and then keep the server running
RUN ${POSTGRES_BIN_PATH}/pg_ctl -D ${POSTGRES_DATA_PATH} start && \
    sleep 5 && \
    ${POSTGRES_BIN_PATH}/createdb mydb

# Expose port 80 for Nginx and 5432 for PostgreSQL
EXPOSE 80 5432