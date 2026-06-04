# Zammad Docker + SOC/SIEM koppeling met Ansible

Deze Ansible-map doet drie dingen:

1. Oude handmatige Zammad/Elasticsearch package-installatie opruimen op `172.16.1.71`
2. Zammad opnieuw installeren via Docker Compose op `172.16.1.71`
3. Zammad koppelen aan je SOC/SIEM-stack op `172.16.1.70` via een Docker-container ticket-bridge en Alertmanager

## Architectuur

```text
VM-SRV-Monitoring 172.16.1.70
├── Prometheus
├── Alertmanager
└── SOC/SIEM stack

VM-SRV-Ticketing 172.16.1.71
├── Zammad Docker Compose stack
└── zammad-ticket-bridge Docker container
```

Flow:

```text
Prometheus alert
      ↓
Alertmanager
      ↓
http://172.16.1.71:8081/webhook/alertmanager
      ↓
zammad-ticket-bridge
      ↓
Zammad API
      ↓
Automatisch ticket
```

---

## Gebruik

Pak de zip uit:

```bash
unzip zammad-docker-ansible-soc.zip
cd zammad-docker-ansible-soc
```

Installeer collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Maak je configbestanden:

```bash
cp inventory/hosts.ini.example inventory/hosts.ini
cp group_vars/all.yml.example group_vars/all.yml
```

Controleer `inventory/hosts.ini`:

```ini
[ticketing]
vm-srv-ticketing ansible_host=172.16.1.71 ansible_user=icu01

[monitoring]
vm-srv-monitoring ansible_host=172.16.1.70 ansible_user=icu01
```

---

## Stap 1 — Oude installatie verwijderen

Dit verwijdert package-Zammad, package-Elasticsearch, oude Nginx config, oude bridge en optioneel oude data.

```bash
ansible-playbook playbooks/00-clean-ticketing.yml
```

Standaard staat in `group_vars/all.yml`:

```yaml
cleanup_delete_data: true
```

Dat verwijdert ook oude data onder `/var/lib/elasticsearch`, `/opt/zammad`, `/opt/zammad-ticket-bridge`, enzovoort.

---

## Stap 2 — Zammad met Docker installeren

```bash
ansible-playbook playbooks/01-deploy-zammad-docker.yml
```

Daarna open je:

```text
http://172.16.1.71:8080
```

Doe de eerste Zammad setup en maak een API-token.

---

## Stap 3 — API-token invullen

Open:

```bash
nano group_vars/all.yml
```

Vul je token in:

```yaml
zammad_api_token: "JOUW_ZAMMAD_API_TOKEN"
```

---

## Stap 4 — Ticket bridge installeren

```bash
ansible-playbook playbooks/02-deploy-bridge-docker.yml
```

Test:

```bash
curl http://172.16.1.71:8081/health
```

---

## Stap 5 — Testticket maken

```bash
./scripts/test-create-ticket.sh
```

Als dit werkt, zie je een nieuw ticket in Zammad.

---

## Stap 6 — SOC/SIEM koppelen via Alertmanager

```bash
ansible-playbook playbooks/03-deploy-alertmanager-integration.yml
```

Daarna wordt op de monitoringserver in `/opt/soc-siem` gezet:

```text
alertmanager/alertmanager.yml
prometheus/rules/soc-alerts.yml
docker-compose.alertmanager.override.yml
```

Start daarna op de monitoringserver:

```bash
cd /opt/soc-siem
docker compose -f docker-compose.yml -f docker-compose.alertmanager.override.yml up -d
docker compose restart prometheus
```

Open:

```text
http://172.16.1.70:9093
```

voor Alertmanager.

---

## Handige commando's

Op Zammad VM:

```bash
cd /opt/zammad-docker-compose
docker compose ps
docker compose logs -f
```

Bridge:

```bash
cd /opt/zammad-ticket-bridge
docker compose ps
docker compose logs -f
```

Monitoring:

```bash
cd /opt/soc-siem
docker compose ps
docker compose logs -f alertmanager
```
