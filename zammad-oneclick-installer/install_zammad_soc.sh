#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Zammad Docker + SOC/SIEM One-Click Installer
# Run this script on VM-SRV-Ticketing-system: 172.16.1.71
# ============================================================

# -------------------------
# CONFIG
# -------------------------
TICKETING_IP="172.16.1.71"
MONITORING_IP="172.16.1.70"
MONITORING_USER="icu01"

ZAMMAD_PORT="8080"
BRIDGE_PORT="8081"
ALERTMANAGER_PORT="9093"

ZAMMAD_COMPOSE_DIR="/opt/zammad-docker-compose"
ZAMMAD_BRIDGE_DIR="/opt/zammad-ticket-bridge"
SOC_STACK_DIR="/opt/soc-siem"

ZAMMAD_DOCKER_REPO="https://github.com/zammad/zammad-docker-compose.git"

# Let op: dit moet eigenlijk een Zammad API-token zijn.
# Je gaf deze waarde door, dus die staat hier ingevuld.
ZAMMAD_API_TOKEN="GuvenKip025!"

ZAMMAD_GROUP="Users"
ZAMMAD_CUSTOMER_EMAIL="soc@example.local"
TZ_VALUE="Europe/Amsterdam"

# -------------------------
# HELPERS
# -------------------------
log() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

warn() {
  echo "[WARNING] $1"
}

require_root_or_sudo() {
  if ! sudo -v; then
    echo "sudo is nodig om dit script uit te voeren."
    exit 1
  fi
}

install_docker() {
  log "Docker installeren/controleren"

  sudo apt update
  sudo apt install -y ca-certificates curl gnupg git

  # Gebruik Ubuntu packages, omdat docker-compose-v2 eerder bij jou werkte.
  sudo apt install -y docker.io docker-compose-v2 python3-docker || {
    warn "docker-compose-v2 niet gevonden. Probeer docker-compose plugin via apt."
    sudo apt install -y docker-compose-plugin || true
  }

  sudo systemctl enable docker
  sudo systemctl start docker

  # Voeg huidige user toe aan docker group als die bestaat
  if id -nG "$USER" | grep -qw docker; then
    echo "User $USER zit al in docker group."
  else
    sudo usermod -aG docker "$USER" || true
    warn "User $USER is toegevoegd aan docker group. Als docker zonder sudo niet werkt, log uit/in of gebruik sudo."
  fi

  docker --version || sudo docker --version
  docker compose version || sudo docker compose version
}

cleanup_old_installation() {
  log "Oude handmatige Zammad/Elasticsearch installatie opruimen"

  sudo systemctl stop zammad 2>/dev/null || true
  sudo systemctl disable zammad 2>/dev/null || true

  sudo systemctl stop elasticsearch 2>/dev/null || true
  sudo systemctl disable elasticsearch 2>/dev/null || true

  sudo systemctl stop zammad-ticket-bridge 2>/dev/null || true
  sudo systemctl disable zammad-ticket-bridge 2>/dev/null || true
  sudo rm -f /etc/systemd/system/zammad-ticket-bridge.service
  sudo systemctl daemon-reload || true

  if [ -d "$ZAMMAD_COMPOSE_DIR" ]; then
    (cd "$ZAMMAD_COMPOSE_DIR" && sudo docker compose down -v) || true
  fi

  if [ -d "$ZAMMAD_BRIDGE_DIR" ]; then
    (cd "$ZAMMAD_BRIDGE_DIR" && sudo docker compose down -v) || true
  fi

  sudo apt purge -y zammad elasticsearch 2>/dev/null || true
  sudo apt autoremove -y || true

  sudo rm -f /etc/apt/sources.list.d/zammad.list
  sudo rm -f /etc/apt/sources.list.d/elastic-8.x.list
  sudo rm -f /etc/nginx/sites-enabled/zammad.conf
  sudo rm -f /etc/nginx/sites-available/zammad.conf

  sudo rm -rf /opt/zammad
  sudo rm -rf "$ZAMMAD_COMPOSE_DIR"
  sudo rm -rf "$ZAMMAD_BRIDGE_DIR"
  sudo rm -rf /var/lib/elasticsearch
  sudo rm -rf /etc/elasticsearch
  sudo rm -rf /var/log/elasticsearch

  echo "Cleanup klaar."
}

deploy_zammad_docker() {
  log "Zammad Docker Compose installeren"

  sudo sysctl -w vm.max_map_count=262144
  echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-zammad-docker.conf >/dev/null
  sudo sysctl --system >/dev/null || true

  sudo mkdir -p "$ZAMMAD_COMPOSE_DIR"
  sudo chown -R "$USER:$USER" "$ZAMMAD_COMPOSE_DIR"

  if [ ! -d "$ZAMMAD_COMPOSE_DIR/.git" ]; then
    git clone "$ZAMMAD_DOCKER_REPO" "$ZAMMAD_COMPOSE_DIR"
  else
    (cd "$ZAMMAD_COMPOSE_DIR" && git pull)
  fi

  cd "$ZAMMAD_COMPOSE_DIR"

  if [ -f ".env.dist" ] && [ ! -f ".env" ]; then
    cp .env.dist .env
  fi

  touch .env

  # Zet poort en timezone idempotent
  if grep -q '^NGINX_EXPOSE_PORT=' .env; then
    sed -i "s/^NGINX_EXPOSE_PORT=.*/NGINX_EXPOSE_PORT=${ZAMMAD_PORT}/" .env
  else
    echo "NGINX_EXPOSE_PORT=${ZAMMAD_PORT}" >> .env
  fi

  if grep -q '^TZ=' .env; then
    sed -i "s|^TZ=.*|TZ=${TZ_VALUE}|" .env
  else
    echo "TZ=${TZ_VALUE}" >> .env
  fi

  sudo docker compose up -d

  echo
  echo "Zammad wordt gestart. Dit kan een paar minuten duren."
  echo "Open straks: http://${TICKETING_IP}:${ZAMMAD_PORT}"
}

deploy_bridge() {
  log "Zammad ticket bridge container installeren"

  sudo mkdir -p "$ZAMMAD_BRIDGE_DIR"
  sudo chown -R "$USER:$USER" "$ZAMMAD_BRIDGE_DIR"
  cd "$ZAMMAD_BRIDGE_DIR"

  cat > requirements.txt <<'EOF'
flask==3.0.3
requests==2.32.3
gunicorn==22.0.0
EOF

  cat > Dockerfile <<'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 8081
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8081", "app:app"]
EOF

  cat > .env <<EOF
ZAMMAD_URL=http://${TICKETING_IP}:${ZAMMAD_PORT}
ZAMMAD_API_TOKEN=${ZAMMAD_API_TOKEN}
ZAMMAD_GROUP=${ZAMMAD_GROUP}
ZAMMAD_CUSTOMER_EMAIL=${ZAMMAD_CUSTOMER_EMAIL}
ZAMMAD_BRIDGE_PORT=${BRIDGE_PORT}
EOF

  chmod 600 .env

  cat > app.py <<'PY'
import os
import hashlib
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

ZAMMAD_URL = os.getenv("ZAMMAD_URL", "http://127.0.0.1:8080").rstrip("/")
ZAMMAD_API_TOKEN = os.getenv("ZAMMAD_API_TOKEN")
ZAMMAD_GROUP = os.getenv("ZAMMAD_GROUP", "Users")
ZAMMAD_CUSTOMER_EMAIL = os.getenv("ZAMMAD_CUSTOMER_EMAIL", "soc@example.local")

if not ZAMMAD_API_TOKEN:
    raise RuntimeError("ZAMMAD_API_TOKEN is not set")

HEADERS = {
    "Authorization": f"Token token={ZAMMAD_API_TOKEN}",
    "Content-Type": "application/json",
}

def fingerprint(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]

def priority_from_severity(severity: str) -> str:
    severity = (severity or "warning").lower()
    if severity in ["critical", "high"]:
        return "3 high"
    if severity in ["warning", "medium"]:
        return "2 normal"
    return "1 low"

def create_zammad_ticket(title: str, body: str, priority: str):
    payload = {
        "title": title,
        "group": ZAMMAD_GROUP,
        "customer_id": f"guess:{ZAMMAD_CUSTOMER_EMAIL}",
        "article": {
            "subject": title,
            "body": body,
            "type": "note",
            "internal": False,
        },
        "priority": priority,
        "state": "new",
    }

    response = requests.post(
        f"{ZAMMAD_URL}/api/v1/tickets",
        headers=HEADERS,
        json=payload,
        timeout=20,
    )
    response.raise_for_status()
    return response.json()

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

@app.route("/webhook/alertmanager", methods=["POST"])
def alertmanager_webhook():
    data = request.get_json(force=True)
    alerts = data.get("alerts", [])
    created = []

    for alert in alerts:
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})

        status = alert.get("status", "unknown")
        alertname = labels.get("alertname", "UnknownAlert")
        instance = labels.get("instance", "unknown-instance")
        severity = labels.get("severity", "warning")
        summary = annotations.get("summary", "")
        description = annotations.get("description", "")

        fp = fingerprint(f"{alertname}|{instance}|{severity}")
        title = f"[{severity.upper()}] {alertname} on {instance}"

        body = f"""Automatisch aangemaakt vanuit SOC/SIEM alerting.

Status: {status}
Severity: {severity}
Alert: {alertname}
Instance: {instance}
Fingerprint: {fp}

Summary:
{summary}

Description:
{description}

Labels:
{labels}

Annotations:
{annotations}
"""

        ticket = create_zammad_ticket(
            title=title,
            body=body,
            priority=priority_from_severity(severity),
        )
        created.append(ticket.get("id"))

    return jsonify({"created_ticket_ids": created})
PY

  cat > docker-compose.yml <<EOF
services:
  zammad-ticket-bridge:
    build: .
    container_name: zammad-ticket-bridge
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "${BRIDGE_PORT}:8081"
EOF

  sudo docker compose up -d --build

  echo "Bridge draait op: http://${TICKETING_IP}:${BRIDGE_PORT}/health"
}

test_bridge_health() {
  log "Bridge health testen"
  curl -s "http://127.0.0.1:${BRIDGE_PORT}/health" || true
  echo
}

test_create_ticket() {
  log "Testticket maken"

  set +e
  curl -X POST "http://127.0.0.1:${BRIDGE_PORT}/webhook/alertmanager" \
    -H "Content-Type: application/json" \
    -d '{
      "alerts": [
        {
          "status": "firing",
          "labels": {
            "alertname": "TestNetworkAlert",
            "instance": "vm-srv-dns:9100",
            "severity": "critical"
          },
          "annotations": {
            "summary": "Test alert vanuit SOC/SIEM",
            "description": "Dit is een automatisch testticket vanuit de SOC/SIEM omgeving."
          }
        }
      ]
    }'
  rc=$?
  set -e

  echo
  if [ "$rc" -ne 0 ]; then
    warn "Testticket maken is mislukt. Waarschijnlijk is Zammad setup/API-token nog niet goed."
    warn "Open eerst http://${TICKETING_IP}:${ZAMMAD_PORT}, maak setup af en maak een echte API-token."
  fi
}

configure_monitoring_alertmanager() {
  log "SOC/SIEM monitoringserver koppelen via Alertmanager"

  echo "Deze stap gebruikt SSH naar ${MONITORING_USER}@${MONITORING_IP}."
  echo "Als SSH keys niet staan, vraagt hij om je wachtwoord."

  ssh "${MONITORING_USER}@${MONITORING_IP}" "sudo mkdir -p ${SOC_STACK_DIR}/alertmanager ${SOC_STACK_DIR}/prometheus/rules"

  tmpdir="$(mktemp -d)"
  cat > "${tmpdir}/alertmanager.yml" <<EOF
global:
  resolve_timeout: 5m

route:
  receiver: zammad
  group_by: ["alertname", "instance"]
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 4h

receivers:
  - name: zammad
    webhook_configs:
      - url: "http://${TICKETING_IP}:${BRIDGE_PORT}/webhook/alertmanager"
        send_resolved: true
EOF

  cat > "${tmpdir}/soc-alerts.yml" <<'EOF'
groups:
  - name: soc-siem-alerts
    rules:
      - alert: HostDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Host is down"
          description: "Prometheus target {{ $labels.instance }} is langer dan 1 minuut down."

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Hoog CPU-gebruik"
          description: "CPU-gebruik op {{ $labels.instance }} is hoger dan 85%."

      - alert: LowDiskSpace
        expr: 100 - ((node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} * 100) / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Weinig vrije schijfruimte"
          description: "Diskgebruik op {{ $labels.instance }} is hoger dan 85%."
EOF

  cat > "${tmpdir}/docker-compose.alertmanager.override.yml" <<EOF
services:
  alertmanager:
    image: prom/alertmanager:latest
    container_name: local-alertmanager
    restart: unless-stopped
    ports:
      - "${ALERTMANAGER_PORT}:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    command:
      - "--config.file=/etc/alertmanager/alertmanager.yml"

  prometheus:
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/rules:/etc/prometheus/rules:ro
EOF

  scp "${tmpdir}/alertmanager.yml" "${MONITORING_USER}@${MONITORING_IP}:/tmp/alertmanager.yml"
  scp "${tmpdir}/soc-alerts.yml" "${MONITORING_USER}@${MONITORING_IP}:/tmp/soc-alerts.yml"
  scp "${tmpdir}/docker-compose.alertmanager.override.yml" "${MONITORING_USER}@${MONITORING_IP}:/tmp/docker-compose.alertmanager.override.yml"

  ssh "${MONITORING_USER}@${MONITORING_IP}" "sudo mv /tmp/alertmanager.yml ${SOC_STACK_DIR}/alertmanager/alertmanager.yml && sudo mv /tmp/soc-alerts.yml ${SOC_STACK_DIR}/prometheus/rules/soc-alerts.yml && sudo mv /tmp/docker-compose.alertmanager.override.yml ${SOC_STACK_DIR}/docker-compose.alertmanager.override.yml"

  # Voeg alerting block toe aan prometheus.yml als die er nog niet staat
  ssh "${MONITORING_USER}@${MONITORING_IP}" "cd ${SOC_STACK_DIR} && if ! grep -q 'ANSIBLE/ONECLICK ALERTMANAGER' prometheus/prometheus.yml; then sudo cp prometheus/prometheus.yml prometheus/prometheus.yml.bak.\$(date +%s); sudo awk 'BEGIN{printed=0} /^scrape_configs:/ && printed==0 {print \"# BEGIN ANSIBLE/ONECLICK ALERTMANAGER\"; print \"alerting:\"; print \"  alertmanagers:\"; print \"    - static_configs:\"; print \"        - targets:\"; print \"            - \\\"alertmanager:9093\\\"\"; print \"\"; print \"rule_files:\"; print \"  - \\\"/etc/prometheus/rules/*.yml\\\"\"; print \"# END ANSIBLE/ONECLICK ALERTMANAGER\"; print \"\"; printed=1} {print}' prometheus/prometheus.yml | sudo tee prometheus/prometheus.yml.new >/dev/null && sudo mv prometheus/prometheus.yml.new prometheus/prometheus.yml; fi"

  ssh "${MONITORING_USER}@${MONITORING_IP}" "cd ${SOC_STACK_DIR} && sudo docker compose -f docker-compose.yml -f docker-compose.alertmanager.override.yml up -d && sudo docker compose restart prometheus"

  rm -rf "$tmpdir"

  echo "Alertmanager: http://${MONITORING_IP}:${ALERTMANAGER_PORT}"
}

main_menu() {
  echo
  echo "Wat wil je doen?"
  echo "1) Alles automatisch: cleanup + Docker + Zammad + bridge"
  echo "2) Alleen cleanup oude installatie"
  echo "3) Alleen Zammad Docker installeren/starten"
  echo "4) Alleen ticket bridge installeren/starten"
  echo "5) Test bridge health"
  echo "6) Testticket maken"
  echo "7) SOC/SIEM koppelen via Alertmanager op monitoringserver"
  echo "8) Alles inclusief monitoring-koppeling"
  echo
  read -rp "Kies optie [1-8]: " choice

  case "$choice" in
    1)
      require_root_or_sudo
      cleanup_old_installation
      install_docker
      deploy_zammad_docker
      echo
      echo "BELANGRIJK:"
      echo "Open nu eerst http://${TICKETING_IP}:${ZAMMAD_PORT} en maak de Zammad setup af."
      echo "Daarna kun je optie 4 draaien voor de bridge."
      ;;
    2)
      require_root_or_sudo
      cleanup_old_installation
      ;;
    3)
      require_root_or_sudo
      install_docker
      deploy_zammad_docker
      ;;
    4)
      require_root_or_sudo
      install_docker
      deploy_bridge
      test_bridge_health
      ;;
    5)
      test_bridge_health
      ;;
    6)
      test_create_ticket
      ;;
    7)
      configure_monitoring_alertmanager
      ;;
    8)
      require_root_or_sudo
      cleanup_old_installation
      install_docker
      deploy_zammad_docker
      deploy_bridge
      configure_monitoring_alertmanager
      test_create_ticket
      ;;
    *)
      echo "Ongeldige keuze."
      exit 1
      ;;
  esac
}

if [ "${1:-}" = "--all" ]; then
  require_root_or_sudo
  cleanup_old_installation
  install_docker
  deploy_zammad_docker
  deploy_bridge
  configure_monitoring_alertmanager
  test_create_ticket
else
  main_menu
fi
