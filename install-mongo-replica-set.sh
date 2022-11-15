#!/bin/bash

## PORTs
PORT1=$1
PORT2=$2
PORT3=$3

## Username and password
DATABASE_ADMIN_USERNAME=$4
DATABASE_ADMIN_PASSWORD=$5

## Docker network
DOCKER_NETWORK=$6
if [ -z $DOCKER_NETWORK ];
then
    DOCKER_NETWORK="mongo-network-"$( tr -cd a-z </dev/urandom | head -c '4' ; echo '' )
fi

if [ "$EUID" -ne 0 ]
then echo "Please run as root user or run with sudo"
    exit
fi

## Check for docker
docker --version
if [ $? -ne 0 ]
then
    curl -fsSL https://get.docker.com | sh
fi

docker stop mongo1 mongo2 mongo3
docker rm mongo1 mongo2 mongo3
rm d_cmd.js
rm -rf ./config
rm -rf ./data

## Create config and data folders
mkdir -p ./config
mkdir -p ./data/data1
mkdir -p ./data/data2
mkdir -p ./data/data3

## Write config file
cat <<EOF > ./config/mongod.conf
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /data/db
  journal:
    enabled: true
#  engine:
#  mmapv1:
#  wiredTiger:

# where to write logging data.
#systemLog:
#  destination: file
#  logAppend: true
#  logRotate: reopen
#  path: /data/log/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0


# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
    authorization: "disabled"
    keyFile: /opt/keyfile/mongodb-keyfile
    transitionToAuth: true
#operationProfiling:

replication:
    replSetName: rs0
#sharding:

## Enterprise-Only Options:

#auditLog:

#snmp:
EOF

## Create mongod-keyfile:
openssl rand -base64 756 > ./config/mongodb-keyfile
chmod 600 ./config/mongodb-keyfile
chown 999 ./config/mongodb-keyfile

## GET IP
SYSTEM_IP=$(curl -s "https://api.ipify.org/" )

## Write init cmd for database
cat <<EOF > ./d_cmd.js
db = (new Mongo('localhost:27017')).getDB('test')
rs.initiate({"_id":"rs0","members":[{"_id":0,"host":"SYSTEM_IP:PORT1"},{"_id":1,"host":"SYSTEM_IP:PORT2"},{"_id":2,"host":"SYSTEM_IP:PORT3"}]})
show dbs
EOF
sed -i s/SYSTEM_IP/$SYSTEM_IP/g d_cmd.js
sed -i s/PORT1/$PORT1/g d_cmd.js
sed -i s/PORT2/$PORT2/g d_cmd.js
sed -i s/PORT3/$PORT3/g d_cmd.js
sed -i s/DATABASE_ADMIN_USERNAME/$DATABASE_ADMIN_USERNAME/g d_cmd.js
sed -i s/DATABASE_ADMIN_PASSWORD/$DATABASE_ADMIN_PASSWORD/g d_cmd.js

## Create Docker network
docker network create $DOCKER_NETWORK || true

## Run Docker containers
docker run -d --restart always \
--name mongo1 \
-p $PORT1:27017 \
--network $DOCKER_NETWORK \
-e MONGO_INITDB_ROOT_USERNAME=$DATABASE_ADMIN_USERNAME \
-e MONGO_INITDB_ROOT_PASSWORD=$DATABASE_ADMIN_PASSWORD \
--mount src=$PWD/data/data1,target=/data/db,type=bind \
--mount src=$PWD/config/mongod.conf,target=/etc/mongoconfig/mongod.conf,type=bind \
--mount src=$PWD/config/mongodb-keyfile,target=/opt/keyfile/mongodb-keyfile,type=bind \
--mount src=$PWD/d_cmd.js,target=/d_cmd.js,type=bind \
mongo --config /etc/mongoconfig/mongod.conf

docker run -d --restart always \
--name mongo2 \
-p $PORT2:27017 \
--network $DOCKER_NETWORK \
-e MONGO_INITDB_ROOT_USERNAME=$DATABASE_ADMIN_USERNAME \
-e MONGO_INITDB_ROOT_PASSWORD=$DATABASE_ADMIN_PASSWORD \
--mount src=$PWD/data/data2,target=/data/db,type=bind \
--mount src=$PWD/config/mongod.conf,target=/etc/mongoconfig/mongod.conf,type=bind \
--mount src=$PWD/config/mongodb-keyfile,target=/opt/keyfile/mongodb-keyfile,type=bind \
mongo --config /etc/mongoconfig/mongod.conf

docker run -d --restart always \
--name mongo3 \
-p $PORT3:27017 \
--network $DOCKER_NETWORK \
-e MONGO_INITDB_ROOT_USERNAME=$DATABASE_ADMIN_USERNAME \
-e MONGO_INITDB_ROOT_PASSWORD=$DATABASE_ADMIN_PASSWORD \
--mount src=$PWD/data/data3,target=/data/db,type=bind \
--mount src=$PWD/config/mongod.conf,target=/etc/mongoconfig/mongod.conf,type=bind \
--mount src=$PWD/config/mongodb-keyfile,target=/opt/keyfile/mongodb-keyfile,type=bind \
mongo --config /etc/mongoconfig/mongod.conf

cmd_str="docker exec --tty mongo1 /bin/bash -c 'mongosh --host $SYSTEM_IP --port $PORT1 < d_cmd.js; eval "$(exit 0)";'"
eval $cmd_str

## Authorization
sed -i s/"authorization: \"disabled\""/"authorization: \"enabled\""/g ./config/mongod.conf
sed -i s/"transitionToAuth: true"/"transitionToAuth: false"/g ./config/mongod.conf
docker restart mongo1 mongo2 mongo3

cat <<EOF > ./config.log
  Connection URL :
    admin url:
      mongodb://$DATABASE_ADMIN_USERNAME:$DATABASE_ADMIN_PASSWORD@$SYSTEM_IP:$PORT1,$SYSTEM_IP:$PORT2,$SYSTEM_IP:$PORT3/test?replicaSet=rs0&readPreference=primary&ssl=false&authMechanism=DEFAULT&authSource=admin
    proxy:
      mongodb://$DATABASE_ADMIN_USERNAME:$DATABASE_ADMIN_PASSWORD@$SYSTEM_IP:$PORT1,$SYSTEM_IP:$PORT2,$SYSTEM_IP:$PORT3/test?replicaSet=rs0&readPreference=primary&ssl=false&authMechanism=DEFAULT&authSource=admin&proxyPort=20170&proxyHost=127.0.0.1
  Docker network: $DOCKER_NETWORK
  Username: $DATABASE_ADMIN_USERNAME
  Password: $DATABASE_ADMIN_PASSWORD
  IP: $SYSTEM_IP
  Ports: $PORT1 $PORT2 $PORT3
EOF

cat ./config.log