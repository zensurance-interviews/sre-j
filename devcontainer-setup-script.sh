#!/bin/bash

minikube delete
minikube start --driver=docker
minikube addons enable registry
docker run --rm -d --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"

echo "Waiting for registry to be ready..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:5000/v2/ > /dev/null 2>&1; then
        echo "Registry is ready!"
        break
    fi
    attempt=$((attempt + 1))
    echo "Waiting for registry... (attempt $attempt/$max_attempts)"
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "Error: Registry failed to become ready after $max_attempts attempts"
    exit 1
fi

docker build -t localhost:5000/zen-svc:latest .
docker push localhost:5000/zen-svc:latest


echo "Terraforming environment..."
cd terraform/
terraform init
terraform apply -auto-approve

echo "all done"