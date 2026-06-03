# Ubuntu NFS fileserver hardening

Deze zip bevat alleen de hardening voor de Ubuntu fileserver met NFS.

## Wat doet dit script?

- SSH blijft aan
- SSH met wachtwoord blijft aan
- Root-login via SSH wordt uitgezet
- UFW firewall wordt aangezet
- SSH wordt toegestaan vanaf alle netwerken uit jullie IP-plan
- NFS wordt toegestaan op 2049/tcp en 2049/udp vanaf alle netwerken uit jullie IP-plan
- Fail2Ban wordt aangezet voor SSH
- auditd wordt aangezet
- unattended security updates worden aangezet
- IPv4 forwarding wordt uitgezet, omdat deze server een fileserver is en geen router

## Run lokaal op de fileserver

```bash
sudo apt update
sudo apt install -y ansible unzip
ansible-galaxy collection install community.general
ansible-playbook -i inventory.yml ubuntu_fileserver_nfs_hardening.yml --check
ansible-playbook -i inventory.yml ubuntu_fileserver_nfs_hardening.yml
```

## Controle na afloop

```bash
sudo ufw status numbered
sudo sshd -T | grep passwordauthentication
sudo sysctl net.ipv4.ip_forward
sudo systemctl status nfs-kernel-server
sudo systemctl status fail2ban
```

Je wilt zien:

```text
passwordauthentication yes
net.ipv4.ip_forward = 0
```
