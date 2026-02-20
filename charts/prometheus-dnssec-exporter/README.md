# prometheus-dnssec-exporter

Prometheus exporter for DNSSEC signature validity and expiration.

## Installation

```bash
helm install dnssec-exporter ./charts/prometheus-dnssec-exporter -f values.yaml
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of replicas |
| image.repository | string | `"ghcr.io/fk-c-3po/prometheus-dnssec-exporter-container"` | Image repository |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.tag | string | `""` | Image tag (defaults to appVersion) |
| resolvers | string | `"8.8.8.8:53,1.1.1.1:53"` | DNS resolvers to use (comma-separated) |
| timeout | string | `"10s"` | Timeout for DNS operations |
| records | list | `[]` | DNSSEC records to monitor |
| records[].zone | string | | DNS zone to check |
| records[].record | string | | Record name (@ for apex) |
| records[].type | string | | Record type (SOA, A, AAAA, etc.) |
| serviceAccount.create | bool | `true` | Create service account |
| serviceAccount.name | string | `""` | Service account name |
| service.type | string | `"ClusterIP"` | Service type |
| service.port | int | `9204` | Service port |
| resources.limits.cpu | string | `"100m"` | CPU limit |
| resources.limits.memory | string | `"64Mi"` | Memory limit |
| resources.requests.cpu | string | `"10m"` | CPU request |
| resources.requests.memory | string | `"32Mi"` | Memory request |
| metrics.annotations.enabled | bool | `false` | Add prometheus.io/* annotations for auto-discovery |
| serviceMonitor.enabled | bool | `false` | Create ServiceMonitor for Prometheus Operator |
| serviceMonitor.interval | string | `"60s"` | Scrape interval |
| serviceMonitor.scrapeTimeout | string | `"30s"` | Scrape timeout |
| podMonitor.enabled | bool | `false` | Create PodMonitor for Prometheus Operator |
| podMonitor.interval | string | `"60s"` | Scrape interval |
| podMonitor.scrapeTimeout | string | `"30s"` | Scrape timeout |
| prometheusRule.enabled | bool | `false` | Create PrometheusRule with default alerts |
| prometheusRule.rules | list | See values.yaml | Alerting rules |

## Example

```yaml
records:
  - zone: "example.org"
    record: "@"
    type: "SOA"
  - zone: "example.com"
    record: "@"
    type: "SOA"

serviceMonitor:
  enabled: true
  interval: 60s

prometheusRule:
  enabled: true
```

## Metrics Scraping

Three options available:

1. **ServiceMonitor** (Prometheus Operator): `serviceMonitor.enabled=true`
2. **PodMonitor** (Prometheus Operator): `podMonitor.enabled=true`
3. **Annotations** (Alloy/Prometheus): `metrics.annotations.enabled=true`

For Grafana Alloy with annotation discovery, see the main [README](../../README.md).
