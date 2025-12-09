Prefect Template
================

Minimal setup to run Prefect 3 flows with Postgres, Prefect Server/Services, and a worker container that already includes your code and dependencies.

What’s inside
-------------
- `flows/`: examples; `greetings_flow.py` is the hello-world.
- `prefect.yaml`: deployments (cron, params, pool) without external storage; the code is baked into the worker image.
- `Dockerfile`: builds the worker image (tag comes from `WORKER_IMAGE` in `.env`).
- `docker-compose.yaml`: brings up Prefect Server/Services, Postgres, and the worker (pool and image driven by `.env`).
- `docker-compose-worker.yaml`: runs only the worker when you already have a Prefect API URL.
- `deploy.bat`: builds the worker image, restarts the worker container, syncs deps with `uv`, points CLI to the local API, ensures the work pool, and runs `prefect deploy --all`.

Prerequisites
-------------
- Docker and Docker Compose.
- Python 3.12 with [`uv`](https://github.com/astral-sh/uv) (`pip install uv`).
- Prefect CLI can be global; the script uses `uv run prefect`.

How to use
----------
1) Copy env vars and adjust:
   ```bash
   cp .env.example .env
   ```
2) Start the local stack (builds the image on first run):
   ```bash
   docker compose up -d
   ```
3) Register deployments (and rebuild the worker with current code):
   ```bash
   ./deploy.bat
   ```
   - Does: build (`WORKER_IMAGE`), restart `prefect-worker`, `prefect config set PREFECT_API_URL=...`, ensure pool (`WORK_POOL_NAME`), run `prefect deploy --all`.
   - Manual equivalent:
     ```bash
     uv run prefect deploy --all
     ```
4) Worker only (API already available): `docker compose -f docker-compose-worker.yaml up -d` with `PREFECT_API_URL` pointing to your server.

Flows and layout
----------------
- Add flows under `flows/` and reference them in `prefect.yaml` (entrypoint, params).
- Rebuild the image when code or deps change (`docker compose build prefect-worker` or `./deploy.bat`).
- Pool: image starts `prefect worker start --pool ${WORK_POOL_NAME}`; adjust labels/vars via CLI/UI. If you change the pool name, keep `WORK_POOL_NAME` in `.env` and `work_pool.name` in `prefect.yaml` in sync.
- UI: http://localhost:4200 (local compose).

Roadmap / open points
---------------------
- Worker restart in `deploy.bat` can interrupt running flows; add rolling update/health-check or zero-downtime refresh.
- Image and deployment versioning (avoid `latest`; tag builds and register deployments with the tag used).
- CI/CD should handle build/push and `prefect deploy`; keep the `.bat` for local dev only.
- Evaluate pulling code/artifacts vs rebuilding the image on every change (performance vs consistency).
- Scaling model: currently one container per worker; validate if multiple workers/replicas per image or higher concurrency on fewer workers is better when many workers are needed.

Notes
-----
- `.prefectignore` excludes virtualenvs and editor artifacts.
- Worker `working_dir` is `/app`, aligned to the Dockerfile `WORKDIR`.
- Prefect docs: https://docs.prefect.io/v3/get-started
