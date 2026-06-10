# ICU firewall Ansible scripts

Deze Ansible-map configureert pfSense firewallregels en optioneel Cisco ACL's op basis van het TO/IP-plan.

## Vooraf aanpassen

Pas eerst deze bestanden aan:

- `inventory/hosts.ini`: IP-adressen en gebruikers van pfSense en Cisco.
- `group_vars/all.yml`: DNS-server, interface-namen van pfSense en Cisco.

Let op: pfSense interface names moeten exact overeenkomen met wat pfSense ziet. Controleer dit in pfSense bij **Interfaces > Assignments**.

## Installatie collections

```bash
ansible-galaxy collection install -r requirements.yml
```

## Alleen pfSense uitvoeren

```bash
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml -k -K
```

## Alleen Cisco ACL's uitvoeren

```bash
ansible-playbook -i inventory/hosts.ini playbooks/cisco_acls.yml -k
```

## Alles uitvoeren

```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -k -K
```

## Eerst checken zonder wijzigingen

```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check -k -K
```

## Belangrijke waarschuwing

Voer dit niet blind uit op een productieve firewall. Test eerst via console-toegang, want verkeerde interface-namen of verkeerde IP's kunnen toegang blokkeren.
