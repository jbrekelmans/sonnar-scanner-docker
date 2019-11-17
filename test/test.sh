#!/usr/bin/env bash
readonly CONTAINING_DIR=$(unset CDPATH && cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$CONTAINING_DIR"
docker-compose up -d
cd ..
docker build --build-arg="SONAR_URL=http://sonarqube:9000/" --network=test_sonarnet --tag=sonar-scanner-cli:latest .
# Print image size
docker images --filter=reference=sonar-scanner-cli:latest
docker run \
    --network=test_sonarnet \
    --workdir=/root \
    sonar-scanner-cli:latest \
    -Dsonar.host.url="http://sonarqube:9000/" \
    -Dsonar.projectKey="myrepo|myapp" \
    -X
