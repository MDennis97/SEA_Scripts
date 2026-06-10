# ICU-01 pfSense firewall Ansible final fixed

Deze versie is gefixt voor:

1. Beide pfSense routers:
   - pfsense01: 10.2.66.2
   - pfsense02: 10.2.66.4
2. Python-pad op pfSense:
   - /usr/local/bin/python3.8
3. pfSense poortnotatie:
   - geen comma-separated poorten meer direct in firewallregels
   - poortgroepen worden eerst als pfSense port aliases aangemaakt

## Gebruik

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml --syntax-check
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml --check -k
ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml -k
```

Als host key checking moeilijk doet:

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml --check -k
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/hosts.ini playbooks/pfsense_firewall.yml -k
```
