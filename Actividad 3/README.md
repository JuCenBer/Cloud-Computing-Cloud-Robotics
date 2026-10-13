# Actividad 3 - SimuPi + Node-RED con docker compose

SimuPi y Node-RED corren como dos servicios del mismo `docker-compose.yml`.
Docker resuelve el nombre del servicio `simupi`, así que Node-RED se conecta a
`mqtt://simupi:1883` sin depender de IPs.

| Servicio | Puerto | Uso |
|---|---|---|
| simupi  | 1883 | Broker MQTT |
| simupi  | 5000 | API / web de SimuPi (`/api/health`) |
| nodered | 1880 | Editor de Node-RED |

## Requisitos

- Docker (Docker Desktop en Windows, o Docker dentro de Linux/WSL)
- El binario de SimuPi en `simupi/simupi` (Linux x86-64) y sus datos en `simupi/data/`

## Antes del primer `docker compose up`

En Linux/WSL (en Windows con Docker Desktop no hace falta el `chown`):

```bash
mkdir -p nodered/data
chmod +x simupi/simupi
sudo chown -R 1000:1000 nodered/data
```

## Uso

Desde esta carpeta:

```bash
docker compose up -d      # levanta SimuPi + Node-RED
docker compose ps         # estado de los contenedores
docker compose logs -f    # ver logs
docker compose down       # bajar todo
```

Verificar:

```bash
curl http://localhost:5000/api/health   # {"status":"ok"}
```

Node-RED queda en http://localhost:1880.

> No correr SimuPi a mano en paralelo (WSL u otra terminal): chocaría con los puertos 1883/5000.

## Modificaciones hechas

- **docker-compose.yml**: se agregó el servicio `simupi` (imagen `debian:bookworm-slim`
  que ejecuta `./simupi` montando la carpeta `./simupi`). Se quitaron los `extra_hosts`
  con `host-gateway`: con Docker Desktop apuntaban al host Windows y no a WSL, por lo que
  Node-RED no llegaba al broker.
- **flow**: reemplazado `localhost` por `simupi` en la configuración del broker MQTT.
