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
  + you have to delete mysql-data-dir and wheels folder!
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
* works now....


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
* used for messages, users
* service cannot create the db! (mysql)
* db creation must be outside! (with admin pw happens in bash script!)
* service can do the migration

## Configure HAProxy for SSL/TLS HTTPS Certbot
https://serversforhackers.com/c/using-ssl-certificates-with-haproxy
see example here:https://discourse.haproxy.org/t/convert-working-nginx-to-haproxy-1-6/2770
https://www.haproxy.com/blog/websockets-load-balancing-with-haproxy/
https://danielparker.me/haproxy/nginx/comparison/nginx-vs-haproxy/

https://www.youtube.com/watch?v=jjNNsRYjAyw
* use haproxy as reverse proxy for ngnix
* create A record
* install certbot and haproxy
* /etc/letsencrypt/live.... certivicates
* uses also ngnix as backend
* systemctl start haproxy
* netstat -tnlp
* haproxy -f /etc/haproxy/haproxy.cfg
* curl -vv https://idgaming.de

https://www.youtube.com/watch?v=8fgi2H737Y4 (good video showing also /stats)


## Setup SSH
* [idgaming.de-pc] sudo apt-get install openssh-server
* [idgaming.de-pc] sudo service ssh status
* [client/lenovoz500/remote] ssh-keygen -b 4096
*  this generates id_rsa and id_rsa.pub
* [idgaming.de-pc]  mkdir .ssh
* [idgaming.de-pc]  extend authorized_keys file in .ssh folder with id_rsa.pub
* [idgaming.de-pc] sudo chmod 700 ~/.ssh/
* [idgaming.de-pc] sudo chmod 600 ~/.ssh/*
* [client/lenovoz500/remote]  ssh idgadmin@idgaming.de geht
* [client/lenovoz500/remote]  nach portfreigabe in fritzbox (22) geht nun auch: ssh idgadmin@87.163.45.201



## Setup all on real server (idgaming.de)
* make a snap (before doing all the changes!) on idgaming.de pc
* stop supervisor, stop ngnix: stop_id (on idgaming.de pc)
  ```
  sudo systemctl stop nginx;
  sudo supervisorctl stop idg;
  ```
* sudo ufw disable
* sudo ufw status

* copy files:
```
ssh idgadmin@idgaming.de
mkdir -p ~/idm && cd "$_"
sudo apt install git
git clone https://github.com/CesMak/microflack_admin.git
sudo ./microflack_admin/install/setup-host

#install docker: https://docs.docker.com/engine/install/ubuntu
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
...

# add docker to usergroup: add to usersgroup
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world

cd microflack_admin/install
sudo ./setup-all-in-one.sh

if messages and users service keeps restarting (see docker container ls)
you need to sudo ufw disable
```

# TODO HOW TO RENEW SSL CERTIFICATE??? inside docker?
* crontab:
  + You have to renew the certificates after 90Days from letsencrypt!
  + sudo crontab -e
  + 30 4 1 * * sudo certbot renew --quiet (must not be changed!)

* test if works on machine
sudo curl -vv 0.0.0.0  -> worked


* include https settings!
* Config was not there anymore..... settings is build after first calling the site in browser? It takes some time?
* Its cause of not using miguelgrinbergs package?

-- changed haproxy settings see inside haproxy docker container:  

- docker run --name lb -d --restart always -p 80:80 -e ETCD_PEERS=$ETCD -e HAPROXY_STATS=1 cesmak/easy-lb-haproxy:latest
- docker run --name lb -d --restart always -p 80:80 -e ETCD_PEERS=$ETCD -e HAPROXY_STATS=1 miguelgrinberg/easy-lb-haproxy:latest
- docker exec -it lb ls /usr/local/etc/haproxy
- docker exec -it lb cat /usr/local/etc/haproxy/haproxy.cfg

* add following line on my z500
bind *:443 ssl crt /etc/letsencrypt/live/idgaming.de/all.pem ## --> no must be inside docker! /etc/haproxy/certs/idgaming.de/all.pem
http-request redirect scheme htpps unless {ssl_fc}
* crownjob must be also inside docker!

* then delete docker container and do
docker run --name lb -d --restart always -p 80:80 -e ETCD_PEERS=$ETCD -e HAPROXY_STATS=1 cesmak/easy-lb-haproxy:latest
* check ./mflogs
lb|2020-11-01T19:48:34Z 6468f9389e30 ./confd[163]: INFO Backend source(s) set to http://192.168.178.26:2379
lb|2020-11-01T19:48:34Z 6468f9389e30 ./confd[163]: INFO Target config /usr/local/etc/haproxy/haproxy.cfg out of sync
lb|2020-11-01T19:48:34Z 6468f9389e30 ./confd[163]: ERROR "global\n    log /dev/log    local0\n    log /dev/log    local1 notice\n\ndefaults\n    log    global\n    mode    http\n>
lb|2020-11-01T19:48:34Z 6468f9389e30 ./confd[163]: ERROR Config check failed: exit status 1
no haproxy.cfg file is created!!!

* delete this line again
* build again
* stop and delte lb
* docker run --name lb -d --restart always -p 80:80 -e ETCD_PEERS=$ETCD -e HAPROXY_STATS=1 cesmak/easy-lb-haproxy:latest
* -> site works again .cfg file is created!
--> this means it is not due to haproxy 2.2.4 or confd file!

192.168.178.44

Installation - Links:
https://www.youtube.com/watch?v=cBLYQ8bbe7c
https://www.ssllabs.com/ssltest
https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.1d&guideline=5.6

https://www.youtube.com/watch?v=tgvuQM0qgCE
https://certbot.eff.org/lets-encrypt/ubuntufocal-haproxy

* teste alles auf idgaming.de pc:
* sudo ufw diable
* stop_id
* idgaming.de geht nicht wenn in mfvars und in HOST_IP_ADDRESS
* copy all.pem inside docker container
* sobald bind :443 (auch ohne idgaming.de) -> haproxy.cfg not build anymore....

* haproxy is build like this:
./build.sh
  -> builds Dockerfile
    -> [Dockerfile] copys etc. and starts ./boot.sh(inside the docker image!)
    -> [boot.sh] starts watcher.sh uses haproxy.toml  

* nutze erstmal nicht lb
* dann muss man ui starten mit 192.168.178.44:36843
* ./mfkill all other services but ui
docker container ls
CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS              PORTS                               NAMES
7c9a9aca6338        microflack_ui:latest              "./boot.sh"              3 seconds ago       Up 3 seconds        0.0.0.0:36843->5000/tcp             ui_7c9a9aca6338
62ff9353f334        redis:3.2-alpine                  "docker-entrypoint.s…"   2 hours ago         Up 2 hours          0.0.0.0:6379->6379/tcp              redis
bc48fe408260        mysql:5.7                         "docker-entrypoint.s…"   2 hours ago         Up 2 hours          0.0.0.0:3306->3306/tcp, 33060/tcp   mysql
29e289ed8bdc        miguelgrinberg/easy-etcd:latest   "./boot.sh"              2 hours ago         Up 2 hours          0.0.0.0:2379-2380->2379-2380/tcp    etcd
a26d31c2c483        gliderlabs/logspout:latest        "/bin/logspout"          2 hours ago         Up 2 hours          0.0.0.0:1095->80/tcp                logspout

* Check the ui docker container:  docker exec -it ui_7c9a9aca6338 cat app.py
* docker exec -it ui_7c9a9aca6338 ls
LICENSE           app.py            requirements.txt  wheels
README.md         boot.sh           static
__pycache__       config.py         templates


HAPROXY_USE_SSL
HAPROXY_SERVERNAME
docker exec -it lb sed -i '/^[[:space:]]*$/d' /usr/local/etc/haproxy/haproxy.cfg
redirect scheme https code 301 if !{ ssl_fc }

### SSH HTTPS setup:
* current ngnix setup:
```
/etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;
	client_max_body_size 5M;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}


#mail {
#	# See sample authentication script at:
#	# http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
#
#	# auth_http localhost/auth.php;
#	# pop3_capabilities "TOP" "USER";
#	# imap_capabilities "IMAP4rev1" "UIDPLUS";
#
#	server {
#		listen     localhost:110;
#		protocol   pop3;
#		proxy      on;
#	}
#
#	server {
#		listen     localhost:143;
#		protocol   imap;
#		proxy      on;
#	}
#}

with include /etc/nginx/sites-enabled/*;
/etc/nginx/sites-enabled/idg
	server{
		server_name idgaming.de www.idgaming.de; # 192.168.178.29 1.2.3.4

		location /static/ {
			alias /home/idgadmin/blog/idg/static/;
			expires 30d;
			}		
		location / {
			proxy_pass http://localhost:8000;
			include /etc/nginx/proxy_params;
			proxy_redirect off;

		}
		location /socket.io {
			proxy_pass   http://localhost:8000/socket.io;
			proxy_redirect off;
			include /etc/nginx/proxy_params;
			proxy_http_version 1.1;
        		# proxy_buffering off;
       			# proxy_set_header Upgrade $http_upgrade;
       			# proxy_set_header Connection "Upgrade";			
			# proxy_pass   http://localhost:8000/socket.io;

	      }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/idgaming.de/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/idgaming.de/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
	server{
    if ($host = idgaming.de) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    if ($host = www.idgaming.de) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


		listen 80;
		server_name idgaming.de www.idgaming.de;
    return 404; # managed by Certbot


}
```


# Questions:
* $(ip route get 1 | awk '{print $NF;exit}')
  + -> gives 1000
  + if i set it HOST_IP_ADDRESS=192. --> 0.0.0.0/stats will work
* diffrence between HOST_IP_ADDRESS and MICROFLACK_IP
* ERROR 1045 (28000): Access denied for user 'root'@'172.17.0.1' (using password: YES)
  + you have to delete mysql-data-dir and wheels folder!
  + if you delete wheels all has to be build again why?!
* problem: eventlet 0.29.1 requires dnspython<2.0.0,>=1.15.0, but you'll have dnspython 2.0.0 which is incompatible.
* ask question on scaling: multiple workers!!!
* only one service can run outside docker at a time... (why?)
* what type of confd version is used? 0.11.0 (2015) - can I use a newer version without any risk?
* why did you use haproxy?
* why do the services all use different common package within its requirements see requirements.txt of the diffrent files?
* how to configure gunicorn for multiple workers?
* why is socketio used so diffrently in ui? I would have used it like .... (got always problems with that usage)

# TODO
* teste die app in production mode!!! -> haProxy genauer anschauen!
* schau dir logspout an wie man hier messages anzeigt!
* und schau dir an wie das nun funktionieren würde den aktuellen service
* und den aktuellen lokalen neuen service hochzuladen

* How is data stored in states (in g, sessions?)
* include rooms and broadcast
* what is mflogs
* how works mfupgrade
* .travis.yml must be updated!!!
* AT WHAT TIME IS THE haproxy.cfg file created how to extend it for ssl? https?


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
