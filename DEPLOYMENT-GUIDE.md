# Guía de Deployment en VPS

# Configuración paso a paso para producción

## 🎯 Estrategias de Deployment

### Opción A: Solo VPN (Recomendada para máxima seguridad)

**Firewall:**

- Puerto 51820/udp (WireGuard VPN)
- Puerto 22/tcp (SSH management)

**Acceso:**

- Webmails solo via VPN (10.13.13.1:8081 y 10.13.13.1:8082)
- MTAs solo via VPN
- TLS interno sigue funcionando

### Opción B: Reverse Proxy + VPN (Más flexible)

**Firewall:**

- Puerto 51820/udp (VPN)
- Puerto 80/tcp y 443/tcp (Web público)
- Puerto 22/tcp (SSH)

**Acceso:**

- Webmails públicos: https://mail1.tudominio.com y https://mail2.tudominio.com
- VPN para acceso directo a MTAs

## 📋 Pasos de Deployment

### 1. Preparar VPS

```bash
# Ejecutar script de deployment
chmod +x deploy-vps.sh
./deploy-vps.sh
```

### 2. Configurar DNS (si usas reverse proxy)

```dns
# Registros A
mail1.tudominio.com     A    IP_DEL_VPS
mail2.tudominio.com     A    IP_DEL_VPS

# Registros MX (opcional para correo externo)
example1.local         MX 10  mail1.tudominio.com
example2.local         MX 10  mail2.tudominio.com
```

### 3. Configurar Reverse Proxy (Opción B)

```bash
# Instalar Nginx
sudo apt install nginx certbot python3-certbot-nginx

# Copiar configuración
sudo cp nginx-reverse-proxy.conf /etc/nginx/sites-available/email-proxy
sudo ln -s /etc/nginx/sites-available/email-proxy /etc/nginx/sites-enabled/

# Obtener certificados SSL
sudo certbot --nginx -d mail1.tudominio.com -d mail2.tudominio.com

# Reiniciar Nginx
sudo systemctl reload nginx
```

### 4. Configurar clientes VPN

```bash
# Los archivos de configuración están en:
config/wireguard/peer1/peer1.conf
config/wireguard/peer2/peer2.conf
config/wireguard/peer3/peer3.conf
config/wireguard/peer4/peer4.conf

# Descargar y usar en clientes WireGuard
```

## 🔒 Consideraciones de Seguridad

1. **TLS + VPN = Doble protección**
2. **Firewall restrictivo** (solo puertos necesarios)
3. **Autenticación fuerte** en correo (SHA512-CRYPT)
4. **Acceso SSH por clave** (deshabilitar password)
5. **Updates automáticos** del sistema

## 🧪 Testing

### Verificar VPN

```bash
# En cliente con VPN conectada
ping 10.13.13.1  # Debe responder
curl http://10.13.13.1:8081  # Debe mostrar Roundcube
```

### Verificar correo

- Acceder a webmails
- Enviar correo interno (mismo MTA)
- Enviar correo entre MTAs diferentes

## 📊 Monitoreo

```bash
# Estado de servicios
docker-compose ps

# Logs en tiempo real
docker-compose logs -f

# Uso de recursos
docker stats

# Verificar puertos
sudo netstat -tulpn | grep -E "(51820|8081|8082)"
```
