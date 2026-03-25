---
name: dokploy-compose-services
description: Use this skill when working in the dokploy-repository workspace, where each top-level folder is a service run with docker compose. Covers editing per-service docker-compose files, Docker build context folders such as php/v8.4, shared nginx config, and the required external Docker network named ben.
---

# Dokploy Compose Services

This repository is a service catalog for local infrastructure used with Dokploy-style deployments.

Treat each service folder as independently runnable with `docker compose`, while preserving repo-wide conventions.

## Communication

- Always reply to the user in Vietnamese
- Keep technical terms, image names, container names, env vars, and file paths in their original form when needed for accuracy
- When giving run instructions, prefer concise Vietnamese explanations with exact commands preserved

## When This Skill Applies

Use this skill when the task involves:

- Adding or updating a service under a repo folder such as `nginx`, `rabbitmq`, `mssql`, `qdrant`, `open-search`, `elastic-search`, or `falkor-db`
- Editing versioned runtime folders such as `php/v8.4`
- Adjusting Docker build args, image tags, env-driven ports, mounts, or container names
- Troubleshooting how services connect to the shared Docker network
- Documenting how to run a service from this repository

## Repository Shape

- Most service folders contain their own `docker-compose.yml`
- `php/v8.4` is a nested service folder with a custom `DockerFile`
- `nginx` also contains `config.d/` and `certs/`
- The root [README.md](/home/ben/tools/dokploy-repository/README.md) documents a required external Docker network named `ben`

Current compose entrypoints include:

- [elastic-search/docker-compose.yml](/home/ben/tools/dokploy-repository/elastic-search/docker-compose.yml)
- [falkor-db/docker-compose.yml](/home/ben/tools/dokploy-repository/falkor-db/docker-compose.yml)
- [mssql/docker-compose.yml](/home/ben/tools/dokploy-repository/mssql/docker-compose.yml)
- [nginx/docker-compose.yml](/home/ben/tools/dokploy-repository/nginx/docker-compose.yml)
- [open-search/docker-compose.yml](/home/ben/tools/dokploy-repository/open-search/docker-compose.yml)
- [php/v8.4/docker-compose.yml](/home/ben/tools/dokploy-repository/php/v8.4/docker-compose.yml)
- [qdrant/docker-compose.yml](/home/ben/tools/dokploy-repository/qdrant/docker-compose.yml)
- [rabbitmq/docker-compose.yml](/home/ben/tools/dokploy-repository/rabbitmq/docker-compose.yml)

## Working Rules

1. Prefer changing only the service directory relevant to the request.
2. Preserve `docker compose` usage. Do not convert this repo to another orchestrator.
3. Keep services attached to the external Docker network `ben` unless the user explicitly asks to change networking.
4. Preserve env-based configurability such as `${PUBLIC_PORT:-...}`, `${PROJECT_DIR:-...}`, `${CONF_DIR:-...}`, and `${CERT_DIR:-...}`.
5. Keep bind mounts and named volumes stable unless the task requires a migration.
6. When editing `php/v8.4`, keep the build context local to that folder and preserve Docker build args unless intentionally changing runtime versions.
7. When editing `nginx`, avoid breaking the existing host mount layout for `config.d`, `certs`, and `/var/www`.

## Standard Workflow

1. Identify the target service folder.
2. Read that folder's `docker-compose.yml` and any adjacent config files it mounts.
3. Check whether the service depends on env vars, host paths, named volumes, or a custom Docker build.
4. Make the smallest change that satisfies the request while preserving the shared `ben` network pattern.
5. If validation is needed, prefer service-local compose commands from the service directory.

Example validation commands:

```bash
docker network inspect ben
docker compose -f docker-compose.yml config
docker compose up -d
```

For nested runtime folders such as `php/v8.4`, run compose commands from that folder or pass `-f php/v8.4/docker-compose.yml`.

## Service-Specific Notes

- `nginx`: mounts config and cert directories from the repo and mounts `${PROJECT_DIR:-/home/ben/projects}` into `/var/www`
- `php/v8.4`: builds locally from `DockerFile`, mounts the project directory into `/var/www`, and mounts `xdebug.ini`
- `rabbitmq`: expects env vars for default user, password, and disk free limit
- `qdrant`: expects `QDRANT_API_KEY`
- `open-search`: expects `OPENSEARCH_INITIAL_ADMIN_PASSWORD`
- `mssql`: persists data under `./data/sql`
- `elastic-search`: runs both Elasticsearch and Kibana in one compose file

## Guardrails

- Do not remove the `ben` external network declaration unless explicitly requested.
- Do not rename service directories casually; path stability matters for compose workflows.
- Do not replace env placeholders with hard-coded values unless the user asks for that.
- Be careful with port mappings: some files publish explicit host ports, while others rely on Docker-assigned host ports.
- Keep changes compatible with Docker Compose syntax already used in the repo.

## Output Expectations

When making changes in this repository:

- Mention which service folder was changed
- Call out any required env vars or external prerequisites
- Note if the user must ensure `docker network create -d bridge ben` exists before starting services
- Write the response in Vietnamese
