#!/bin/sh

echo "POST TEST..."
curl --header "Content-Type: application/json" --request POST --data '{"name":"xavki blog"}' localhost:80
