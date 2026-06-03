# Ubuntu Server 24.04 Hardening Ansible

Dit zipje bevat alleen de Ubuntu Server hardening scripts.

## Bestanden

- `inventory.yml` - voorbeeld inventory
- `ubuntu_24_hardening.yml` - hardening playbook voor Ubuntu Server 24.04 LTS

## Benodigde collection

```bash
ansible-galaxy collection install community.general
```

## Uitvoeren

Pas eerst in `inventory.yml` het IP-adres en de SSH-gebruiker aan.

Pas daarna in `ubuntu_24_hardening.yml` minimaal dit aan:

```yaml
allowed_ssh_network: "192.168.1.0/24"
```

Test eerst:

```bash
ansible-playbook -i inventory.yml ubuntu_24_hardening.yml --check
```

Voer daarna uit:

```bash
ansible-playbook -i inventory.yml ubuntu_24_hardening.yml
```

Let op: het playbook zet `PasswordAuthentication no`. Zorg dat SSH keys werken voordat je dit uitvoert, anders kun je jezelf buitensluiten.
