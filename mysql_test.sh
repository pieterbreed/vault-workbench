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

# read the credentials
envconsul -once -secret mysql/creds/full -upcase -pristine env > creds
echo "envconsul output..."
cat creds

# change the creds so we can import them
# also rename the variables a little
sed 's/MYSQL_CREDS_FULL/export MYSQL_DB/' \
    < creds \
    > modded_creds
echo "modded creds"
cat modded_creds

. modded_creds
env | grep MYSQL

#################################################################
# prepping mysql data

function to_mysql {
	mysql -u "${MYSQL_DB_USERNAME:?}" \
	      -p"${MYSQL_DB_PASSWORD:?}" \
	      --host="${MYSQL_DB_HOST:?}" \
	      -P"${MYSQL_DB_PORT:?}" \
	      --protocol TCP \
	      -e "$1" \
	      "${MYSQL_DB_NAME:?}" 2> /dev/null
}

function insert_data {
	to_mysql "insert into test (id) values (`date +%s`)"
}

# create the table, because reasons
to_mysql "create table if not exists test (id int);"

# make sure we start with at least some data so the count can work
for run in {1..10}
do
	insert_data
done

#################################################################
# infinitly, count how many rows we have to test that we can still connect

while true; do
	date
	to_mysql "select count(*) from test"
	insert_data
	sleep 1
done
