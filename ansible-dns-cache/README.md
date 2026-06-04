# Ansible DNS Caching Server - ICU-01

Deze Ansible-structuur installeert en configureert een Ubuntu DNS caching server met Unbound.

## Structuur

```text
ansible-dns-cache/
├── ansible.cfg
├── inventory/
│   └── hosts.ini
├── group_vars/
│   └── dns_cache.yml
├── site.yml
├── roles/
│   └── dns_cache/
│       ├── defaults/
│       │   └── main.yml
│       ├── handlers/
│       │   └── main.yml
│       ├── tasks/
│       │   └── main.yml
│       └── templates/
│           └── cache.conf.j2
└── docs/
    └── test-commands.md
```

## Aanpassen voor jouw omgeving

Open:

```bash
inventory/hosts.ini
```

Pas dit IP aan naar het echte IP-adres van je Ubuntu DNS cache server:

```ini
dns-cache-01 ansible_host=172.16.1.44 ansible_user=icu01
```

Open daarna:

```bash
group_vars/dns_cache.yml
```

Belangrijkste waarden:

```yaml
dns_allowed_networks:
  - "172.16.0.0/23"
```

Dit staat toe dat jullie interne SEA-netwerken 172.16.0.x en 172.16.1.x de DNS cache gebruiken.

Interne DNS forwarding:

```yaml
internal_dns_zones:
  - name: "icu-01.local."
    forwarders:
      - "172.16.1.34"
      - "172.16.1.35"
```

Pas `icu-01.local.` aan naar jullie echte interne domein.

## Uitvoeren

Vanaf je Ansible control machine:

```bash
ansible-playbook site.yml
```

## Testen

```bash
dig google.com @172.16.1.44
nslookup google.com 172.16.1.44
```

## Let op

De DNS cache server moet een vast IP-adres krijgen. Zet dit IP daarna als DNS-server bij je DHCP-scope of handmatig op clients.
