# Ubuntu Bastion SSH-only hardening

Run lokaal op de bastion server:

```bash
sudo apt update
sudo apt install -y ansible unzip
ansible-galaxy collection install community.general
ansible-playbook -i inventory.yml ubuntu_bastion_ssh_only_hardening.yml --check --ask-become-pass
ansible-playbook -i inventory.yml ubuntu_bastion_ssh_only_hardening.yml --ask-become-pass
```

Controle:

```bash
sudo ufw status numbered
sudo sshd -T | grep passwordauthentication
sudo sshd -T | grep permitrootlogin
sudo sysctl net.ipv4.ip_forward
```
