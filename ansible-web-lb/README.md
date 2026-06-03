# Ansible Webserver + Load Balancer Setup

Deze setup maakt:

- 1 load balancer met HAProxy
- 2 webservers met Nginx
- Geen reverse proxy op de webservers
- Health checks via `/health`
- Round-robin load balancing

## Structuur

```text
Gebruiker
   ↓
Load balancer HAProxy
   ↓
Webserver 1 Nginx
Webserver 2 Nginx
```

## Aanpassen

Pas eerst `inventory.ini` aan:

```ini
[loadbalancer]
lb1 ansible_host=JOUW_LOAD_BALANCER_IP

[webservers]
web1 ansible_host=JOUW_WEBSERVER_1_IP
web2 ansible_host=JOUW_WEBSERVER_2_IP
```

Pas daarna `group_vars/all.yml` aan:

```yaml
domain_name: jouw-domein.nl
haproxy_stats_password: jouw-sterke-wachtwoord
```

## Uitvoeren

```bash
ansible-playbook -i inventory.ini site.yml
```

## Testen

```bash
curl http://LOAD_BALANCER_IP
```

Je zou afwisselend `web1` en `web2` moeten zien.

## HAProxy stats

```text
http://LOAD_BALANCER_IP:8404/stats
```

Login staat in `group_vars/all.yml`.

## DNS

Laat je domein wijzen naar het IP-adres van de load balancer, niet naar de webservers.
