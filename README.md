# Introduction
Small Alpine Docker image (~160MB) with [sonar-scanner-cli](https://github.com/SonarSource/sonar-scanner-cli).

## Building
```bash
docker build --tag=sonar-scanner-cli:latest .
```
To bake the plugin cache into the image (this can reduce scan times depending on your environment), set the SONAR_URL build argument:
```bash
docker build --tag=sonar-scanner-cli:latest --build-arg=SONAR_URL=http://sonarqube:9000/ .
```

## Using the image
The project being analyzed will need to be mounted into the container, for example:
```bash
docker run -v "$(pwd)":/workspace --workdir /workspace sonar-scanner-cli:latest -Dsonar.host.url=http://sonarqube:9000/
```
To configure analysis parameters on the command line, or via a `sonar-scanner.properties` configuration file, refer to the official documentation: https://docs.sonarqube.org/7.9/analysis/scan/sonarscanner/
