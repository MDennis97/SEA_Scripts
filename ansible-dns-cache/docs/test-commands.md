# Testcommando's

Test lokaal op de DNS caching server:

```bash
dig google.com @127.0.0.1
```

Test vanaf een client:

```bash
nslookup google.com 172.16.1.44
```

Test interne DNS-zone:

```bash
nslookup servernaam.icu-01.local 172.16.1.44
```

Controleer service:

```bash
sudo systemctl status unbound
sudo unbound-checkconf
```
