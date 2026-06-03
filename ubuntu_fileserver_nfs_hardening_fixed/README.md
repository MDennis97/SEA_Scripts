# Ubuntu NFS fileserver hardening - fixed versie

Deze versie lost de eerdere fouten op met auditd en fail2ban.

## Wat is aangepast?

- Na package-installatie wordt systemd opnieuw geladen.
- auditd wordt alleen gestart als de service echt bestaat.
- fail2ban wordt alleen gestart als de service echt bestaat.
- NFS gebruikt systemd-service `nfs-server`, wat op Ubuntu meestal correct naar de NFS-server verwijst.
- SSH met wachtwoord blijft aan.
- Root-login via SSH blijft uit.
- NFS 2049/tcp en 2049/udp wordt toegestaan vanaf alle netwerken uit jullie IP-plan.

## Run lokaal op de fileserver

```bash
sudo apt update
sudo apt install -y ansible unzip
ansible-galaxy collection install community.general
ansible-playbook -i inventory.yml ubuntu_fileserver_nfs_hardening.yml --check --ask-become-pass
ansible-playbook -i inventory.yml ubuntu_fileserver_nfs_hardening.yml --ask-become-pass
```

## Controle na afloop

```bash
sudo ufw status numbered
sudo sshd -T | grep passwordauthentication
sudo systemctl status nfs-server
sudo systemctl status fail2ban
sudo systemctl status auditd
sudo sysctl net.ipv4.ip_forward
```
