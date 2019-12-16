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

  -i, --ip
    list ip for each container

  -j, --jenkins
    run jenkins container

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
    -i|--ip)
      ip
      ;;
    -j|--jenkins)
      jenkins
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

# Let's Go !! parse args  ####################################################################

parse_options $@

ip
