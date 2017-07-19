#!/bin/bash

set -e

SQL="select count(*) from test"

while true; do
	mysql -u "${MYSQL_CREDS_FULL_USERNAME:?}" \
	      -p"${MYSQL_CREDS_FULL_PASSWORD:?}" \
	      --host="${MYSQL_DB_HOST:?}" \
	      -P"${MYSQL_DB_PORT:?}" \
	      --protocol TCP \
	      -e "${SQL:?}" \
	      "${MYSQL_DB_NAME:?}"
	date
	sleep 1;
done