#!/bin/bash
# Script de deployment para VPS
# Archivo: deploy-vps.sh

set -e  # Salir si hay errores

echo "🚀 Iniciando deployment en VPS..."

# 1. Actualizar sistema
echo "📦 Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Instalar dependencias
echo "🐳 Instalando Docker y dependencias..."
sudo apt install -y docker.io docker-compose-plugin nginx certbot python3-certbot-nginx ufw git

# 3. Configurar Docker
echo "⚙️ Configurando Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# 4. Configurar firewall
echo "🔒 Configurando firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp       # SSH
sudo ufw allow 51820/udp    # WireGuard VPN
sudo ufw allow 80/tcp       # HTTP (opcional para reverse proxy)
sudo ufw allow 443/tcp      # HTTPS (opcional para reverse proxy)
sudo ufw --force enable

# 5. Clonar proyecto
echo "📥 Clonando proyecto..."
if [ ! -d "email-mua-mta" ]; then
    git clone https://github.com/Re-21-12/email-mua-mta.git
fi
cd email-mua-mta

# 6. Configurar VPN con IP del servidor
echo "🌐 Configurando VPN..."
VPS_IP=$(curl -s ifconfig.me)
echo "IP del VPS detectada: $VPS_IP"

# Actualizar SERVERURL en docker-compose.yml
sed -i "s/SERVERURL=vps.midominio.com/SERVERURL=$VPS_IP/" Docker-compose.yml

# 7. Iniciar servicios
echo "🏃 Iniciando servicios..."
docker-compose up -d

# 8. Mostrar estado
echo "✅ Deployment completado!"
echo ""
echo "📊 Estado de los servicios:"
docker-compose ps

echo ""
echo "🔗 Accesos disponibles:"
echo "- VPN WireGuard: $VPS_IP:51820"
echo "- Webmail 1: http://$VPS_IP:8081 (via VPN)"
echo "- Webmail 2: http://$VPS_IP:8082 (via VPN)"
echo ""
echo "📋 Próximos pasos:"
echo "1. Configurar clientes VPN usando archivos en config/wireguard/peer*/"
echo "2. (Opcional) Configurar reverse proxy con Nginx"
echo "3. (Opcional) Obtener certificados SSL con certbot"

echo ""
echo "🛠️ Comandos útiles:"
echo "- Ver logs: docker-compose logs -f"
echo "- Reiniciar: docker-compose restart"
echo "- Parar: docker-compose down"