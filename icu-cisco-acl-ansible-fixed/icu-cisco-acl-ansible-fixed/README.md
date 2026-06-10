# ICU Cisco ACL Ansible scripts - gefixte versie

Deze versie lost de eerdere fouten op:

- `net_gasten is undefined`: variabelen staan nu ook in `inventory/group_vars/all.yml`.
- `path specified in src not found`: de rendered map wordt eerst aangemaakt en de template wordt ook in `--check` lokaal gerenderd.
- Cisco ACL's gebruiken nu correcte wildcard masks in plaats van CIDR-notatie.

## Bestanden

- `inventory/hosts.ini` - pas hier het IP en de username van je Cisco-router/switch aan.
- `inventory/group_vars/all.yml` - IP-plan, servers en Cisco interfaces.
- `templates/cisco_acl.j2` - de ACL-configuratie.
- `playbooks/cisco_acls.yml` - het playbook.

## Vooraf checken

Controleer op de Cisco de echte interfacenamen:

```text
show ip interface brief
show running-config | section interface
```

Pas daarna in `inventory/group_vars/all.yml` deze regels aan:

```yaml
cisco_if_vlan10: "GigabitEthernet0/0/0.10"
cisco_if_vlan20: "GigabitEthernet0/0/0.20"
cisco_if_vlan30: "GigabitEthernet0/0/0.30"
cisco_if_vlan40: "GigabitEthernet0/0/0.40"
```

## Installatie

```bash
ansible-galaxy collection install -r requirements.yml
```

## Check-mode

```bash
ansible-playbook -i inventory/hosts.ini playbooks/cisco_acls.yml --check -k
```

## Gegenereerde config bekijken

Na check-mode staat de config hier:

```bash
cat rendered/cisco_acls.cfg
```

## Uitvoeren

```bash
ansible-playbook -i inventory/hosts.ini playbooks/cisco_acls.yml -k
```

## Belangrijk

Gebruik dit pas nadat je consoletoegang hebt via Proxmox of fysiek, zodat je jezelf niet buitensluit als een interface verkeerd staat.
