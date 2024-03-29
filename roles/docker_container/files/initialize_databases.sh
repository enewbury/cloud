#!/bin/bash

set -e
set -u

function create_user_and_database() {
	IFS=: read database password locale<<< "$1"
	echo "  Creating user and database '$database'"
	psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" <<-EOSQL
	    CREATE USER $database WITH PASSWORD '$password';
	    CREATE DATABASE $database TEMPLATE template0 LOCALE '${locale:-en_US.utf8}';
	    GRANT ALL PRIVILEGES ON DATABASE $database TO $database;
EOSQL
}

function load_dump_file() {
	IFS=: read database password locale<<< "$1"
	echo " Checking for dump file postgres_dump_$database.sql"
	if [[ -f "/dump/postgres_dump_$database.sql" ]]; then
		echo "  Loading $database dump file"
		psql -U "$database" -d "$database" < "/dump/postgres_dump_$database.sql"
	else
		echo " No dump file found"
	fi

}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
	echo "Multiple database creation requested"
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
		create_user_and_database $db
		load_dump_file $db
	done
	echo "Multiple databases created"
fi
