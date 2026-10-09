#!/bin/bash
# =============================================================================
# User data - INSTANCIA B (Node-RED con Docker Compose) - Debian 13 (Trixie)
# Pegar completo en: EC2 > Launch instance > Advanced details > User data
# Se ejecuta una sola vez, como root, en el primer arranque.
# Progreso: sudo tail -f /var/log/userdata-nodered.log
# Cuando termina existe el archivo /var/log/userdata-nodered.done
# =============================================================================
set -euxo pipefail
exec > >(tee -a /var/log/userdata-nodered.log) 2>&1

export DEBIAN_FRONTEND=noninteractive
APT="apt-get -o DPkg::Lock::Timeout=300 -y"

# Usuario normal de la instancia (en la AMI de Debian es "admin")
if id admin >/dev/null 2>&1; then
  USR=admin
else
  USR=$(getent passwd 1000 | cut -d: -f1)
fi
HOME_DIR=$(getent passwd "$USR" | cut -d: -f6)
echo "Usuario: $USR  Home: $HOME_DIR"

# --- Paso 1: Docker Engine y plugin Compose (repositorio oficial) ------------
$APT update
$APT install ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release
cat > /etc/apt/sources.list.d/docker.sources <<DOCKERREPO
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
DOCKERREPO

$APT update
$APT install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# Permite usar docker sin sudo (efectivo en el proximo login SSH)
usermod -aG docker "$USR"

# --- Paso 2: directorio persistente con el propietario del contenedor --------
mkdir -p "$HOME_DIR/nodered/data"
chown -R 1000:1000 "$HOME_DIR/nodered/data"

# --- Paso 3: docker-compose.yml ----------------------------------------------
cat > "$HOME_DIR/nodered/docker-compose.yml" <<'COMPOSE'
services:
  nodered:
    image: nodered/node-red:latest
    container_name: nodered
    restart: unless-stopped
    ports:
      - "1880:1880"
    environment:
      - TZ=America/Argentina/Buenos_Aires
    volumes:
      - ./data:/data
    deploy:
      resources:
        limits:
          memory: 512M
COMPOSE
chown "$USR":"$USR" "$HOME_DIR/nodered/docker-compose.yml"

# --- Paso 4: iniciar Node-RED ------------------------------------------------
cd "$HOME_DIR/nodered"
docker compose up -d

echo "Esperando a que Node-RED responda en el puerto 1880..."
for i in $(seq 1 90); do
  if curl -fsS -o /dev/null http://localhost:1880/; then break; fi
  sleep 2
done

# --- Paso 5: nodo del dashboard (Dashboard 2.0) ------------------------------
docker exec -w /data nodered npm install --no-audit --no-fund @flowfuse/node-red-dashboard
docker restart nodered

for i in $(seq 1 90); do
  if curl -fsS -o /dev/null http://localhost:1880/; then break; fi
  sleep 2
done

date > /var/log/userdata-nodered.done
echo "LISTO: Node-RED en http://IP_PUBLICA_DE_B:1880  |  dashboard en /dashboard"
