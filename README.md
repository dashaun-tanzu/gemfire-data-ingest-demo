# Spring Data with JPA and Gemfire

Sets up Rest endpoints to load ~3mb CSV file.
Data is loaded 1 row at a time.
Data can be stored into either JPA(Postgres) or Gemfire.
The Docker Compose file provides running instances of both Postgres & Gemfire.

# Prerequisites

You must have the gemfire repository configured.

## Quick Start

```text
docker compose up -d postgres
docker compose up -d gemfire-locator-0
docker exec gemfire-data-ingest-demo-gemfire-locator-0-1 gfsh -e 'connect --jmx-manager=gemfire-locator-0[1099]' -e 'configure pdx --read-serialized=true --disk-store'
docker compose up -d gemfire-server-0
docker exec gemfire-data-ingest-demo-gemfire-server-0-1 gfsh -e 'connect --locator=gemfire-locator-0[10334]' -e 'create region --name=stores --type=REPLICATE --skip-if-exists=true'
docker compose up -d management-console
./mvnw clean package spring-boot:start -DskipTests
time http :8080/load-jpa
time http :8080/get-jpa-count
time http :8080/load-gemfire
time http :8080/get-gemfire-count
open http://localhost:7072
./mvnw spring-boot:stop -Dspring-boot.stop.fork
docker compose down
```