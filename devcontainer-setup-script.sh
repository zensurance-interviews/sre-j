#!/bin/bash

minikube start --driver=docker --wait=all
minikube addons enable ingress
docker run --rm -d --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"
docker build -t localhost:5000/zen-svc:latest .
docker push localhost:5000/zen-svc:latest