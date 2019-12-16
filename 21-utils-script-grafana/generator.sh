#!/bin/bash


DIR="${HOME}/generator"
USER_SCRIPT=$USER

# Fonctions ###########################################################

help_list() {
  echo "Usage:

  ${0##*/} [-h][--prometheus][--grafana]

Options:

  -h, --help
    can I help you ?

  -a, --api
    run api for test

  -c, --cassandra
    run cassandra

  -g, --gitlab
    run gitlab

  -gra, --grafana
    run grafana container

  -i, --ip
    list ip for each container

  -j, --jenkins
    run jenkins container

  -m, --mariadb
    run mariadb

  -pos, --postgres
    run postgres

  -pro, --prometheus
    run prometheus container

  "
}

parse_options() {
  case $@ in
    -h|--help)
      help_list
      exit
     ;;
    -a|--api)
      api
      ;;
    -c|--cassandra)
      cassandra
      ;;
    -i|--ip)
      ip
      ;;
    -j|--jenkins)
      jenkins
      ;;
    -g|--gitlab)
      gitlab
      ;;
    -gra|--grafana)
      grafana
      ;;
    -m|--mariadb)
      mariadb
      ;;
    -p|--postgres)
      postgres
      ;;

    -pro|--prometheus)
      prometheus
      ;;

    *)
      echo "Unknown option: ${opt} - Run ${0##*/} -h for help.">&2
      exit 1
  esac
}


ip() {
for i in $(docker ps -q); do docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} - {{.Name}}" $i;done
}

api() {
docker run -d --name httpbin -p 9999:80 kennethreitz/httpbin
firefox -p test 127.0.0.1:9999 &
}

cassandra() {

echo
echo "Install Cassandra"

echo "1 - Create directories ${DIR}/generator/cassandra/"
mkdir -p $DIR/cassandra/


echo "2 - Create docker-compose file"
echo "
version: '3'
services:
  cassandra:
    image: bitnami/cassandra:latest
    container_name: cassandra
    volumes:
    - cassandra_data:/bitnami
    ports:
    - 9042:9042 # cqlsh
    - 7199:7199 # jmx
    - 7000:7000 # internode communication
    - 7001:7001 # tls internode
    - 9160:9160 # client api
    networks:
    - generator
volumes:
  cassandra_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/cassandra/
networks:
  generator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.168.0/24
" >$DIR/docker-compose-cassandra.yml

echo "3 - Run cassandra"
docker-compose -f $DIR/docker-compose-cassandra.yml up -d

echo "4 - Credentials"
echo "
                user: cassandra
                password: cassandra
"
}


gitlab() {

echo
echo "Install Gitlab"

echo "1 - Create directories ${DIR}/generator/gitlab/"
mkdir -p $DIR/gitlab/{config,data,logs}

echo "
version: '3.0'
services:
  web:
   image: 'gitlab/gitlab-ce:latest'
   container_name: gitlab
   hostname: 'gitlab.example.com'
   environment:
     GITLAB_OMNIBUS_CONFIG: |
       external_url 'https://gitlab.example.com'
   expose: 
   - 5000
   ports:
   - 80:80
   - 443:443
   - 5000:5000
   volumes:
   - gitlab_config:/etc/gitlab/
   - gitlab_logs:/var/log/gitlab/
   - gitlab_data:/var/opt/gitlab/
   networks:
   - generator     
volumes:
  gitlab_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/gitlab/data
  gitlab_logs:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/gitlab/logs
  gitlab_config:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/gitlab/config
networks:
  generator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.168.0/24
" >$DIR/docker-compose-gitlab.yml

echo "3 - Run gitlab"
docker-compose -f $DIR/docker-compose-gitlab.yml up -d

echo "Add ip of gitlab container and url gitlab.example.com in your /etc/hosts"

}

grafana() {
echo
echo "Install Grafana"

echo "1 - Create directories ${DIR}/generator/grafana/{etc,data}"
mkdir -p $DIR/grafana/{etc,data}
chmod 775 -R $DIR/grafana/

echo "2 - Create docker compose for grafana"

echo "
version: '3'
services:
  grafana:
    image: grafana/grafana
    container_name: grafana
    user: 0:0
    ports:
     - 3000:3000
    volumes:
     - grafana_data:/var/lib/grafana
     - grafana_etc:/etc/grafana/provisioning/
     networks:
     - generator
volumes:
  grafana_etc:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/grafana/etc/
  grafana_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/grafana/data/
networks:
  generator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.168.0/24
" > $DIR/docker-compose-grafana.yml

echo "3 - Run grafana "
docker-compose -f $DIR/docker-compose-grafana.yml up -d
sleep 10s

echo "4 - Auto setup for local prometheus"
curl --user admin:admin "http://localhost:3000/api/datasources" -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"test","isDefault":true ,"type":"prometheus","url":"http://localhost:9090","access":"proxy","basicAuth":false}'

firefox -p test 127.0.0.1:3000

}


prometheus() {
echo
echo "Install Prometheus"

echo "1 - Create directories ${DIR}/generator/prometheus/{etc,data}"
mkdir -p $DIR/prometheus/{etc,data}
chmod 775 -R $DIR/prometheus/

echo "2 - Create config file prometheus.yml "
echo "
global:
  scrape_interval:     5s # By default, scrape targets every 15 seconds.
  evaluation_interval: 5s # By default, scrape targets every 15 seconds.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first.rules"
  # - "second.rules"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
- job_name: 'node'
  static_configs:
  #- targets: ['172.37.1.1:9100']
" > $DIR/prometheus/etc/prometheus.yml


echo "3 - Create docker compose for prometheus "
echo "
version: '3'
services:
  prometheus:
    image: quay.io/prometheus/prometheus:v2.0.0
    container_name: prometheus
    volumes:
     - prometheus_etc:/etc/prometheus/
     - prometheus_data:/prometheus/
    command: '--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus'
    ports:
     - 9090:9090
    networks:
     - generator
volumes:
  prometheus_etc:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/prometheus/etc/
  prometheus_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/prometheus/data/
networks:
  generator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.168.0/24
" > $DIR/docker-compose-prometheus.yml

echo "4 - Run prometheus "
docker-compose -f $DIR/docker-compose-prometheus.yml up -d

firefox 127.0.0.1:9090

}


jenkins() {

echo
echo "Install Jenkins"

echo "1 - Create directories ${DIR}/jenkins/"
mkdir -p $DIR/jenkins/

echo "2 - Create docker-compose file"
echo "
version: '3'
services:
  jenkins:
    image: 'jenkins/jenkins:lts'
    container_name: jenkins
    user: 0:0
    ports:
      - '8080:8080'
      - '443:8443'
      - '50000:50000'
    volumes:
      - 'jenkins_data:/var/jenkins_home/'
    networks:
     - generator
volumes:
  jenkins_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/jenkins/
networks:
  generator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.168.0/24
" >$DIR/docker-compose-jenkins.yml

echo "3 - Run jenkins "
docker-compose -f $DIR/docker-compose-jenkins.yml up -d

sleep 15s

firefox -p test 127.0.0.1:8080 &
}


mariadb() {

echo
echo "Install Mariadb"

echo "1 - Create directories ${DIR}/generator/mariadb/"
mkdir -p $DIR/mariadb/

echo "2 - Create docker-compose file"
echo "
version: '3'
services:
  mariadb:
    container_name: mariadb
    image: mariadb/server:latest
    volumes:
     - mariadb_data:/var/lib/mysql/
    environment:
      MYSQL_ROOT_PASSWORD: myrootpassword
      MYSQL_DATABASE: mydatabase
      MYSQL_USER: myuser
      MYSQL_PASSWORD: myuserpassword
    ports:
    - 3306:3306
    networks:
    - generator
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/mariadb/
networks:
  generator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.168.0/24
" >$DIR/docker-compose-mariadb.yml

echo "3 - Run mariadb"
docker-compose -f $DIR/docker-compose-mariadb.yml up -d

echo "4 - Credentials"
echo "
      MYSQL_ROOT_PASSWORD: myrootpassword
      MYSQL_DATABASE: mydatabase
      MYSQL_USER: myuser
      MYSQL_PASSWORD: myuserpassword
"

}

postgres() {

echo
echo "Install Postgres"

echo "1 - Create directories ${DIR}/generator/postgres/"
mkdir -p $DIR/postgres/

echo "
version: '3.0'
services:
  web:
   image: postgres:latest
   container_name: postgres
   environment:
   - POSTGRES_USER=myuser
   - POSTGRES_PASSWORD=myuserpassword
   - POSTGRES_DB=mydb
   ports:
   - 5432:5432
   volumes:
   - postgres_data:/var/lib/postgresql/
   networks:
   - generator     
volumes:
  postgres_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/postgres
networks:
  generator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.168.0/24
" >$DIR/docker-compose-postgres.yml

echo "2 - Run postgres"
docker-compose -f $DIR/docker-compose-postgres.yml up -d

echo "
Credentials:
                user: myuser
                password: myuserpassword
                db: mydb
                port: 5432

command : psql -h <ip> -u myuser mydb

"
}



# Let's Go !! parse args  ####################################################################

parse_options $@

ip
