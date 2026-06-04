# Zammad One-Click Installer

Dit is één script dat je op de **ticketing VM `172.16.1.71`** draait.

Het kan:

1. Oude handmatige Zammad/Elasticsearch installatie verwijderen.
2. Docker installeren.
3. Zammad via Docker Compose installeren.
4. Ticket bridge als Docker container installeren.
5. SOC/SIEM koppelen via Alertmanager op `172.16.1.70`.

## Gebruik

```bash
chmod +x install_zammad_soc.sh
./install_zammad_soc.sh
```

Kies in het menu eerst optie:

```text
1) Alles automatisch: cleanup + Docker + Zammad + bridge
```

Daarna open je:

```text
http://172.16.1.71:8080
```

Maak Zammad setup af.

Daarna draai je opnieuw:

```bash
./install_zammad_soc.sh
```

Kies:

```text
4) Alleen ticket bridge installeren/starten
6) Testticket maken
7) SOC/SIEM koppelen via Alertmanager op monitoringserver
```

## Ingevulde waarden

```text
Ticketing VM: 172.16.1.71
Monitoring VM: 172.16.1.70
Zammad poort: 8080
Bridge poort: 8081
Alertmanager poort: 9093
API-token: GuvenKip025!
```

Let op: `GuvenKip025!` moet eigenlijk een echte Zammad API-token zijn. Als dit geen token is, maakt de bridge geen tickets aan. Maak dan in Zammad een token aan en vervang bovenin het script:

```bash
ZAMMAD_API_TOKEN="GuvenKip025!"
```

door je echte token.

## Direct alles uitvoeren

Kan ook met:

```bash
./install_zammad_soc.sh --all
```

Maar handiger is het menu, omdat je Zammad setup tussendoor eerst in de browser moet afmaken.
