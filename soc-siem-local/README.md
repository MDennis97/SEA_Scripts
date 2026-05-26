# SOC/SIEM local teststack

Deze lokale teststack is gebaseerd op de architectuur waarin Grafana het centrale dashboard is voor metrics, logs, tracing en security-informatie.

## Starten op Windows voor lokale test

```powershell
Copy-Item .env.example .env
docker compose up -d
```

Open daarna Grafana:

```text
http://localhost:3000
```

Login standaard lokaal:

```text
admin / admin
```

## Waarom Promtail en node-exporter niet standaard starten

Promtail en node-exporter staan wel in `docker-compose.yml`, maar onder het profile `agents`.

Op Windows met Docker Desktop geven host-mounts zoals `/`, `/var/log` en `/var/lib/docker/containers` vaak problemen. Daarom start je lokaal eerst zonder agents.

## Productie/Linux starten met agents

Op een Linux-server of productieachtige omgeving:

```bash
cp .env.example .env
docker compose --profile agents up -d
```

Dan worden ook deze services gestart:

- `promtail` voor logs naar Loki
- `node-exporter` voor host metrics naar Prometheus

## Services

- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- Loki: http://localhost:3100
- Tempo: http://localhost:3200
- Elasticsearch: http://localhost:9200
- Wazuh Manager: poorten 1514/udp, 1515, 55000

## Stoppen

```bash
docker compose down
```

Alles verwijderen inclusief volumes:

```bash
docker compose down -v
```
