@echo off
REM Script de despliegue para Windows PowerShell
REM Ejecutar como: deploy.bat

echo 🚀 Iniciando despliegue del sistema de correo multi-dominio...

REM Verificar que Docker esté ejecutándose
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Docker no está ejecutándose
    pause
    exit /b 1
)

echo ✅ Docker disponible

REM Detener servicios existentes
echo 🛑 Deteniendo servicios existentes...
docker-compose down >nul 2>&1

REM Iniciar servicios
echo 📦 Iniciando servicios...
docker-compose up -d

REM Esperar inicialización
echo ⏳ Esperando inicialización de servicios (30 segundos)...
timeout /t 30 /nobreak >nul

REM Verificar estado
echo 🔍 Verificando estado de los servicios...
docker-compose ps

REM Configurar enrutamiento
echo 🔧 Configurando enrutamiento entre dominios...

REM Esperar que MTA estén listos
echo ⏳ Esperando que los MTA estén listos...
:wait_mta1
docker exec mta1 postconf -h myhostname >nul 2>&1
if %errorlevel% neq 0 (
    echo    Esperando MTA1...
    timeout /t 5 /nobreak >nul
    goto wait_mta1
)

:wait_mta2
docker exec mta2 postconf -h myhostname >nul 2>&1
if %errorlevel% neq 0 (
    echo    Esperando MTA2...
    timeout /t 5 /nobreak >nul
    goto wait_mta2
)

REM Configurar transporte MTA2 -> MTA1
echo 🔗 Configurando MTA2 -^> MTA1...
docker exec mta2 bash -c "echo 'example1.local smtp:[mta1]:25' >> /etc/postfix/transport && postmap /etc/postfix/transport && postconf -e 'transport_maps=hash:/etc/postfix/transport' && postfix reload" >nul 2>&1

REM Configurar transporte MTA1 -> MTA2
echo 🔗 Configurando MTA1 -^> MTA2...
docker exec mta1 bash -c "echo 'example2.local smtp:[mta2]:25' >> /etc/postfix/transport && postmap /etc/postfix/transport && postconf -e 'transport_maps=hash:/etc/postfix/transport' && postfix reload" >nul 2>&1

REM Configurar redes de confianza
echo 🛡️ Configurando redes de confianza...
docker exec mta1 bash -c "postconf -e 'mynetworks=172.19.0.0/16,127.0.0.0/8' && postconf -e 'smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination' && postfix reload" >nul 2>&1
docker exec mta2 bash -c "postconf -e 'mynetworks=172.19.0.0/16,127.0.0.0/8' && postconf -e 'smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination' && postfix reload" >nul 2>&1

echo.
echo 🎉 ¡Despliegue completado!
echo.
echo 📧 Acceso a webmails:
echo    • MTA1 (example1.local): http://localhost:8081
echo    • MTA2 (example2.local): http://localhost:8082
echo.
echo 🔐 Credenciales por defecto:
echo    • user1@example1.local / password123
echo    • user2@example1.local / password123
echo    • user3@example2.local / password123
echo    • user4@example2.local / password123
echo.
echo 🔧 Comandos útiles:
echo    • Ver logs: docker-compose logs -f
echo    • Estado servicios: docker-compose ps
echo    • Verificar colas: docker exec mta1 postqueue -p
echo    • Detener todo: docker-compose down
echo.
echo ⏰ Los servicios pueden tardar 2-3 minutos en estar completamente operativos.
echo.
pause