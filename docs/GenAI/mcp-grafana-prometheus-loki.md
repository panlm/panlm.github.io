---
title: MCP Server for Grafana
description: MCP Server for Grafana
created: 2025-04-21 14:05:47.674
last_modified: 2025-04-21
tags:
  - llm/mcp
---

# grafana-mcp-server

## create token from grafana UI

Administrator --> Users and access --> Service accounts --> Add service account --> Add service account token

![[attachments/mcp-grafana-prometheus-loki/IMG-20250603-140400.png]]

verify your token
```sh
curl -H "Authorization: Bearer glsa_xxx" https://grafana.domainname.com/api/dashboards/home
```

## build mcp server
- grafana mcp server: https://github.com/grafana/mcp-grafana
```sh
GO=$(which go)
GOBIN=${GO%/*} go install github.com/grafana/mcp-grafana/cmd/mcp-grafana@latest

```

- sample for stdio
```json
{
  "mcpServers": {
    "grafana": {
      "command": "/home/ec2-user/.local/opt/go/bin/mcp-grafana",
      "args": [],
      "env": {
        "GRAFANA_URL": "https://grafana.domainname.com",
        "GRAFANA_API_KEY": "<your service account token>"
      }
    }
  }
}
```

- sample for sse
```sh
nohup mcp-proxy --sse-host=0.0.0.0 --sse-port=${PORT} \
    --env GRAFANA_URL https://grafana.domainname.com \
    --env GRAFANA_API_KEY glsa_xxx \
    /home/ec2-user/.local/opt/go/bin/mcp-grafana 2>&1 1>/tmp/mcp-proxy-${PORT}.log &

```
- connect to sse in Cline
```json
    "grafana-mcp-server-remote": {
      "autoApprove": [
        "search_dashboards",
        "get_dashboard_by_uid",
        "query_prometheus",
        "list_datasources",
        "list_alert_rules"
      ],
      "disabled": false,
      "timeout": 60,
      "url": "http://sse-server:port/sse",
      "transportType": "sse"
    }

```



