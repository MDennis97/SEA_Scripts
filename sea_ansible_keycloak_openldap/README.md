# SEA-project: Ansible Keycloak + OpenLDAP + Virtual IP + SSO + MFA

Dit project rolt een simpele redundante identity-opstelling uit voor een schoolproject/lab.

De setup gebruikt:

- 2 Ubuntu Server VM's
- Docker Compose
- Keycloak container op beide nodes
- OpenLDAP container op beide nodes
- dezelfde LDAP-testgebruikers op beide nodes
- Keycloak realm `school`
- LDAP user federation naar de lokale OpenLDAP-container
- keepalived met een virtual IP voor automatische failover
- SSO via OpenID Connect voor Grafana
- MFA/OTP via Keycloak required action `CONFIGURE_TOTP`

Dit is bewust **geen productie-HA**. Er is geen PostgreSQL, geen HAProxy en geen live OpenLDAP-replicatie. De opzet is bedoeld om redundantie, SSO en MFA begrijpelijk te demonstreren.

## Architectuur

```text
Applicatie / Grafana
        |
        v
auth.school.local / 192.168.56.100  <-- virtual IP
        |
        v
server1 of server2
        |
        v
Keycloak container + lokale OpenLDAP container
```

Voorbeeld-IP's:

```text
server1:     192.168.56.11
server2:     192.168.56.12
virtual IP:  192.168.56.100
hostname:    auth.school.local
```

Applicaties zoals Grafana verwijzen niet naar `server1` of `server2`, maar naar:

```text
http://auth.school.local:8080/realms/school
```

## Redundantie-uitleg

- Op beide servers draait Keycloak.
- Op beide servers draait OpenLDAP.
- Ansible rolt dezelfde configuratie en dezelfde basisgebruikers uit.
- keepalived geeft het virtual IP aan de actieve server.
- Als de actieve server of Keycloak daarop uitvalt, neemt de tweede server het virtual IP over.
- Applicaties blijven hetzelfde adres gebruiken.

Belangrijke beperking:

- Keycloak-data wordt niet automatisch gedeeld, omdat er geen PostgreSQL is.
- OpenLDAP-data wordt niet live gerepliceerd.
- Wijzigingen moeten via Ansible/configuratie opnieuw naar beide nodes uitgerold worden.

## 1. Vereisten

Op je Ansible-controller:

```bash
sudo apt update
sudo apt install -y ansible sshpass
```

Op de doel-VM's:

- Ubuntu/Debian
- SSH-toegang
- gebruiker met sudo-rechten
- beide VM's in hetzelfde netwerk/subnet
- een vrij IP-adres voor het virtual IP

## 2. Inventory aanpassen

Open:

```bash
inventory/hosts.ini
```

Pas de IP-adressen en SSH-gebruiker aan:

```ini
[identity]
server1 ansible_host=192.168.56.11 ansible_user=student node_name=server1 keepalived_state=MASTER keepalived_priority=150
server2 ansible_host=192.168.56.12 ansible_user=student node_name=server2 keepalived_state=BACKUP keepalived_priority=100
```

## 3. Netwerkinterface controleren

Op beide servers:

```bash
ip a
```

Zoek de interface waarop je VM-IP staat, bijvoorbeeld:

```text
enp0s3
ens33
enp0s8
eth0
```

Open daarna:

```bash
group_vars/all.yml
```

Pas aan:

```yaml
keepalived_interface: enp0s3
```

## 4. Virtual IP en hostnames instellen

In `group_vars/all.yml` staan standaard:

```yaml
keepalived_virtual_ip: 192.168.56.100
keycloak_hostname: auth.school.local
grafana_hostname: grafana.school.local
```

Zet op je client/Grafana-machine in `/etc/hosts`:

```text
192.168.56.100 auth.school.local
192.168.56.50  grafana.school.local
```

Gebruik voor `grafana.school.local` het IP van jouw Grafana-machine. Als je Grafana lokaal draait, mag dit ook `127.0.0.1` zijn of laat je de standaard localhost redirect staan.

## 5. Uitrollen

Met wachtwoord-login:

```bash
ansible-playbook site.yml -k -K
```

Met SSH-key:

```bash
ansible-playbook site.yml -K
```

Syntaxcheck:

```bash
ansible-playbook site.yml --syntax-check
```

## 6. Testgebruikers

Deze LDAP-gebruikers worden op beide nodes aangemaakt:

```text
testuser / Password123!
student  / Student123!
```

Door MFA moeten gebruikers bij de eerste login een authenticator-app koppelen, bijvoorbeeld:

- Microsoft Authenticator
- Google Authenticator
- Bitwarden Authenticator
- 1Password

## 7. Keycloak openen

Gebruik bij voorkeur de vaste hostname:

```text
http://auth.school.local:8080
```

Admin console:

```text
http://auth.school.local:8080/admin
```

Admin-login:

```text
admin / ChangeMeKeycloak123!
```

Realm:

```text
school
```

## 8. SSO-configuratie voor Grafana

De Ansible-role maakt automatisch een Keycloak-client aan:

```text
client_id:     grafana
client_secret: ChangeMeGrafanaSecret123!
```

Issuer URL:

```text
http://auth.school.local:8080/realms/school
```

Grafana `grafana.ini` voorbeeld:

```ini
[server]
root_url = http://grafana.school.local:3000

[auth.generic_oauth]
enabled = true
name = Keycloak
allow_sign_up = true
client_id = grafana
client_secret = ChangeMeGrafanaSecret123!
scopes = openid email profile
auth_url = http://auth.school.local:8080/realms/school/protocol/openid-connect/auth
token_url = http://auth.school.local:8080/realms/school/protocol/openid-connect/token
api_url = http://auth.school.local:8080/realms/school/protocol/openid-connect/userinfo
role_attribute_path = contains(groups[*], 'admin') && 'Admin' || 'Viewer'
```

Bij login klik je in Grafana op `Sign in with Keycloak`. Je wordt doorgestuurd naar Keycloak. Na login vraagt Keycloak om MFA/OTP te configureren. Daarna kom je terug in Grafana.

## 9. MFA controleren

MFA wordt ingesteld via Keycloak required action:

```text
CONFIGURE_TOTP enabled=true defaultAction=true
```

Dit betekent:

- gebruikers moeten bij eerste login een OTP-app koppelen;
- daarna is naast wachtwoord ook een OTP-code nodig;
- dit werkt voor de LDAP-gebruikers zodra Keycloak ze importeert bij login.

Controleren in Keycloak:

```text
Realm school
Authentication
Required actions
Configure OTP
```

`Configure OTP` moet aan staan en als default action ingesteld zijn.

## 10. Failover testen

Check waar het virtual IP actief is:

```bash
ip a | grep 192.168.56.100
```

Stop Keycloak op server1:

```bash
docker stop keycloak
```

Wacht een paar seconden. Check daarna op server2:

```bash
ip a | grep 192.168.56.100
```

Als server2 het virtual IP heeft, werkt deze URL nog steeds:

```text
http://auth.school.local:8080
```

Voor applicaties zoals Grafana verandert er niets, want die gebruiken hetzelfde vaste adres.

## 11. Handige commando's

Containers bekijken:

```bash
docker ps
```

Logs Keycloak:

```bash
docker logs -f keycloak
```

Logs OpenLDAP:

```bash
docker logs -f openldap
```

Keepalived status:

```bash
sudo systemctl status keepalived
```

Virtual IP controleren:

```bash
ip a | grep 192.168.56.100
```

## 12. Verslagtekst

Je kunt dit gebruiken in je SEA-verslag:

> Voor het SEA-project is een redundante identity-opstelling gerealiseerd met Ansible. Beide Ubuntu Server-nodes draaien een Keycloak-container en een OpenLDAP-container. De configuratie wordt volledig door Ansible uitgerold, waardoor beide nodes dezelfde realm-, LDAP- en SSO-configuratie krijgen. Applicaties gebruiken niet direct een node-adres, maar verbinden met `auth.school.local`, dat verwijst naar een virtual IP. Dit virtual IP wordt beheerd door keepalived. Wanneer de actieve node of de Keycloak-service uitvalt, neemt de tweede node het virtual IP over. Hierdoor kunnen applicaties zoals Grafana hetzelfde SSO-adres blijven gebruiken.

> SSO is ingericht met OpenID Connect. In Keycloak wordt automatisch een client voor Grafana aangemaakt. Grafana gebruikt de Keycloak issuer URL van de realm `school` om gebruikers via Keycloak te laten inloggen. De gebruikers komen uit OpenLDAP via Keycloak User Federation. MFA is geconfigureerd via de Keycloak required action `CONFIGURE_TOTP`, waardoor gebruikers bij hun eerste login een authenticator-app moeten koppelen. Daarna is naast het wachtwoord ook een OTP-code nodig.

> De omgeving is bewust beperkt gehouden voor een schoolproject. Er is geen PostgreSQL-cluster, HAProxy of live LDAP-replicatie gebruikt. Daarom is dit geen productie-HA, maar een eenvoudige redundante labopstelling waarmee automatische failover, SSO en MFA aantoonbaar zijn.
