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

    echo.
    echo ================================
    echo  Running Prisma setup commands...
    echo ================================
    echo.

    :: Set environment variable to disable TLS certificate validation
    set NODE_TLS_REJECT_UNAUTHORIZED=0

    :: Generate Prisma client
    echo Executing: yarn prisma:generate
    yarn prisma:generate
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] Failed to execute "yarn prisma:generate". Please check the error messages.
        echo.
        pause
        exit /b 1
    )

    :: Check if database file exists
    echo.
    echo Checking database file...
    if exist "server\storage\anythingllm.db" (
        echo Database file exists
    ) else (
        echo Database file does not exist
    )

    :: Check Prisma migrate status
    echo.
    echo Checking Prisma migrate status...
    cd server
    npx prisma migrate status
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Warning] Prisma migrate status check returned an error.
    )
    cd ..

    :: Deploy Prisma migrations
    echo.
    echo Deploying Prisma migrations...
    cd server
    npx prisma migrate deploy
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Error] Failed to execute "npx prisma migrate deploy". Please check the error messages.
        echo.
        cd ..
        pause
        exit /b 1
    )
    cd ..

    :: Check Prisma migrate status again
    echo.
    echo Checking Prisma migrate status again...
    cd server
    npx prisma migrate status
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [Warning] Prisma migrate status check returned an error.
    )
    cd ..

    echo.
    echo Prisma setup completed successfully!
    echo.
)

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

