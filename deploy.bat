@echo off
SETLOCAL

:: ================= CONFIGURACOES =================
SET LOCAL_PREFECT_API_URL=http://localhost:4200/api
IF "%WORK_POOL_NAME%"=="" SET WORK_POOL_NAME=worker-pool
IF "%WORKER_IMAGE%"=="" SET WORKER_IMAGE=prefect-worker:latest
:: =================================================

echo.
echo ========================================================
echo      INICIANDO PROCESSO DE DEPLOY - HUBIA INGESTION
echo ========================================================
echo.

echo [1/6] Buildando imagem do worker...
docker build -t %WORKER_IMAGE% -f Dockerfile.worker .
IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao buildar a imagem do worker.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/6] Subindo/atualizando o worker com a imagem buildada...
docker compose up -d --no-deps prefect-worker
IF %ERRORLEVEL% NEQ 0 (
    echo [ALERTA] Nao foi possivel recriar o worker via docker compose. Suba manualmente se necessario.
)

echo [3/6] Sincronizando dependencias locais com uv...
call uv sync
IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao rodar uv sync.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [4/6] Configurando URL do Prefect Local...
call uv run prefect config set PREFECT_API_URL=%LOCAL_PREFECT_API_URL%

echo.
echo [5/6] Verificando Work Pool...
call uv run prefect work-pool create "%WORK_POOL_NAME%" --type process >nul 2>&1
echo (Work Pool garantida)

echo.
echo [6/6] Registrando Deploy no Prefect Server...
call uv run prefect deploy --all
IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha no comando prefect deploy.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo      SUCESSO! DEPLOY REALIZADO.
echo ========================================================
echo.
pause
