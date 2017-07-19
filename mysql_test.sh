#!/bin/bash

set -e

# wait for mysql to come online
while ! nc -z "${MYSQL_DB_HOST:?}" "${MYSQL_DB_PORT:?}"; do
	echo "Waiting for mysql to come online at ${MYSQL_DB_HOST:?}:${MYSQL_DB_PORT:?}..."
	sleep 2.5
done

# wait for our vault client token to become available
counter=0
while ! vault token-lookup; do
	(( counter++ ))
	echo "waiting for vault token \"$VAULT_TOKEN\" to become available (counter=$counter...)"
	if [ $counter -gt 30 ]; then
		echo "WARNING: the test may have failed..."
	fi
	sleep 2.5
done

echo "SUCCESS!"

# function to_mysql {
# 	mysql -u "${MYSQL_CREDS_FULL_USERNAME:?}" \
# 	      -p"${MYSQL_CREDS_FULL_PASSWORD:?}" \
# 	      --host="${MYSQL_DB_HOST:?}" \
# 	      -P"${MYSQL_DB_PORT:?}" \
# 	      --protocol TCP \
# 	      -e "${SQL:?}" \
# 	      "${MYSQL_DB_NAME:?}"
# }

# SQL="select count(*) from test"

# while true; do
# 	mysql -u "${MYSQL_CREDS_FULL_USERNAME:?}" \
# 	      -p"${MYSQL_CREDS_FULL_PASSWORD:?}" \
# 	      --host="${MYSQL_DB_HOST:?}" \
# 	      -P"${MYSQL_DB_PORT:?}" \
# 	      --protocol TCP \
# 	      -e "${SQL:?}" \
# 	      "${MYSQL_DB_NAME:?}"
# 	date
# 	sleep 1;
# done