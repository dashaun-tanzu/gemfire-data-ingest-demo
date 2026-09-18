[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

![Demo](demo.gif)

# Spring Data with JPA and Gemfire

Performance demo comparing **Spring Data JPA (Postgres)** vs **Spring Data for GemFire** for a bulk data ingest (~3MB CSV, ~24k rows), plus a JPA batch-insert comparison.

- Rest endpoints to load the CSV, one record at a time, into either store (plus a batch JPA variant).
- Live per-request timing via `time http ...`, Micrometer metrics, and a `/stats` endpoint.
- Docker Compose provisions Postgres and a local GemFire 10.3 cluster (locator + 1 server, PDX enabled, `Stores` region pre-created) with real healthchecks between steps.
- The app binds to a **random port** (`server.port: 0`) so it never conflicts with other apps — `./demo.sh` discovers the actual port at startup.

## Tech Stack

| Component | Version |
|---|---|
| Spring Boot | 4.1.1 |
| Java | 25 (LTS) — pinned via `.sdkmanrc` |
| VMware GemFire | 10.3.1 |
| Spring Boot for VMware GemFire starter | `spring-boot-4.1-gemfire-10.3:2.0.1` |
| GemFire Docker image | `gemfire/gemfire-all:10.3-jdk25` |
| Postgres Docker image | `postgres:latest` |

## Endpoints

| Endpoint | Description |
|---|---|
| `GET /load-jpa` | Load CSV into Postgres, one row at a time (~24k individual inserts) |
| `GET /load-jpa-batch` | Load CSV into Postgres in one `saveAll` batch |
| `GET /load-gemfire` | Load CSV into GemFire, one row at a time |
| `GET /get-jpa-count` | Postgres row count |
| `GET /get-gemfire-count` | GemFire row count |
| `GET /get-jpa-by-id/{id}` | Single Postgres record (e.g. `750931`) |
| `GET /stats` | Both counts plus recorded load durations per strategy |
| `GET /actuator/health` | Health (Postgres + GemFire connectivity) |

> The app binds to a random port. `./demo.sh` reads the port from the startup log
> (`Tomcat started on port <port>`), so `time http :<port>/...` works automatically.
> For a manual run, watch the console log for the assigned port (e.g. `:50418`).

## Prerequisites

- [SDKMAN](https://sdkman.io) with the Java version declared in `.sdkmanrc` (install with `sdk env install`).
- [Docker](https://www.docker.com) with Compose support.
- Access to the VMware GemFire artifacts (the `com.vmware.gemfire` dependencies come from the GemFire commercial repository). `./demo.sh` and the build resolve these through your configured Maven repository (`~/.m2/settings.xml`).
- CLI tools used by `./demo.sh`: `vendir`, `httpie`, `bc`, `git`, `jq`.

## Quick Start

```text
./demo.sh
```

The script:

1. Checks dependencies and sets up Java 25 via SDKMAN.
2. Starts Postgres + the GemFire 10.3 cluster with `docker compose up` (locator and server are health-checked; the PDX and region configurators wait on `service_healthy`).
3. Starts the Spring Boot app.
4. Loads the CSV into JPA and GemFire, timing each.
5. Reads back counts, collects Micrometer `TOTAL_TIME` metrics, and prints a JPA vs GemFire comparison chart.

## Manual Run

```bash
# terminal 1 - services
docker compose up -d --wait

# terminal 2 - app (random port; note the port from the log, e.g. :50418)
./mvnw spring-boot:run

# terminal 3 - exercise the endpoints (replace <port> with the one from the log)
PORT=<port>
time http :$PORT/load-jpa        # load CSV into Postgres, 1 row at a time (~1 min)
time http :$PORT/load-jpa-batch  # same data via saveAll (~3-4s)
time http :$PORT/load-gemfire    # same data into GemFire (~4s)
http :$PORT/get-jpa-count        # 24221
http :$PORT/get-gemfire-count    # 24221
http :$PORT/get-jpa-by-id/750931 # single-record lookup
http :$PORT/stats                # counts + recorded load durations
http :$PORT/actuator/health
```

## Native Image

Not currently supported. Spring Boot 4.1 AOT code generation fails on Spring Data GemFire's
`LazyResolvingComposableRegionConfigurer` bean (`UnsupportedTypeValueCodeGenerationException`).
This is a GemFire starter limitation — if native support is a requirement, watch the
`spring-boot-for-vmware-gemfire` releases.

## CI

`.github/workflows/ci.yml` builds the app, starts the Compose stack, loads data, and asserts both
stores contain `24221` records. Because the GemFire artifacts come from the commercial repository,
the workflow requires three repository secrets:

| Secret | Description |
|---|---|
| `GEMFIRE_REPO_URL` | GemFire commercial Maven repo URL |
| `GEMFIRE_REPO_USERNAME` | Repo username |
| `GEMFIRE_REPO_PASSWORD` | Repo password |

## Attributions
- [Demo Magic](https://github.com/paxtonhare/demo-magic) is pulled via `vendir sync`

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[forks-shield]: https://img.shields.io/github/forks/dashaun-tanzu/gemfire-data-ingest-demo.svg?style=for-the-badge
[forks-url]: https://github.com/dashaun-tanzu/gemfire-data-ingest-demo/forks
[stars-shield]: https://img.shields.io/github/stars/dashaun-tanzu/gemfire-data-ingest-demo.svg?style=for-the-badge
[stars-url]: https://github.com/dashaun-tanzu/gemfire-data-ingest-demo/stargazers
[issues-shield]: https://img.shields.io/github/issues/dashaun-tanzu/gemfire-data-ingest-demo.svg?style=for-the-badge
[issues-url]: https://github.com/dashaun-tanzu/gemfire-data-ingest-demo/issues
