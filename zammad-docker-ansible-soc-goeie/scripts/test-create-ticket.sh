#!/usr/bin/env bash
set -euo pipefail
curl -X POST http://172.16.1.71:8081/webhook/alertmanager \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [
      {
        "status": "firing",
        "labels": {
          "alertname": "TestNetworkAlert",
          "instance": "vm-srv-dns:9100",
          "severity": "critical"
        },
        "annotations": {
          "summary": "Test alert vanuit SOC/SIEM",
          "description": "Dit is een automatisch testticket vanuit de SOC/SIEM omgeving."
        }
      }
    ]
  }'
echo
