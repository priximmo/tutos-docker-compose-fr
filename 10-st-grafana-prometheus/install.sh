#!/bin/bash


# 1. création répertoires

mkdir -p ./etc/prometheus/
mkdir -p ./etc/grafana/
mkdir -p ./data/prometheus
mkdir -p ./data/grafana/


# 2. ajout de prometheus.yml

cp prometheus.yml ./etc/prometheus/


# 3. test node exporter

wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz

tar -xzvf node_exporter-0.18.1.linux-amd64.tar.gz -C /usr/local/bin

/usr/loca/bin/node_exporter-0.18.1.linux-amd64/node-exporter



# 4. ajout dans grafana

# add source prometheus
# node_memory_MemFree{instance="\$instance",job="node"}
# node_memory_MemTotal
