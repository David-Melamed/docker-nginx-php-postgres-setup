#!/bin/bash

# Query Postgres DB to fetch all databases
psql -h /var/run/postgresql -U postgres -c "\list"