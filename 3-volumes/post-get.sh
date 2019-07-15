#!/bin/bash


echo "Contenu de la base redis avant POST"
curl localhost:5000

echo "POST..."
curl --header "Content-Type: application/json" --request POST --data '{"name":"Hello Oscaro !!"}' localhost:5000

echo "Contenu de la base redis après POST"
curl localhost:5000
