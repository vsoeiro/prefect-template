@echo off
SETLOCAL

:: ================= SETTINGS =================
SET LOCAL_PREFECT_API_URL=http://localhost:4200/api
IF "%WORK_POOL_NAME%"=="" SET WORK_POOL_NAME=worker-pool
IF "%WORKER_IMAGE%"=="" SET WORKER_IMAGE=prefect-template-worker:latest
:: =================================================

echo.
echo ========================================================
echo      STARTING DEPLOY PROCESS - HUBIA INGESTION
echo ========================================================
echo.

echo [1/6] Building worker image...
docker build -t %WORKER_IMAGE% -f Dockerfile .
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to build worker image.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/6] Starting/updating the worker with the built image...
docker compose -f docker-compose-worker.yaml up -d --no-deps prefect-worker
IF %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Could not recreate the worker via docker compose. Start it manually if needed.
)

echo [3/6] Syncing local dependencies with uv...
call uv sync
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to run uv sync.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [4/6] Setting Prefect API URL for local use...
SET PREFECT_API_URL=%LOCAL_PREFECT_API_URL%
call uv run prefect config set PREFECT_API_URL=%LOCAL_PREFECT_API_URL%

echo.
echo [5/6] Ensuring Work Pool exists...
call uv run prefect work-pool inspect "%WORK_POOL_NAME%" >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Work pool not found; creating "%WORK_POOL_NAME%"...
    call uv run prefect work-pool create "%WORK_POOL_NAME%" --type process
    IF %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to create work pool "%WORK_POOL_NAME%".
        pause
        exit /b %ERRORLEVEL%
    )
) ELSE (
    echo (Work Pool exists)
)

echo.
echo [6/6] Registering deployments in Prefect Server...
call uv run prefect deploy --all
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to run prefect deploy.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo      SUCCESS! DEPLOY COMPLETED.
echo ========================================================
echo.
pause
