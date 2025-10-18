# Sistema de Correo Docker Multi-Dominio

Este proyecto configura un sistema completo de correo electrónico con múltiples dominios usando Docker Compose, incluyendo:

- 2 servidores de correo independientes (MTA1 y MTA2)
- 2 clientes webmail (Roundcube)
- VPN WireGuard
- Enrutamiento automático entre dominios

## 🚀 Características

- ✅ **Autenticación IMAP/SMTP funcional**
- ✅ **Envío de correos sin errores**
- ✅ **Enrutamiento entre dominios automático**
- ✅ **Volúmenes Docker optimizados** (evita problemas de permisos Windows)
- ✅ **Configuración simplificada** (servicios no esenciales deshabilitados)

## 🏗️ Arquitectura del Sistema

### Conceptos Clave

**MUA (Mail User Agent)**: Son los **clientes de correo** - las aplicaciones que usan los usuarios para leer y enviar correos:

- Roundcube (webmail1, webmail2)
- Outlook, Thunderbird, Gmail (web), Apple Mail
- Aplicaciones móviles de correo

**MTA (Mail Transfer Agent)**: Son los **servidores de correo** que transportan y entregan los mensajes:

- Postfix + Dovecot (mta1, mta2)
- Servidores SMTP que manejan el envío
- Servidores que procesan y enrutan correos

### Componentes Técnicos Detallados

#### 📧 **Postfix (MTA - Mail Transfer Agent)**

**Postfix** es el **motor de transporte** que maneja el **envío, recepción y enrutamiento** de correos electrónicos.

**¿Qué hace Postfix?**

- **Envía correos** desde clientes (MUA) hacia otros servidores
- **Recibe correos** de otros servidores de correo
- **Enruta mensajes** entre diferentes dominios
- **Maneja colas** de correos pendientes
- **Aplica políticas** de seguridad y antispam

**Protocolos que maneja:**

- **SMTP (25)**: Recepción desde otros servidores
- **SMTP (587)**: Envío desde clientes (submission)
- **SMTP (465)**: Envío seguro (SMTPS)

**En tu configuración:**

```yaml
# Los puertos que expone Postfix en tus MTAs
ports:
  - "2525:25" # SMTP server-to-server
  - "2587:587" # SMTP submission (clientes)
```

#### 📥 **Dovecot (Servidor de Acceso al Correo)**

**Dovecot** es el **servidor de buzones** que permite que los clientes **lean y gestionen** sus correos almacenados.

**¿Qué hace Dovecot?**

- **Almacena correos** en el sistema de archivos
- **Sirve correos** a los clientes vía IMAP/POP3
- **Maneja autenticación** de usuarios
- **Indexa mensajes** para búsquedas rápidas
- **Gestiona buzones** y carpetas

**Protocolos que maneja:**

- **IMAP (143)**: Acceso completo al buzón (sincronización)
- **IMAPS (993)**: IMAP seguro con SSL/TLS
- **POP3 (110)**: Descarga simple de mensajes
- **POP3S (995)**: POP3 seguro con SSL/TLS

**En tu configuración:**

```yaml
# Los puertos que expone Dovecot en tus MTAs
ports:
  - "2143:143" # IMAP para lectura de correos
```

#### 🤝 **Cómo trabajan Postfix y Dovecot juntos**

```
┌─────────────────┐
│   Roundcube     │ ◄─── Usuario accede vía web
│   (MUA/Cliente) │
└─────┬───────────┘
      │
      ├─── SMTP:587 ───► ┌─────────────┐
      │                  │   Postfix   │ ◄─── Envío de correos
      │                  │    (MTA)    │
      │                  └─────┬───────┘
      │                        │
      │                        ▼
      │                  ┌─────────────┐
      │                  │ Sistema de  │ ◄─── Almacenamiento
      │                  │  Archivos   │
      │                  └─────┬───────┘
      │                        │
      │                        ▲
      │                  ┌─────┴───────┐
      └─── IMAP:143 ───► │   Dovecot   │ ◄─── Lectura de correos
                         │ (Servidor   │
                         │  de Buzón)  │
                         └─────────────┘
```

#### 📋 **Diferencias clave entre Postfix y Dovecot**

| Aspecto                 | Postfix                   | Dovecot             |
| ----------------------- | ------------------------- | ------------------- |
| **Función**             | Transporta/enruta correos | Da acceso a buzones |
| **Protocolo principal** | SMTP                      | IMAP/POP3           |
| **Cuándo actúa**        | Al enviar/recibir         | Al leer correos     |
| **Analogía**            | Servicio postal           | Buzón personal      |

#### 🔄 **Flujo completo en tu sistema**

**Envío de correo:**

1. **Roundcube** se conecta a **Postfix** (puerto 587)
2. **Postfix** procesa y envía el mensaje
3. **Postfix** almacena copia en sistema de archivos
4. **Dovecot** indexa el mensaje para futuras consultas

**Lectura de correo:**

1. **Roundcube** se conecta a **Dovecot** (puerto 143)
2. **Dovecot** busca mensajes en el sistema de archivos
3. **Dovecot** sirve los mensajes vía IMAP
4. **Roundcube** muestra los correos al usuario

**En tu docker-compose.yml:**
Ambos servicios están integrados en la imagen `docker-mailserver`:

```yaml
mta1:
  image: docker.io/mailserver/docker-mailserver:latest
  # Esta imagen incluye:
  # - Postfix (para SMTP)
  # - Dovecot (para IMAP)
  # - Configuraciones integradas
```

**En resumen**: Postfix es el "cartero" que lleva los correos, y Dovecot es el "buzón" donde se almacenan y desde donde los lees.

### Componentes del Sistema

```
┌─────────────────┐    ┌─────────────────┐
│   Webmail1      │    │   Webmail2      │
│  (Roundcube)    │    │  (Roundcube)    │
│   :8081         │    │   :8082         │
│     MUA         │    │     MUA         │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          │ IMAP/SMTP            │ IMAP/SMTP
          │                      │
┌─────────▼───────┐    ┌─────────▼───────┐
│      MTA1       │◄──►│      MTA2       │
│  (Postfix +     │    │  (Postfix +     │
│   Dovecot)      │    │   Dovecot)      │
│ example1.local  │    │ example2.local  │
└─────────────────┘    └─────────────────┘
          │                      │
          └──────────┬───────────┘
                     │
           ┌─────────▼───────┐
           │   VPN WireGuard │
           │     :51820      │
           │                 │
           └─────────────────┘
```

## 🔄 Flujo del Correo Electrónico

### Paso a paso: user1@example1.local → user3@example2.local

#### 1. **Composición del mensaje (MUA → MTA)**

```
Usuario accede webmail1 (localhost:8081)
Webmail1 se conecta a mta1:587 (SMTP)
Envía mensaje a user3@example2.local
```

#### 2. **Procesamiento en MTA origen (mta1)**

```
mta1 (Postfix):
- Verifica autenticación del usuario
- Valida formato del mensaje
- Determina que destino (@example2.local) es externo
- Consulta postfix-transport.cf
```

#### 3. **Resolución de enrutamiento**

```
mta1 encuentra en postfix-transport.cf:
example2.local    smtp:[mta2]:25
```

#### 4. **Transferencia entre MTAs**

```
mta1 → mta2 (puerto 25 interno de Docker)
Protocolo SMTP servidor-a-servidor
```

#### 5. **Recepción en MTA destino (mta2)**

```
mta2 (Postfix):
- Recibe el mensaje de mta1
- Verifica que user3@example2.local existe
- Acepta el mensaje para entrega local
```

#### 6. **Almacenamiento (Dovecot)**

```
Dovecot en mta2:
- Almacena mensaje en buzón de user3
- Actualiza índices y metadatos
- Mensaje disponible vía IMAP
```

#### 7. **Lectura por el destinatario (MTA → MUA)**

```
user3 accede webmail2 (localhost:8082)
Webmail2 se conecta a mta2:143 (IMAP)
Descarga/visualiza el nuevo mensaje
```

### Protocolos Utilizados

| Protocolo | Puerto    | Uso                                           |
| --------- | --------- | --------------------------------------------- |
| **SMTP**  | 25        | Transferencia servidor-a-servidor (MTA ↔ MTA) |
| **SMTP**  | 587       | Envío desde cliente (MUA → MTA)               |
| **IMAP**  | 143       | Lectura de correos (MUA ← MTA)                |
| **HTTP**  | 8081/8082 | Acceso web a Roundcube                        |

### Flujo Interno vs Externo

#### **Correo Interno** (mismo dominio):

```
user1@example1.local → user2@example1.local
MUA → mta1 → Dovecot (mismo servidor) → MUA
```

#### **Correo Entre Dominios** (diferentes dominios):

```
user1@example1.local → user3@example2.local
MUA → mta1 → mta2 → Dovecot → MUA
```

## 📋 Credenciales por defecto

### MTA1 (example1.local)

- `user1@example1.local` / `password123`
- `user2@example1.local` / `password123`
- **Webmail**: http://localhost:8081

### MTA2 (example2.local)

- `user3@example2.local` / `password123`
- `user4@example2.local` / `password123`
- **Webmail**: http://localhost:8082

## 🛠️ Instalación

1. **Clonar el repositorio:**

```bash
git clone <tu-repo-url>
cd email-docker
```

2. **Iniciar los servicios:**

```bash
docker-compose up -d
```

3. **Esperar inicialización (2-3 minutos):**

```bash
docker-compose logs -f mta1 mta2
```

4. **Acceder a los webmails:**

- MTA1: http://localhost:8081
- MTA2: http://localhost:8082

## 📁 Estructura Detallada del Proyecto

```
email-docker/
├── 📄 Docker-compose.yml          # Configuración principal de servicios
├── 📄 README.md                   # Documentación del proyecto
├── 📄 DEPLOYMENT-GUIDE.md         # Guía de despliegue
├── 📄 CHANGELOG.md                # Historial de cambios
├── 📄 LICENSE                     # Licencia del proyecto
├── 📄 deploy.sh / deploy.bat      # Scripts de despliegue
├── 📄 nginx-reverse-proxy.conf    # Configuración proxy inverso
│
├── 📁 config1/                    # 🏢 Configuración MTA1 (example1.local)
│   ├── postfix-accounts.cf        # 👥 Cuentas de usuario y contraseñas
│   ├── postfix-main.cf            # ⚙️  Configuración principal Postfix
│   ├── postfix-relaymap.cf        # 🚦 Enrutamiento hacia otros dominios
│   ├── postfix-transport.cf       # 📮 Mapeo de transporte de correos
│   └── dovecot-quotas.cf          # 💾 Cuotas de almacenamiento
│
├── 📁 config2/                    # 🏢 Configuración MTA2 (example2.local)
│   ├── postfix-accounts.cf        # 👥 Cuentas de usuario y contraseñas
│   ├── postfix-main.cf            # ⚙️  Configuración principal Postfix
│   ├── postfix-transport.cf       # 📮 Enrutamiento hacia otros dominios
│   ├── postfix-relaymap.cf        # 🚦 Mapeo de relay hosts
│   └── dovecot-quotas.cf          # 💾 Cuotas de almacenamiento
│
├── 📁 config/                     # 🔐 Configuración VPN WireGuard
│   └── wireguard/
│       ├── wg_confs/
│       │   └── wg0.conf           # 🌐 Configuración servidor VPN
│       ├── peer1/ peer2/ peer3/   # 👤 Configuraciones de clientes VPN
│       ├── server/                # 🖥️  Claves del servidor VPN
│       ├── coredns/               # 🔍 Configuración DNS interno
│       └── templates/             # 📋 Plantillas de configuración
│
├── 📁 maildata1/                  # 💌 Buzones de correo MTA1
│   └── example1.local/
│       ├── user1/ user2/          # 📬 Buzones individuales usuarios
│
├── 📁 maildata2/                  # 💌 Buzones de correo MTA2
│   └── example2.local/
│       ├── user3/ user4/          # 📬 Buzones individuales usuarios
│
├── 📁 mailstate1/                 # ⚡ Estado y colas MTA1
│   ├── lib-postfix/               # 🏃 Procesos y colas Postfix
│   ├── lib-dovecot/               # 📊 Estados Dovecot
│   ├── lib-amavis/                # 🛡️  Antivirus y antispam
│   └── spool-postfix/             # 📦 Cola de correos pendientes
│
└── 📁 mailstate2/                 # ⚡ Estado y colas MTA2
    ├── lib-postfix/               # 🏃 Procesos y colas Postfix
    ├── lib-dovecot/               # 📊 Estados Dovecot
    ├── lib-amavis/                # 🛡️  Antivirus y antispam
    └── spool-postfix/             # 📦 Cola de correos pendientes
```

### 📋 Descripción detallada de archivos y carpetas

#### 🏗️ **Archivos de Configuración Principal**

##### `Docker-compose.yml`

**Propósito**: Define todos los servicios, redes y volúmenes del sistema

```yaml
services:
  vpn: # Servicio VPN WireGuard
  mta1: # Servidor de correo 1
  webmail1: # Cliente web para MTA1
  mta2: # Servidor de correo 2
  webmail2: # Cliente web para MTA2
```

##### `DEPLOYMENT-GUIDE.md`

**Propósito**: Guía paso a paso para desplegar en producción

##### Scripts de despliegue

**Propósito**: Automatización del despliegue

- `deploy.sh` (Linux/Mac)
- `deploy.bat` (Windows)

#### ⚙️ **Configuraciones MTA1 y MTA2**

##### `postfix-accounts.cf`

**Propósito**: Define usuarios y contraseñas hasheadas
**Ejemplo**:

```plaintext
user1@example1.local|{SHA512-CRYPT}$6$TRKXZ5K788CbjY1Q$cqv...
user2@example1.local|{SHA512-CRYPT}$6$TRKXZ5K788CbjY1Q$cqv...
```

##### `postfix-main.cf`

**Propósito**: Configuraciones principales de Postfix
**Ejemplo**:

```plaintext
# Configuración de timeouts y límites
queue_run_delay = 300s
message_size_limit = 10240000
mailbox_size_limit = 0

# Referencias a otros archivos de configuración
transport_maps = texthash:/tmp/docker-mailserver/postfix-transport.cf
```

##### `postfix-transport.cf` / `postfix-relaymap.cf`

**Propósito**: Enrutamiento entre dominios
**Ejemplo MTA1**:

```plaintext
# Enrutar correos de example2.local hacia MTA2
example2.local    smtp:[mta2]:25
```

**Ejemplo MTA2**:

```plaintext
# Enrutar correos de example1.local hacia MTA1
example1.local    smtp:[mta1]:25
```

##### `dovecot-quotas.cf`

**Propósito**: Límites de almacenamiento por usuario
**Ejemplo**:

```plaintext
user1@example1.local:userdb_quota_rule=*:storage=1G
user2@example1.local:userdb_quota_rule=*:storage=2G
```

#### 🔐 **Configuración VPN WireGuard**

##### `wg_confs/wg0.conf`

**Propósito**: Configuración del servidor VPN
**Ejemplo**:

```ini
[Interface]
Address = 10.13.13.1
ListenPort = 51820
PrivateKey = QEWjmOnMEsU0TzdvXvQbUxtpDBZFMTIpT5vOdkKew0I=

[Peer]
# peer1
PublicKey = 8FWoJ9idk9jg8mS2EjvjfgEIh3tIqGFM+LAngmHMrxg=
AllowedIPs = 10.13.13.2/32
```

##### `peer1/peer1.conf`

**Propósito**: Configuración para cliente VPN
**Ejemplo**:

```ini
[Interface]
Address = 10.13.13.2
PrivateKey = CLIENTE_PRIVATE_KEY

[Peer]
PublicKey = SERVIDOR_PUBLIC_KEY
Endpoint = vps.midominio.com:51820
AllowedIPs = 10.13.13.0/24
```

#### 📬 **Directorios de Datos**

##### `maildata1/` y `maildata2/`

**Propósito**: Almacenamiento físico de correos electrónicos
**Estructura típica**:

```
maildata1/example1.local/user1/
├── cur/           # Correos leídos
├── new/           # Correos nuevos
├── tmp/           # Archivos temporales
├── dovecot.index.log
├── dovecot-uidlist
└── subscriptions  # Carpetas suscritas
```

##### `mailstate1/` y `mailstate2/`

**Propósito**: Estados, procesos y colas del sistema de correo

**Subdirectorios importantes**:

```
mailstate1/
├── lib-postfix/
│   └── master.lock        # Proceso principal Postfix
├── spool-postfix/
│   ├── active/            # Cola de correos siendo procesados
│   ├── deferred/          # Cola de correos diferidos
│   ├── incoming/          # Cola de correos entrantes
│   └── maildrop/          # Buzón de entrada temporal
└── lib-dovecot/
    └── instances          # Instancias activas Dovecot
```

### 🔄 **Flujo de Archivos en Operación**

#### **Al enviar un correo**:

1. `postfix-accounts.cf` → Autenticación usuario
2. `postfix-main.cf` → Configuración procesamiento
3. `postfix-transport.cf` → Decisión enrutamiento
4. `spool-postfix/active/` → Cola de procesamiento
5. `maildata2/ejemplo2.local/user3/new/` → Entrega final

#### **Al leer correos**:

1. `postfix-accounts.cf` → Autenticación IMAP
2. `maildata1/ejemplo1.local/user1/` → Lectura buzón
3. `dovecot.index.log` → Índices optimizados
4. Cliente web/IMAP → Visualización

### 💡 **Archivos que puedes personalizar**

| Archivo                | Personalización                 |
| ---------------------- | ------------------------------- |
| `postfix-accounts.cf`  | ✅ Agregar/quitar usuarios      |
| `postfix-main.cf`      | ✅ Límites, timeouts, políticas |
| `postfix-transport.cf` | ✅ Enrutamiento entre dominios  |
| `dovecot-quotas.cf`    | ✅ Cuotas almacenamiento        |
| `wg0.conf`             | ✅ Red VPN, peers               |
| `Docker-compose.yml`   | ✅ Puertos, servicios           |

## 🔧 Configuraciones importantes

### Volúmenes Docker nombrados

El proyecto usa volúmenes Docker nombrados en lugar de bind mounts para evitar problemas de permisos en Windows:

```yaml
volumes:
  maildata1_vol:
    driver: local
  mailstate1_vol:
    driver: local
```

### Enrutamiento entre dominios

Los servidores están configurados para enrutar automáticamente correos entre dominios:

- **MTA1** → **MTA2**: `example2.local smtp:[mta2]:25`
- **MTA2** → **MTA1**: `example1.local smtp:[mta1]:25`

### Servicios deshabilitados

Para evitar conflictos y problemas de rendimiento:

```yaml
environment:
  - ENABLE_OPENDKIM=0
  - ENABLE_OPENDMARC=0
  - ENABLE_POLICYD_SPF=0
  - ENABLE_AMAVIS=0
```

## 🐛 Problemas comunes resueltos

1. **"queue file write error"**: Resuelto con volúmenes Docker nombrados
2. **Errores de autenticación SSL**: Configuración TLS corregida
3. **Correos no llegan**: Sistema de enrutamiento configurado
4. **Problemas de permisos**: Volúmenes Docker en lugar de bind mounts

## 📝 Personalización

### Cambiar contraseñas

Para generar nuevas contraseñas:

```bash
# Generar hash de nueva contraseña
docker exec mta1 doveadm pw -s SHA512-CRYPT -p "tu_nueva_contraseña"

# Actualizar en config1/postfix-accounts.cf y config2/postfix-accounts.cf
```

### Agregar más usuarios

Editar los archivos `postfix-accounts.cf`:

```
nuevo_usuario@example1.local|{SHA512-CRYPT}$hash_generado
```

## 🆘 Troubleshooting

### Verificar estado de servicios

```bash
docker-compose ps
```

### Ver logs

```bash
docker logs mta1 --tail 20
docker logs mta2 --tail 20
```

### Verificar colas de correo

```bash
docker exec mta1 postqueue -p
docker exec mta2 postqueue -p
```

### Forzar procesamiento de colas

```bash
docker exec mta1 postqueue -f
docker exec mta2 postqueue -f
```

## 🌐 Puertos utilizados

| Servicio        | Puerto    | Descripción          |
| --------------- | --------- | -------------------- |
| VPN WireGuard   | 51820/udp | VPN Server           |
| Webmail1        | 8081      | Interface web MTA1   |
| Webmail2        | 8082      | Interface web MTA2   |
| MTA1 SMTP       | 2525      | SMTP MTA1 (externo)  |
| MTA1 IMAP       | 2143      | IMAP MTA1 (externo)  |
| MTA1 Submission | 2587      | SMTP Submission MTA1 |
| MTA2 SMTP       | 3525      | SMTP MTA2 (externo)  |
| MTA2 IMAP       | 3143      | IMAP MTA2 (externo)  |
| MTA2 Submission | 3587      | SMTP Submission MTA2 |

## 📄 Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork del proyecto
2. Crear branch para nueva funcionalidad
3. Commit de cambios
4. Push al branch
5. Crear Pull Request

## 📧 Soporte

Si encuentras problemas:

1. Revisa la sección de troubleshooting
2. Verifica los logs de los contenedores
3. Crea un issue con información detallada

---

**Desarrollado con ❤️ usando Docker y docker-mailserver**

# email-mua-mta
"# Server_correo" 
"# Server_correo" 
"# Server_correo" 
