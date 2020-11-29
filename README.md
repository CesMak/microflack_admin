Microflack 2.0 developed by Markus Lamprecht (2020).

A simple Chat App based on a flask highly scalable microservices architecture:

![chat_app](docu/01_overview.png)

see also this [video](docu/mickroflack_2.0.mp4)

Overview of services:
![services_app](docu/02_services.png)

## Related repros
* Services: [ui](https://github.com/CesMak/microflack_ui), [users](https://github.com/CesMak/microflack_users), [messages](https://github.com/CesMak/microflack_messages), [socketio](https://github.com/CesMak/microflack_socketio), [tokens](https://github.com/CesMak/microflack_tokens)
* Other: [service-registry-etcd](https://github.com/CesMak/easy-lb-haproxy)

## Getting started
Tested on Ubuntu 20.04, Python3
0. Create a folder e.g. called idm
1. Set alias in your bashrc:
```
alias ss_idm='cd ~/Documents/06_Software_Projects/idm; export INSTALL_PATH=$PWD; pushd $INSTALL_PATH/; export PATH=$PATH:$PWD/microflack_admin/bin; cd microflack_admin; source mfvars'
```
2. download microflack_admin in /idm
3. ss_idm
4. ./setup-host.sh
5. The following command should setup all on your local machine
```
./setup-all-in-one.sh
```

For more details see these videos by Miguel:
* [mickroflack](https://www.youtube.com/watch?v=nrzLdMWTRMM)
* [Flask at scale](https://www.youtube.com/watch?v=tdIIJuPh3SI)

## Done
* 07.11.2020  changing betweeen https and local mode works with NOT USE command
* 15.11.2020  workflow and understanding tokens
* 17.11.2020  make a new tag! for wheels and install version5! (does not raise status!) --> solved Error: requests.exceptions.HTTPError: 401 Client Error: UNAUTHORIZED for url: http://192.168.178.26/api/users/me
* 29.11.2020 stable version working (with sid)

## TODO
* include rooms (locally on this pc)
 + see under workflow for more info
* test local mfdev mfenv workflow as well as mfupgrade
* test migration
* solve db error (root localhost user)
* test if contab works to renewe certificates inside docker?
* test why not possible to run without internet connection (fully locally? cause works over network!)
* redis container is completely empty? (docker exec -it redis sh)
* is redis used at all?
* TODO where are the db stored????!!
* understand backbone.js -> https://backbonejs.org/#Getting-started

## adding sid
* required for individual server messages (to a specific client)
* alternatively create a room with the nickname and simply join the user to 3 rooms
* nickname room, sid room, roomid ?
* for testing:
* get current client user id (see backbone current user model)
* send a server message to that user
* see also hints at: https://github.com/miguelgrinberg/microflack_messages/issues/9

## Database column adding
- docker exec -it messages_311651440dd8 sh
- with the classic ./rebuild messages the migration folder is not created!
- use /install$ ./cleanAllDB.sh to delete messages and user db!
- delete wheels and mysql-data-dir then do ./setup-all-in-one.sh (this will delete all db!!!)
-> check if messages starts at all! if not migrations folder missing?
-> delete messages image!
* ./startDEVService messages
* ./mfupgrade roll messages
* ./mfrun messages
* docker image ls
* docker rmi <messages>
* ./rebuild messages
  + afterwards migrations folder should be there again
  + docker exec -it messages_e333fb2b08e8 sh


## Migrations
* see: https://flask-migrate.readthedocs.io/en/latest/ Flask-Migrate uses Alembic
  + flask db init adds migrations folder!
* used for messages, users
* service cannot create the db! (mysql)
* db creation must be outside! (with admin pw happens in bash script!)
* service can do the migration

## Make a new microflack_common tag
* inside microflack_common->setup.py change to 0.5 (version) ! very important step!
* git tag -l
* git tag -a v0.5 -m "comment"
* git push origin v0.5
* inside microflack_common test it with: ./mkwheel all
* or simply with
```
(inside microflack_common)
git checkout v0.5
pip wheel -e . --no-deps  #installs the version in the setup.py file!
ls *.whl
```



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

## SPA's and CSR vs SSR
* https://github.com/miguelgrinberg/microflack_ui/issues/6
* https://www.youtube.com/watch?v=Y2spCNZDt84
* Single Page App, Client Side rendering see https://dotcms.com/blog/post/spas-and-server-side-rendering-a-must-or-a-maybe
* **I need to use SPA in js for javascript no forms etc.**
* SSR=Server side rendering
  + faster rendering the site (important if you want to load heavy js files)
  + initial page load is faster
  + great for static sites
  + SEO = Search Enginge Optimization --> crawling is better
  - Not good for sites that are very interactive!!!
  - Non rich site interactions
  - --> Do not use server side rendering!

## Testing the api:
* go to: http://0.0.0.0/api/users
* get user by id: http://0.0.0.0/api/users/3
* or http://0.0.0.0/api/messages

## Workflow
* click register or sign in (submit button)
* login (user service)   -> (token service gets request with username and pw -> asks user service if ok before gives out the token)  -> mark user as active (shows up on the right bar).
* /api/users/me endpoint to validate username and password and return user information
* register (POST) -> no token needed.


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

* copy files: (change beteween local mode and https mode!)
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
stop_id
./setup-all-in-one.sh

if messages and users service keeps restarting (see docker container ls)
you need to sudo ufw disable
```

# TODO HOW TO RENEW SSL CERTIFICATE??? inside docker?
-> muss ich den lb lokal installieren um das hinzubekommen? nicht innerhalb von docker?
* crontab:
  + You have to renew the certificates after 90Days from letsencrypt!
  + sudo crontab -e
  + 30 4 1 * * sudo certbot renew --quiet (must not be changed!)

## TODO  Error 06.11.2020 mysql
- seems like I have 2 pw a root and a localhost? mysql user pw....
docker exec -it mysql mysql -u root -p
Enter password:
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)

mflogs shows: pymysql.err.OperationalError: (1045, "Access denied for user 'users'@'172.17.0.1' (using password: YES)")
users_1bdc1fdc743f|sqlalchemy.exc.OperationalError: (pymysql.err.OperationalError) (1045, "Access denied for user 'users'@'172.17.0.1' (using password: YES)")
users_1bdc1fdc743f|(Background on this error at: http://sqlalche.me/e/13/e3q8)
users_1bdc1fdc743f|USERS DB:  mysql+pymysql://users:lJPq89NCbm1K4Cpc@192.168.178.26:3306/users

## Delte mysql db from outside!!!
```
docker exec -it mysql mysql -u root -p
#enter root mysql pw
mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| messages           |
| mysql              |
| performance_schema |
| sys                |
| users              |
+--------------------+
6 rows in set (0.00 sec)

mysql> USE messages;
mysql> SELECT COUNT(*) FROM messages;
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
1 row in set (0.00 sec)

# check if column exists:
mysql> SELECT sid FROM users;
ERROR 1054 (42S22): Unknown column 'sid' in 'field list' #--> does not exist

# adding a new column if not exists:
DROP PROCEDURE IF EXISTS `?`;
DELIMITER //
CREATE PROCEDURE `?`()
BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
  ALTER TABLE users ADD COLUMN sid VARCHAR(255);
END //
DELIMITER ;
CALL `?`();
DROP PROCEDURE `?`;

# Delete messages:
mysql> USE messages;
mysql> DELETE FROM messages
    -> WHERE roomid=0;
Query OK, 21 rows affected (0.03 sec)

```

- This must be in oneLINE::::: (inside mfrun otherwise access error!)
MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -u root --protocol tcp <<EOF



## CD INTO Docker:
docker exec -it socketio_47d330258694 sh
the environ variable contains inside docker:
docker exec -it socketio_47d330258694 python test.py
environ({'PATH': '/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', 'HOSTNAME': '47d330258694', 'TERM': 'xterm', 'SERVICE_NAME': 'socketio', 'LB': 'http://192.168.178.26', 'JWT_SECRET_KEY': 'J9qQWkhHiaJ721YCkYSRer7jUdD2poC3', 'LB_ALGORITHM': 'source', 'ETCD': 'http://192.168.178.26:2379', 'REDIS': '192.168.178.26:6379', 'LOAD_BALANCER': 'haproxy', 'SECRET_KEY': 'xohmDLNsmDMjoWcqEH2UxWfm8zH0YGul', 'PYTHONUNBUFFERED': '1', 'HOST_IP_ADDRESS': '192.168.178.26', 'SERVICE_URL': '/socket.io', 'LANG': 'C.UTF-8', 'GPG_KEY': '0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D', 'PYTHON_VERSION': '3.6.12', 'PYTHON_PIP_VERSION': '20.2.4', 'PYTHON_GET_PIP_URL': 'https://github.com/pypa/get-pip/raw/8283828b8fd6f1783daf55a765384e6d8d2c5014/get-pip.py', 'PYTHON_GET_PIP_SHA256': '2250ab0a7e70f6fd22b955493f7f5cf1ea53e70b584a84a32573644a045b4bfb', 'SERVICE_VERSION': '1-8-g59cfeaa', 'HOME': '/root'})


# TODO sending a message is not working in https mode!
-> why?
-> registry works
-> cause of socketio!!!!????
-> Firefox can’t establish a connection to the server at wss://idgaming.de/socket.io/?EIO=3&transport=websocket&sid=7ab331a3a0804bf29a93cca98c31282f.
to solve see: https://gist.github.com/Philmod/21b7c8fbd5a2bc20987141bc99966951
see here::: HAPROXY AND WEBSOCKETS: https://www.haproxy.com/blog/websockets-load-balancing-with-haproxy/
see here::: u have to use cookies... ? https://stackoverflow.com/questions/8149038/can-i-have-sticky-sessions-with-haproxy-and-socket-io-with-authentication

02.11.2020
- Das komische mit https und auf https://idgaming.de
- socketio scheint teilweise zu funktionieren...
- die namen werden richtig upgadated auf bildschirm1 aber wenn man eine nachricht schickt dann kommt sie nicht an.
- man sieht jedoch auf bildschirm1 eine nachricht reinpoppen und auch die namen updaten wenn sich einer von bilschrirm2 mit http anmeldet und nachrichten schickt!
- liegt an message queue? I need cookies in my haproxy config?
- Fehler hier dokumentiert! : https://github.com/socketio/socket.io/issues/1942 (**TODO**)
- see also https://github.com/miguelgrinberg/microflack_admin/issues/6
```
The reason the connection still works even with this error is that socket.io is falling back to AJAX, which is not optimal and you should fix your server configuration.
```

- **TODO** teste mit socketio 2.3.0 //cdnjs.cloudflare.com/ajax/libs/socket.io/2.3.0/socket.io.min.js

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


In the **mikroflack_socketio->boot.sh** package I changed:

```
exec gunicorn -b 0.0.0.0:5000 -k eventlet --access-logfile - --error-logfile - app:app
```

to

```
exec gunicorn -b 0.0.0.0:5000 -k eventlet --access-logfile - --log-level debug --error-logfile gunicorn_error.log app:app
```

that gave me:


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

# Error
Do mfrun users
Inside db=users: USERS_DB_PASSWORD fMz6bfgyrA8fyGUW -e DATABASE_URL=mysql+pymysql://users:fMz6bfgyrA8fyGUW@192.168.178.26:3306/users
ERROR 2013 (HY000): Lost connection to MySQL server at 'reading initial communication packet', system error: 22
--> solution ./mfrun users (just do it again)

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



In case you get:
```
Do mfrun users
ERROR 2013 (HY000): Lost connection to MySQL server at 'reading initial communication packet', system error: 22

# or
Do mfrun users
ERROR 1045 (28000): Access denied for user 'root'@'172.17.0.1' (using password: YES)
```

just redo ./mfrun users, ./mfrun messages


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
