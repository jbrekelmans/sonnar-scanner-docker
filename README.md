# Introduction
Alpine Docker image (~160MB) with [sonar-scanner-cli](https://github.com/SonarSource/sonar-scanner-cli)

## Building
```bash
docker build .
```
To warmup the plugin cache and bake it into the imagae, set the SONAR_URL build argument:
```bash
docker build --build-arg=SONAR_URL=http://sonarqube:9000/ .
```
