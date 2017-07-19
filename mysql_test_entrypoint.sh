#!/bin/bash

#################################################################
# waiting to be ready

echo "wait for mysql to come online..."
while ! nc -z "${MYSQL_DB_HOST:?}" "${MYSQL_DB_PORT:?}"; do
	echo "Waiting for mysql to come online at ${MYSQL_DB_HOST:?}:${MYSQL_DB_PORT:?}..."
	sleep 2.5
done

echo "wait for our vault client token to become available..."
counter=0
while ! vault token-lookup; do
	(( counter++ ))
	echo "waiting for vault token \"$VAULT_TOKEN\" to become available (counter=$counter...)"
	if [ $counter -gt 30 ]; then
		echo "WARNING: the test may have failed..."
	fi
	sleep 2.5
done



#################################################################
# all about getting secrets and loading them into the environment

# read the credentials and run the test
envconsul -once -secret mysql/creds/full -upcase ./mysql_test.sh

