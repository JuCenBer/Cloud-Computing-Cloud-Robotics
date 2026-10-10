Como correr todo en WSL y con docker compose

ANTES de hacer docker compose up

mkdir nodered/data
mkdir simupi/data

sudo chmod -R 1000:1000 nodered/data
sudo chmod -R 1000:1000 simupi/data

docker compose up

Modificaciones hechas

docker-compose.yml
extra_hosts:
      - "simupi:host-gateway"
      - "sumupi:host-gateway"
      - "host.docker.internal:host-gateway"

--> Permiten conectarse con simupi

flow:
Reemplazado "localhost" por "simupi"