#!/bin/bash


echo "Contenu de la base redis avant POST"
curl xavki.localhost:80

echo "POST..."
curl --header "Content-Type: application/json" --request POST --data '{"name":"xavki blog"}' xavki.localhost:80

echo "Contenu de la base redis après POST"
curl xavki.localhost:80
