FROM python:3.12-slim

WORKDIR /app

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir uv

COPY pyproject.toml uv.lock ./
RUN uv pip install --system --locked

COPY flows ./flows
COPY prefect.yaml ./prefect.yaml

CMD ["prefect", "worker", "start", "--pool", "docker-pool"]
