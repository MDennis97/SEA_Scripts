# ICU-01 pfSense firewall Ansible

Deze Ansible automation configureert firewallregels op het redundante pfSense firewallpaar:

- pfSense01: 10.2.66.2
- pfSense02: 10.2.66.4

Gebaseerd op de interface mapping uit de pfSense consoles:

| Segment | VLAN | pfSense interface |
|---|---:|---|
| WAN | - | wan |
| DMZ Intern | 424 | opt1 |
| Network Servers | 425 | opt2 |
| Observability | 426 | opt3 |
| Internal Access | 427 | opt4 |
| IAM | 428 | opt5 |
| DMZ Extern | 429 | opt6 |

## Installeren

```bash
ansible-galaxy collection install -r requirements.yml
```

## Testen

```bash
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml --syntax-check
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml --check -k
```

## Uitvoeren

```bash
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml -k
```

Controleer voor uitvoeren of SSH op pfSense aan staat en of de automation VM 10.2.66.2 en 10.2.66.4 kan bereiken.
