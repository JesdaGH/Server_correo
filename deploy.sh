#!/bin/bash

# Script de despliegue automatizado para el sistema de correo Docker
# Ejecutar como: ./deploy.sh

echo "🚀 Iniciando despliegue del sistema de correo multi-dominio..."

# Verificar que Docker esté ejecutándose
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker no está ejecutándose"
    exit 1
fi

# Verificar que docker-compose esté disponible
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: docker-compose no está instalado"
    exit 1
fi

echo "✅ Docker y docker-compose disponibles"

# Detener servicios existentes si los hay
echo "🛑 Deteniendo servicios existentes..."
docker-compose down 2>/dev/null || true

# Limpiar volúmenes antiguos si es necesario (opcional)
read -p "¿Deseas limpiar volúmenes existentes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️ Limpiando volúmenes..."
    docker-compose down -v 2>/dev/null || true
fi

# Iniciar servicios
echo "📦 Iniciando servicios..."
docker-compose up -d

# Esperar a que los servicios se inicialicen
echo "⏳ Esperando inicialización de servicios..."
sleep 30

# Verificar estado de los servicios
echo "🔍 Verificando estado de los servicios..."
docker-compose ps

# Configurar enrutamiento entre dominios
echo "🔧 Configurando enrutamiento entre dominios..."

# Esperar a que MTA1 y MTA2 estén listos
echo "⏳ Esperando que los MTA estén listos..."
while ! docker exec mta1 postconf -h myhostname 2>/dev/null; do
    echo "   Esperando MTA1..."
    sleep 5
done

while ! docker exec mta2 postconf -h myhostname 2>/dev/null; do
    echo "   Esperando MTA2..."  
    sleep 5
done

# Configurar transporte MTA2 -> MTA1
echo "🔗 Configurando MTA2 -> MTA1..."
docker exec mta2 bash -c "echo 'example1.local smtp:[mta1]:25' >> /etc/postfix/transport && postmap /etc/postfix/transport && postconf -e 'transport_maps=hash:/etc/postfix/transport' && postfix reload" 2>/dev/null

# Configurar transporte MTA1 -> MTA2  
echo "🔗 Configurando MTA1 -> MTA2..."
docker exec mta1 bash -c "echo 'example2.local smtp:[mta2]:25' >> /etc/postfix/transport && postmap /etc/postfix/transport && postconf -e 'transport_maps=hash:/etc/postfix/transport' && postfix reload" 2>/dev/null

# Configurar redes de confianza
echo "🛡️ Configurando redes de confianza..."
docker exec mta1 bash -c "postconf -e 'mynetworks=172.19.0.0/16,127.0.0.0/8' && postconf -e 'smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination' && postfix reload" 2>/dev/null

docker exec mta2 bash -c "postconf -e 'mynetworks=172.19.0.0/16,127.0.0.0/8' && postconf -e 'smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination' && postfix reload" 2>/dev/null

# Verificar que todo esté funcionando
echo "🧪 Ejecutando pruebas básicas..."

# Verificar conectividad
if docker exec mta1 nc -z mta2 25 2>/dev/null; then
    echo "✅ MTA1 puede conectar con MTA2"
else
    echo "⚠️ Problema de conectividad MTA1 -> MTA2"
fi

if docker exec mta2 nc -z mta1 25 2>/dev/null; then
    echo "✅ MTA2 puede conectar con MTA1"  
else
    echo "⚠️ Problema de conectividad MTA2 -> MTA1"
fi

# Mostrar información de acceso
echo ""
echo "🎉 ¡Despliegue completado!"
echo ""
echo "📧 Acceso a webmails:"
echo "   • MTA1 (example1.local): http://localhost:8081"
echo "   • MTA2 (example2.local): http://localhost:8082"
echo ""
echo "🔐 Credenciales por defecto:"
echo "   • user1@example1.local / password123"
echo "   • user2@example1.local / password123" 
echo "   • user3@example2.local / password123"
echo "   • user4@example2.local / password123"
echo ""
echo "🔧 Comandos útiles:"
echo "   • Ver logs: docker-compose logs -f"
echo "   • Estado servicios: docker-compose ps"
echo "   • Verificar colas: docker exec mta1 postqueue -p"
echo "   • Detener todo: docker-compose down"
echo ""
echo "⏰ Los servicios pueden tardar 2-3 minutos en estar completamente operativos."