# Zammad + SOC/SIEM one-big Ansible deployment

Deze bundel bevat **één groot playbook** dat alles achter elkaar uitvoert:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy-complete.yml
```

Het doet automatisch:

1. Oude handmatige Zammad/Elasticsearch installatie verwijderen op de ticketing-VM.
2. Docker installeren op de ticketing-VM.
3. Zammad via Docker Compose installeren op `172.16.1.71:8080`.
4. Ticket bridge als Docker container installeren op `172.16.1.71:8081`.
5. Alertmanager + Prometheus alert rules koppelen op de monitoringserver `172.16.1.70`.

## Gebruik

Pak uit op de ticketing-VM:

```bash
unzip zammad-ansible-onebig.zip
cd zammad-ansible-onebig
ansible-galaxy collection install -r requirements.yml
./run_all.sh
```

Of direct:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy-complete.yml
```

## Belangrijke URLs

```text
Zammad:       http://172.16.1.71:8080
Bridge:       http://172.16.1.71:8081/health
Alertmanager: http://172.16.1.70:9093
```

## Let op over API-token

In `group_vars/all.yml` staat:

```yaml
zammad_api_token: "GuvenKip025!"
```

Dit moet eigenlijk een echte Zammad API-token zijn. Als dit alleen je wachtwoord is, dan start de bridge wel, maar tickets maken via de Zammad API kan falen. Maak dan na de eerste Zammad setup een token in Zammad en pas `group_vars/all.yml` aan. Daarna draai je gewoon opnieuw:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy-complete.yml
```

Het playbook is idempotent genoeg om opnieuw te draaien.
