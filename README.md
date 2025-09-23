[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

![Demo](demo.gif)

# Spring Data with JPA and Gemfire

- Sets up Rest endpoints to load ~3mb CSV file.
- Data is loaded 1 row at a time.
- Data can be stored into either JPA(Postgres) or Gemfire.
- The Docker Compose file provides running instances of both Postgres & Gemfire.

# Prerequisites

You must have the gemfire repository configured.

## Quick Start

```text
./demo.sh
```

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