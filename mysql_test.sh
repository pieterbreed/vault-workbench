#!/bin/bash

set -e

instance=`date +%s`

##########################
# funcs, so we can compose

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

function run_test {
	# create the table, because reasons
	to_mysql "create table if not exists test (id int);"
	
	# make sure we start with at least some data so the count can work
	for run in {1..10}
	do
		insert_data
	done
	
	while true; do
		echo "$instance:`date`"
		to_mysql "select count(*) from test"
		insert_data
		sleep 1
	done
}

##############################################
# vault gives us 'dirty' environment variables
# we need to rename them so our scripts look cool

# export MYSQL_DB_PASSWORD="$MYSQL_CREDS_FULL_PASSWORD"
# export MYSQL_DB_USERNAME="$MYSQL_CREDS_FULL_USERNAME"

######################################
# this is the steady-state of the test

run_test
