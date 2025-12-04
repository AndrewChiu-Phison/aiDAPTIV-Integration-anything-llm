@echo off
setlocal enabledelayedexpansion

:: Change to project root directory (from aiDAPTIV_Files\Installer back to project root)
cd /d "%~dp0..\..\"

echo.
echo ================================
echo  Checking if yarn is installed...
echo ================================
echo.

:: Check if yarn command exists
where yarn >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo yarn is not installed, attempting to install yarn globally using npm...
    where npm >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] npm not found on this computer. Please install Node.js and npm before running this batch file.
        echo Download link: https://nodejs.org/
        echo.
        pause
        exit /b 1
    )

    echo Executing: npm install -g yarn
    npm install -g yarn
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] Failed to install yarn. Please check your network connection or permissions and try again.
        echo.
        pause
        exit /b 1
    )
) else (
    echo yarn detected, skipping installation step.
)

echo.
echo ================================
echo  Checking if yarn setup has been executed...
echo ================================
echo.

:: Check if yarn setup has been executed
:: Criteria: Check if node_modules directories exist in server, collector, and frontend subdirectories
set NEED_SETUP=0

if not exist "server\node_modules" (
    echo [Check] server\node_modules does not exist
    set NEED_SETUP=1
) else (
    echo [Check] server\node_modules exists
)

if not exist "collector\node_modules" (
    echo [Check] collector\node_modules does not exist
    set NEED_SETUP=1
) else (
    echo [Check] collector\node_modules exists
)

if not exist "frontend\node_modules" (
    echo [Check] frontend\node_modules does not exist
    set NEED_SETUP=1
) else (
    echo [Check] frontend\node_modules exists
)

if %NEED_SETUP%==0 (
    echo.
    echo All required node_modules directories exist. yarn setup has been executed, skipping this step.
) else (
    echo.
    echo Missing required node_modules directories detected. Need to execute yarn setup...
    echo.
    echo ================================
    echo  Executing yarn setup...
    echo ================================
    echo.

    yarn setup
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] Failed to execute "yarn setup". Please check the error messages.
        echo.
        pause
        exit /b 1
    )
    
    echo.
    echo yarn setup completed successfully!
)

echo.
echo ================================
echo  Setting up Prisma...
echo ================================
echo.

:: Check if server directory exists
if not exist "server" (
    echo [Error] server directory does not exist!
    echo.
    pause
    exit /b 1
)

:: Check if server node_modules exists
if not exist "server\node_modules" (
    echo [Warning] server\node_modules does not exist. Prisma may not be installed.
    echo Installing Prisma packages in server...
    cd server
    yarn add prisma @prisma/client --dev
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] Failed to install Prisma packages. Please check the error messages.
        echo.
        cd ..
        pause
        exit /b 1
    )
    echo Prisma packages installed successfully.
    cd ..
) else (
    echo server\node_modules exists, checking Prisma installation...
)

:: Ensure Prisma is available (check via npx prisma -v)
echo.
echo Checking Prisma CLI...
cd server
if %ERRORLEVEL% NEQ 0 (
    echo [Error] Failed to change to server directory!
    pause
    exit /b 1
)

:: Check if Prisma is installed by checking for prisma binary
if exist "node_modules\.bin\prisma.cmd" (
    echo Prisma binary found, checking version...
    call npx prisma -v
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Prisma CLI not working. Re-installing Prisma packages in server...
        echo This may take a few minutes...
        :: Try to (re)install prisma and @prisma/client as dev dependencies
        yarn add prisma @prisma/client --dev
        if %ERRORLEVEL% NEQ 0 (
            echo.
            echo [Error] Failed to install Prisma packages. Please check the error messages.
            echo.
            cd ..
            pause
            exit /b 1
        )
        echo Prisma packages installed successfully.
        echo Verifying Prisma installation...
        call npx prisma -v
        if %ERRORLEVEL% NEQ 0 (
            echo.
            echo [Error] Prisma CLI still not working after reinstall. Please check manually.
            echo.
            cd ..
            pause
            exit /b 1
        )
    ) else (
        echo Prisma CLI is available.
    )
) else (
    echo Prisma binary not found. Installing Prisma packages...
    yarn add prisma @prisma/client --dev
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] Failed to install Prisma packages. Please check the error messages.
        echo.
        cd ..
        pause
        exit /b 1
    )
    echo Prisma packages installed successfully.
    echo Verifying Prisma installation...
    call npx prisma -v
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] Prisma CLI still not working after install. Please check manually.
        echo.
        cd ..
        pause
        exit /b 1
    )
)

cd ..
if %ERRORLEVEL% NEQ 0 (
    echo [Error] Failed to return to project root directory!
    pause
    exit /b 1
)
echo.
echo Continuing with Prisma setup...

:: Set environment variable to disable TLS certificate validation
set NODE_TLS_REJECT_UNAUTHORIZED=0

:: Generate Prisma client
echo Executing: yarn prisma:generate
call yarn prisma:generate
set PRISMA_GEN_RESULT=%ERRORLEVEL%
if !PRISMA_GEN_RESULT! NEQ 0 (
    echo.
    echo [Warning] Failed to execute "yarn prisma:generate". Trying to reinstall Prisma and retry...
    echo.
    cd server
    call yarn add prisma @prisma/client --dev
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] Failed to install Prisma packages during retry. Please check the error messages.
        echo.
        cd ..
        pause
        exit /b 1
    )
    echo Re-running yarn prisma:generate after reinstall...
    cd ..
    call yarn prisma:generate
    set PRISMA_GEN_RETRY=%ERRORLEVEL%
    if !PRISMA_GEN_RETRY! NEQ 0 (
        echo.
        echo [Error] \"yarn prisma:generate\" still failing after reinstall. Please check manually.
        echo.
        pause
        exit /b 1
    )
) else (
    echo yarn prisma:generate completed successfully.
)

:: Check if database file exists
echo.
echo Checking database file...
if exist "server\storage\anythingllm.db" (
    echo Database file exists
) else (
    echo Database file does not exist
)

:: Check migration status
echo.
echo Checking Prisma migration status...
cd server
if %ERRORLEVEL% NEQ 0 (
    echo [Error] Failed to change to server directory!
    pause
    exit /b 1
)
call npx prisma migrate status
cd ..
if %ERRORLEVEL% NEQ 0 (
    echo [Error] Failed to return to project root directory!
    pause
    exit /b 1
)

:: Deploy migrations
echo.
echo Deploying Prisma migrations...
cd server
if %ERRORLEVEL% NEQ 0 (
    echo [Error] Failed to change to server directory!
    pause
    exit /b 1
)
call npx prisma migrate deploy
set MIGRATE_DEPLOY_RESULT=%ERRORLEVEL%
if !MIGRATE_DEPLOY_RESULT! NEQ 0 (
    echo.
    echo [Warning] Failed to execute "npx prisma migrate deploy". Continuing anyway...
    echo.
)
cd ..
if %ERRORLEVEL% NEQ 0 (
    echo [Error] Failed to return to project root directory!
    pause
    exit /b 1
)

:: Check migration status again
echo.
echo Checking Prisma migration status after deploy...
cd server
if %ERRORLEVEL% NEQ 0 (
    echo [Error] Failed to change to server directory!
    pause
    exit /b 1
)
call npx prisma migrate status
cd ..
if %ERRORLEVEL% NEQ 0 (
    echo [Error] Failed to return to project root directory!
    pause
    exit /b 1
)

echo.
echo Prisma setup completed successfully!

echo.
echo ================================
echo  Executing yarn dev:all...
echo ================================
echo.

:: Start yarn dev:all in background
start "AnythingLLM Dev Server" cmd /c "yarn dev:all"

:: Wait for server to start (wait 10 seconds)
echo Waiting for server to start...
timeout /t 10 /nobreak >nul

echo.
echo ================================
echo  Opening browser...
echo ================================
echo.

:: Open browser
start http://localhost:3000

echo.
echo ================================
echo  Development server started
echo  Browser opened to http://localhost:3000
echo  To stop the server, close the "AnythingLLM Dev Server" window
echo ================================
echo.
pause

endlocal
exit /b 0

