# Spring Data with JPA and Gemfire

Sets up Rest endpoints to load ~6mb CSV file.
Data is loaded 1 row at a time.
Data can be stored into either JPA(Postgres) or Gemfire
The Docker Compose file provides running instances of both Postgres & Gemfire

## Quick Start

```text
docker compose up -d
docker exec gemfire-data-ingest-demo-gemfire-server-0-1 gfsh -e 'connect --locator=gemfire-locator-0[10334]' -e 'create region --name=stores --type=REPLICATE --skip-if-exists=true
./mvnw clean package spring-boot:start -DskipTests
time http :8080/load-jpa
time http :8080/get-jpa-count
time http :8080/load-gemfire
time http :8080/get-gemfire-count
./mvnw spring-boot:stop -Dspring-boot.stop.fork
docker compose down
```