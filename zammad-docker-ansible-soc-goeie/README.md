# Zammad Docker + SOC/SIEM koppeling met Ansible

Deze versie bevat direct de echte bestanden:

```text
inventory/hosts.ini
group_vars/all.yml
```

Er staan dus geen `.example`-bestanden meer in.

## Belangrijke gegevens

```text
Ticketing VM: 172.16.1.71
Monitoring/SOC VM: 172.16.1.70
Zammad URL: http://172.16.1.71:8080
Ticket bridge: http://172.16.1.71:8081
Alertmanager: http://172.16.1.70:9093
```

De API-token staat ingevuld in `group_vars/all.yml`. Behandel deze token als een wachtwoord.

## Stappen

```bash
unzip zammad-docker-ansible-soc-final.zip
cd zammad-docker-ansible-soc-final
ansible-galaxy collection install -r requirements.yml
ansible-inventory --list
```

Oude installatie verwijderen:

```bash
ansible-playbook playbooks/00-clean-ticketing.yml
```

Zammad via Docker installeren:

```bash
ansible-playbook playbooks/01-deploy-zammad-docker.yml
```

Open daarna:

```text
http://172.16.1.71:8080
```

Ticket bridge installeren:

```bash
ansible-playbook playbooks/02-deploy-bridge-docker.yml
curl http://172.16.1.71:8081/health
```

Testticket maken:

```bash
./scripts/test-create-ticket.sh
```

SOC/SIEM koppelen:

```bash
ssh icu01@172.16.1.70
ansible-playbook playbooks/03-deploy-alertmanager-integration.yml
```

Flow:

```text
Prometheus alert
      ↓
Alertmanager
      ↓
zammad-ticket-bridge
      ↓
Zammad API
      ↓
Automatisch ticket
```
