@echo off
SETLOCAL

:: ================= CONFIGURACOES =================
:: URL da API do Prefect Local
SET LOCAL_PREFECT_API_URL=http://localhost:4200/api
:: Nome da Work Pool
SET WORK_POOL_NAME=docker-pool

:: --- CREDENCIAIS MINIO (PARA O DEPLOY LOCAL) ---
SET AWS_ACCESS_KEY_ID=minioadmin
SET AWS_SECRET_ACCESS_KEY=minioadmin
:: Endpoint visto de FORA do Docker (Windows)
SET AWS_ENDPOINT_URL=http://localhost:9000
:: Região padrão
SET AWS_DEFAULT_REGION=us-east-1
:: =================================================

echo.
echo ========================================================
echo      INICIANDO PROCESSO DE DEPLOY - HUBIA INGESTION
echo ========================================================
echo.

:: 1. Sincronizar dependencias (garante que o urllib3<2 esteja instalado)
echo [1/4] Sincronizando dependencias locais com uv...
call uv sync
IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao rodar uv sync.
    pause
    exit /b %ERRORLEVEL%
)

:: 2. Configurar ambiente local
echo.
echo [2/4] Configurando URL do Prefect Local...
call uv run prefect config set PREFECT_API_URL=%LOCAL_PREFECT_API_URL%

:: 3. Garantir que a Work Pool existe
echo.
echo [3/4] Verificando Work Pool...
call uv run prefect work-pool create "%WORK_POOL_NAME%" --type process >nul 2>&1
echo    (Work Pool garantida)

:: 4. Enviar Deploy
echo.
echo [4/4] Registrando Deploy no Prefect Server...
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