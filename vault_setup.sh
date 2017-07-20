#!/bin/bash

# read returns non-zero so we wait for 'set -e' until after we have these vars
mount_point='mysql'

read -r -d '' sql_create_full <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DB_NAME:?};
CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
GRANT ALL PRIVILEGES ON ${MYSQL_DB_NAME:?}.* TO '{{name}}'@'%';
EOF

read -r -d '' sql_revoke <<EOF
DROP USER '{{name}}';
FLUSH PRIVILEGES;
EOF

read -r -d '' policy <<EOF
path "$mount_point/creds/full" {
	policy = "read"
}

path "sys/renew/${mount_point}*" {
	capabilities = ["update"]
}
EOF

set -e

###########################################
# wait for mysql to come online/open a port

while ! nc -z "${MYSQL_DB_HOST:?}" "${MYSQL_DB_PORT:?}"; do
	echo "Waiting for mysql to come online at ${MYSQL_DB_HOST:?}:${MYSQL_DB_PORT:?}..."
	sleep 2.5
done

echo "Found mysql, continuing..."

##############################
# Setup the mysql mount point

# check if vault is set up or not, bail early
if ! vault token-lookup > /dev/null 2>&1; then echo "Set up valid VAULT_ADDR and VAULT_TOKEN."; exit 1; fi

# Set the mount if it's missing
if ! vault mounts | grep $mount_point > /dev/null 2>&1; then
	echo "setting vault mount for $mount_point"
	vault mount -path=$mount_point mysql
fi

echo "vault write $mount_point/config/connection ..."
vault write "$mount_point/config/connection" \
	connection_url="${MYSQL_DB_USERNAME:?}:${MYSQL_DB_PASSWORD:?}@tcp(${MYSQL_DB_HOST:?}:${MYSQL_DB_PORT:?})/" \
	> /dev/null 2>&1

# create the lease with configured value
echo "vault write $mount_point/config/lease ..."
vault write $mount_point/config/lease lease=$MYSQL_VAULT_LEASE lease_max=$MYSQL_VAULT_MAX_LEASE

echo "vault write $mount_point/roles/full ..."
vault write "$mount_point/roles/full" \
	sql="$sql_create_full" \
	revocation_sql="$sql_revoke"

###################################################
# create a policy that allows access to mysql creds

vault policy-write $mount_point <(echo -e "$policy")
vault token-create -policy="$mount_point" \
                   -id="vault-client-token" \
                   -ttl=$TOKEN_TTL


