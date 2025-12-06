Prefect Template
================

This repository is a lightweight template for building and deploying Prefect 3 flows with a fully local stack (Postgres, Redis, Prefect Server/Services, MinIO as S3). It gives teams a repeatable starting point for experiments, workshops, or small services without wiring cloud dependencies first.

What's inside
-------------
- `flows/` contains sample flows; `greetings_flow.py` is a minimal hello-world example.
- `prefect.yaml` defines the deployment (cron schedule, parameters, work pool, S3 push/pull to MinIO).
- `docker-compose.yaml` stands up Prefect Server + Services, a worker bound to a `docker-pool`, Postgres, Redis, and MinIO with its console.
- `deploy.bat` automates local deployment: syncs deps with `uv`, points the CLI to the local API, ensures the work pool exists, and runs `prefect deploy --all`.

Motivation
----------
- Avoid repeating boilerplate when spiking new flows: infra, buckets, and work pools are ready in one command.
- Keep everything local/offline-friendly via MinIO while preserving the same S3 contract used in production.
- Ship a predictable environment (Python 3.12, Prefect 3.6.x, pinned urllib3) so examples run consistently across machines.

Prerequisites
-------------
- Docker and Docker Compose available on your machine.
- Python 3.12 with [`uv`](https://github.com/astral-sh/uv) installed (`pip install uv`), which handles the virtualenv and CLI runs.
- Optional: Prefect CLI installed globally; otherwise `uv run prefect ...` is used by the script.

Quick start
-----------
1) Copy environment defaults and adjust as needed:
   ```bash
   cp .env.example .env
   ```
2) Bring up the local stack:
   ```bash
   docker compose up -d
   ```
3) Register deployments to the local Prefect Server:
   ```bash
   ./deploy.bat
   ```
   This sets `PREFECT_API_URL` to `http://localhost:4200/api`, ensures the `docker-pool` work pool exists, and deploys everything in `prefect.yaml`. Code is pushed to MinIO (bucket `prefect-flows`) so workers can pull it.

Using the template
------------------
- Add new flows under `flows/` and reference them in `prefect.yaml` with their entrypoints, parameters, and schedules.
- Update or add work pools in Prefect UI or CLI as needed; the provided worker in Compose connects to `docker-pool`.
- Access the Prefect UI at `http://localhost:4200` and the MinIO console at `http://localhost:9001` (credentials from `.env`).

Notes
-----
- `.prefectignore` excludes virtualenvs and editor artifacts from deployments.
- The template favors local-first workflows; swap the MinIO endpoint and credentials in `prefect.yaml` when targeting a real S3 service.
- Prefect docs: https://docs.prefect.io/v3/get-started

Next steps (ideas)
------------------
- Add an example flow using parameters, results storage, retries, and task timeouts to showcase Prefect features.
- Include a GitHub Actions workflow that runs lint/tests and registers deployments on merges to `main`.
- Add a Dockerfile for custom worker images with extra dependencies.
- Wire alerts/notifications (e.g., Slack or email) for failed runs using Prefect blocks.
