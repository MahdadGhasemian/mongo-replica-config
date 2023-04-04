# mongo-replica-config

## Run on a server
* $ mkdir db-data
* $ cd db-data
* $ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/mongo-replica-config/main/install-mongo-replica-set.sh | sudo bash -s 27020 27021 27022 admin password

or

* $ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/mongo-replica-config/main/install-mongo-replica-set.sh | sudo bash -s 27020 27021 27022 admin password mongo-docker-version

or

* $ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/mongo-replica-config/main/install-mongo-replica-set.sh | sudo bash -s 27020 27021 27022 admin password mongo-docker-version your-system-ip

or

* $ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/mongo-replica-config/main/install-mongo-replica-set.sh | sudo bash -s 27020 27021 27022 admin password mongo-docker-version your-system-ip app-docker-network

## Run on your local pc
* $ mkdir db-data
* $ cd db-data
* $ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/mongo-replica-config/main/install-mongo-replica-set.sh | sudo bash -s 27020 27021 27022 admin password mongo-docker-version your-system-ip


## After finishing the script shows the connecting link like following:

```
Connection URL :
    admin url:
      mongodb://admin:password@192.168.1.117:27020,192.168.1.117:27021,192.168.1.117:27022/test?replicaSet=rs0&readPreference=primary&ssl=false&authMechanism=DEFAULT&authSource=admin
    proxy:
      mongodb://admin:password@192.168.1.117:27020,192.168.1.117:27021,192.168.1.117:27022/test?replicaSet=rs0&readPreference=primary&ssl=false&authMechanism=DEFAULT&authSource=admin&proxyPort=20170&proxyHost=127.0.0.1
  Docker network: mongo-network-ondf
  Username: admin
  Password: password
  IP: 192.168.1.117
  Ports: 27020 27021 27022
```
