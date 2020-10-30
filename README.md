installation instruction:
https://www.youtube.com/watch?v=nrzLdMWTRMM 2:30 (intresting),  2:01 (users service - migration)
https://www.youtube.com/watch?v=tdIIJuPh3SI -->  Flack at scale


Set alias:
alias ss_idm='cd ~/Documents/06_Software_Projects/idm; export INSTALL_PATH=$PWD; pushd $INSTALL_PATH/; export PATH=$PATH:$PWD/microflack_admin/bin; cd microflack_admin; source mfvars'

* download microflack_admin in /idm
* ss_idm
* ./setup-host.sh
* ./setup-all-in-one.sh

# Install a service by hand
*  2:25
* ./createTestService.sh ui -u -env
* ./createTestService.sh messages -u -env  #fails --> cause of no service registry: OSError: [Errno 98] Address already in use

# Build service
* mfbuild ui
* mfrun tokens
* mfbuild messages

# Run service
* mfrun ui
* mfrun messages # --> ERROR 1045 (28000): Access denied for user 'root'@'172.17.0.1' (using password: YES)

# Finally worked like this:
* do never use ss_idm
* delete again all other folders except admin
* ran ./setup-all-... :
```
CONTAINER ID        IMAGE                                   COMMAND                  CREATED             STATUS                  PORTS                               NAMES
9ef1ea7b0733        microflack_socketio:latest              "./boot.sh"              2 seconds ago       Up Less than a second   0.0.0.0:32772->5000/tcp             socketio_9ef1ea7b0733
ba5a5b40f9e4        microflack_messages:latest              "./boot.sh"              3 seconds ago       Up 1 second             0.0.0.0:32771->5000/tcp             messages_ba5a5b40f9e4
d12f6d11ce38        microflack_tokens:latest                "./boot.sh"              3 seconds ago       Up 2 seconds            0.0.0.0:32770->5000/tcp             tokens_d12f6d11ce38
1f686433e57b        microflack_users:latest                 "./boot.sh"              4 seconds ago       Up 3 seconds            0.0.0.0:32769->5000/tcp             users_1f686433e57b
1116c2207a7f        microflack_ui:latest                    "./boot.sh"              5 seconds ago       Up 4 seconds            0.0.0.0:32768->5000/tcp             ui_1116c2207a7f
38487a319549        miguelgrinberg/easy-lb-haproxy:latest   "/docker-entrypoint.…"   2 minutes ago       Up 2 minutes            0.0.0.0:80->80/tcp                  lb
1667c70b069e        redis:3.2-alpine                        "docker-entrypoint.s…"   2 minutes ago       Up 2 minutes            0.0.0.0:6379->6379/tcp              redis
dba27323222e        mysql:5.7                               "docker-entrypoint.s…"   2 minutes ago       Up 2 minutes            0.0.0.0:3306->3306/tcp, 33060/tcp   mysql
3bfba992b4bb        miguelgrinberg/easy-etcd:latest         "./boot.sh"              2 minutes ago       Up 2 minutes            0.0.0.0:2379-2380->2379-2380/tcp    etcd
19af94e9b0db        gliderlabs/logspout:latest              "/bin/logspout"          2 minutes ago       Up 2 minutes            0.0.0.0:1095->80/tcp                logspout
```

# Test it:
* 0.0.0.0 worked
* login worked
* 0.0.0.0/stats worked
* ./mfkill socketio worked (see /stats)
* restart:
*  source .profile
*  ./mfrun socketio  --> worked again green.
* login with mobile 192.168.178.26 --> worked.

## Modify ui service
* delete all but _admin folder  
  + --otherwise you will get: ERROR 1045 (28000): Access denied for user 'root'@'172.17.0.1' (using password: YES)
  + it is also enough to delete wheels .mysql_passwords .mysql_root_password .profile
* ./setup-all
* ./createTestService.sh ui -u -env
* stop container of ui service -->
* --> works!!!
* just start the service ./startDEVService.sh ui

## Modify users service
* ./setup-all
* ./createTestService.sh messages -u -env #<-- uses database sqllite in package not the one on docker see .env file if commented or not!
* modify this service
* (env) markus@pc:~/Documents/06_Software_Projects/idm/microflack_users$ flask db upgrade  #<- creates users.sqllite !
* exending with roomid did not work yet: sqlite3.OperationalError: no such column: users.roomid
* simply check the users.sqllite file!


## Testing the api:
* go to: http://0.0.0.0/api/users
* get user by id: http://0.0.0.0/api/users/3
* or http://0.0.0.0/api/messages

## Workflow
* click register or sign in (submit button)
* login (user service)   -> (token service gets request with username and pw -> asks user service if ok before gives out the token)  -> mark user as active (shows up on the right bar).
* /api/users/me endpoint to validate username and password and return user information
* register (POST) -> no token needed.

## Migrations
* see: https://flask-migrate.readthedocs.io/en/latest/ Flask-Migrate uses Alembic
  + flask db init adds migrations folder!
  + 
* used for messages, users
* service cannot create the db! (mysql)
* db creation must be outside! (with admin pw happens in bash script!)
* service can do the migration


# Questions:
* $(ip route get 1 | awk '{print $NF;exit}')
  + -> gives 1000
  + if i set it HOST_IP_ADDRESS=192. --> 0.0.0.0/stats will work
* diffrence between HOST_IP_ADDRESS and MICROFLACK_IP
* ERROR 1045 (28000): Access denied for user 'root'@'172.17.0.1' (using password: YES)
* problem: eventlet 0.29.1 requires dnspython<2.0.0,>=1.15.0, but you'll have dnspython 2.0.0 which is incompatible.
* ask question on scaling: multiple workers!!!
* only one service can run outside docker at a time... (why?)


# TODO
* How is data stored in states (in g, sessions?)
* include rooms and broadcast
* what is mflogs
* how works mfupgrade
* .travis.yml must be updated!!!


MicroFlack's Administration Scripts
===================================

This repository contains installation and administration scripts for MicroFlack.

Environment variables used by microservices
-------------------------------------------

Microservices expect the following environment variables to be defined:

- LB

The URL of the load balancer, for example `http://192.168.33.10`. Required.

- LB_ALGORITHM

The load balancing algorithm to use, for example `roundrobin` or `source`. Optional.

- ETCD

A list of connection endpoints for the etcd service, separated by commas. For example, `http://192.168.33.10:2379` for a single endpoint, or `http://192.168.33.10:2379,http://192.168.33.11:2379` for multiple endpoints. Required.

- REDIS

The IP address and port of the Redis service, for example `192.168.33.10:6379`. Required.

- SECRET_KEY

The user session's secret key. Optional.

- JWT_SECRET_KEY

The token signing key. This key must be the same across all services for token generation and validation to work. Required.

- DATABASE_URL

The SQLAlchemy database connection URL. Optional.

- SERVICE_NAME

The name of the service. Optional.

- SERVICE_URL

The path portion of the URL on which the service will be exposed by the load balancer. Optional.

- HOST_IP_ADDRESS

The IP address the container can use to access the Docker host. Optional.
