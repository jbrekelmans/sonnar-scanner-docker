#!/usr/bin/env bash
readonly CONTAINING_DIR=$(unset CDPATH && cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$CONTAINING_DIR"/../../test
docker-compose up -d
cd ..
docker build --build-arg="SONAR_URL=http://sonarqube:9000/" --network=test_sonarnet --tag=sonar-scanner-cli:latest .
docker run -v "$CONTAINING_DIR":/workspace --workdir=/workspace --entrypoint sh golang:1.13.4-alpine3.10 -c '
go test ./... -v -coverprofile=coverage.out
go run ./cmd/greeter
'
set -x
docker run \
    -v "$CONTAINING_DIR":/workspace \
    --workdir=/workspace \
    --network=test_sonarnet \
    --entrypoint sh \
    sonar-scanner-cli:latest \
    -c \
    "exec sonar-scanner \
    -Dsonar.host.url='http://sonarqube:9000/' \
    -Dsonar.projectKey='sonar-scanner-docker|golang' \
    -Dsonar.go.coverage.reportPaths=coverage.out
    "


