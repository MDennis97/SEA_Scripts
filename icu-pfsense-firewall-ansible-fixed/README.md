# ICU pfSense firewall automation

Dit pakket automatiseert alleen de pfSense firewallconfiguratie. Er zitten geen Cisco ACL's in.

## Inhoud

```text
icu-pfsense-firewall-ansible-fixed/
├── ansible.cfg
├── requirements.yml
├── inventory/
│   ├── hosts.ini
│   └── group_vars/
│       └── all.yml
└── playbooks/
    └── pfsense_firewall.yml
```

## Vooraf aanpassen

Open eerst:

```bash
nano inventory/hosts.ini
nano inventory/group_vars/all.yml
```

Controleer vooral:

```yaml
pfsense_if_gasten: "VLAN10_GASTEN"
pfsense_if_observability: "VLAN20_OBSERVABILITY"
pfsense_if_werkplekken: "VLAN30_WERKPLEKKEN"
pfsense_if_security: "VLAN40_SECURITY"
pfsense_if_services: "SERVICES"
pfsense_if_wan: "WAN"
```

Deze interface-namen moeten exact overeenkomen met pfSense. Kijk in pfSense bij:

```text
Interfaces > Assignments
```

Of via shell:

```sh
ifconfig
```

## Installeren

```bash
ansible-galaxy collection install -r requirements.yml
```

## Test-run

```bash
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml --check -k
```

## Uitvoeren

```bash
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml -k
```

Gebruik eventueel `-K` als je pfSense-gebruiker sudo nodig heeft:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml -k -K
```

## Belangrijk

Zorg dat je Proxmox console-toegang tot pfSense hebt voordat je dit uitvoert. Als een interface-naam verkeerd staat, kan pfSense regels op de verkeerde interface zetten of kun je beheer verliezen.

## IP-plan

- VLAN 10 Gasten: `172.16.0.0/27`
- VLAN 20 Observability: `172.16.0.64/27`
- VLAN 30 Werkplekken: `172.16.0.96/27`
- VLAN 40 Security: `172.16.0.128/27`
- VLAN 99 Management: `172.16.0.160/27`
- Services: `172.16.1.0/24`

Servers:

- SOC/SIEM: `172.16.1.70`
- Zammad: `172.16.1.71`
- Identity 1: `172.16.1.132`
- Identity 2: `172.16.1.133`
- Identity VIP: `172.16.1.134`
