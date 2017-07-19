# vault/mysql test bench

Purpose: To test 

 - how we wrap [vault](https://www.vaultproject.io/)-provided credentials
 - using [envconsul](https://github.com/hashicorp/envconsul)
 - so that we honor various token and credential TTLs

# how to use

Run using `docker-compose up --force-recreate --build`.

The mysql container leaves state behind. To reset all of the state(s), run `docker-compose rm -f`

# what

 - a `mysql` db server
 - a `vault` server
 - a script that configures the integration between `vault` and `mysql`
 - a script that:
 	- fetches `mysql` creds from vault
 	- connects to `mysql` using those creds using the `mysql` cli
 	- loads some data
 	- then run a query until you are tired of it...