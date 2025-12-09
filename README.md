Prefect Template
================

Lightweight template for building and deploying Prefect 3 flows with a local stack (Postgres, Prefect Server/Services) and a worker image that already contains your code.

What's inside
-------------
- `flows/` keeps sample flows; `greetings_flow.py` is the hello-world example.
- `prefect.yaml` defines deployments (cron, params, work pool) without external storage; the worker already has the code baked in.
- `Dockerfile` builds an image with the project dependencies and starts a Prefect process worker.
- `docker-compose.yaml` brings up Prefect Server + Services, Postgres, and the worker built from the Dockerfile.
- `docker-compose-worker.yaml` runs only the worker container (when you already have a Prefect API available).
- `deploy.bat` builds the worker image, restarts the worker container, syncs local deps with `uv`, points the CLI at the local API, ensures the work pool, and runs `prefect deploy --all`.

Motivation
----------
- Keep a predictable environment (Python 3.12, Prefect 3.6.x, pinned urllib3) so examples run consistently across machines.
- Make iteration faster: rebuild the worker image when code/deps change, re-register deployments, and go.

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
2) Bring up the local stack (builds the worker image on first run):
   ```bash
   docker compose up -d
   ```
3) Register deployments to the local Prefect Server (and rebuild the worker image with your latest code):
   ```bash
   ./deploy.bat
   ```
   - Shortcut: builds the worker image, restarts the worker container, runs `uv run prefect config set PREFECT_API_URL=http://localhost:4200/api`, ensures the `docker-pool` work pool exists, and calls `uv run prefect deploy --all`.
   - Equivalent manual command if you prefer the CLI directly:
     ```bash
     uv run prefect deploy --all
     ```

Using the template
------------------
- Add new flows under `flows/` and reference them in `prefect.yaml` with their entrypoints, parameters, and schedules.
- The provided worker uses the image built from `Dockerfile.worker`; rebuild (`docker compose build prefect-worker` or rerun `./deploy.bat`) whenever flows or dependencies change.
- Work pool: the Compose worker connects to `docker-pool` (process type). Adjust labels/variables as needed via CLI or UI.
- Access the Prefect UI at `http://localhost:4200`.
- For a worker-only run (if you already have a Prefect API URL), use `docker compose -f docker-compose-worker.yaml up -d`.

Multi-file flows
----------------
- Organize `flows/` as a package with submodules (e.g., `flows/services/db.py`, `flows/models/user.py`) and import them from your main flow file.
- Point `prefect.yaml` to the main entrypoint (e.g., `entrypoint: flows/my_flow.py:my_flow`); because the worker image includes the repo contents, everything under `flows/` ships with it.
- Avoid absolute paths; use package-relative imports and keep needed configs/data in the repo so they go into the image.

Multiple automations in one repo
--------------------------------
- Option 1 (cleanest): one repo per automation; each has its own `prefect.yaml`, `Dockerfile.worker`, and `flows/`.
- Option 2 (shared repo): keep each automation under its own folder (e.g., `automations/foo/flows/...` and `automations/bar/flows/...`), point `prefect.yaml` entrypoints to the correct paths, and adjust the Dockerfile copy paths accordingly.
- If flows live in different subfolders, make sure the Dockerfile copies them and that `prefect.yaml` uses the same working directory (`/app` by default).

Notes
-----
- `.prefectignore` excludes virtualenvs and editor artifacts from deployments.
- Flows run inside the worker container via the process work pool, so a new image build is required after code/dependency changes.
- Prefect docs: https://docs.prefect.io/v3/get-started

Next steps (ideas)
------------------
- Add an example flow using parameters, results storage, retries, and task timeouts to showcase Prefect features.
- Include a GitHub Actions workflow that runs lint/tests and registers deployments on merges to `main`.
- Wire alerts/notifications (e.g., Slack or email) for failed runs using Prefect blocks.
