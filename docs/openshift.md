# OpenShift Deployment Guide

Deploy prometheus-dnssec-exporter on OpenShift using the Helm chart.

## Prerequisites

- OpenShift 4.x cluster
- `helm` CLI installed
- `oc` CLI configured

## Installation

### Add the Helm repository

```bash
helm repo add prometheus-dnssec-exporter https://fk-c-3po.github.io/prometheus-dnssec-exporter-container
helm repo update
```

### Install the chart

```bash
helm install dnssec-exporter prometheus-dnssec-exporter/prometheus-dnssec-exporter \
  --namespace dnssec-monitoring \
  --create-namespace
```

## Configuration

Create a `values.yaml` file to customize your deployment:

```yaml
records:
  - zone: "example.org"
    record: "@"
    type: "SOA"
  - zone: "example.com"
    record: "@"
    type: "SOA"

resolvers: "8.8.8.8:53,1.1.1.1:53"

serviceMonitor:
  enabled: true
  interval: 60s

prometheusRule:
  enabled: true
```

Install with custom values:

```bash
helm install dnssec-exporter prometheus-dnssec-exporter/prometheus-dnssec-exporter \
  --namespace dnssec-monitoring \
  --create-namespace \
  -f values.yaml
```

## Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `records` | List of DNSSEC records to monitor | `[{zone: "example.org", record: "@", type: "SOA"}]` |
| `resolvers` | DNS resolvers (comma-separated) | `"8.8.8.8:53,1.1.1.1:53"` |
| `serviceMonitor.enabled` | Enable ServiceMonitor for Prometheus Operator | `false` |
| `podMonitor.enabled` | Enable PodMonitor (alternative to ServiceMonitor) | `false` |
| `prometheusRule.enabled` | Enable alerting rules | `false` |
| `metrics.annotations.enabled` | Enable prometheus.io annotations for auto-discovery | `false` |

## Upgrading

```bash
helm upgrade dnssec-exporter prometheus-dnssec-exporter/prometheus-dnssec-exporter \
  --namespace dnssec-monitoring \
  -f values.yaml
```

## Uninstalling

```bash
helm uninstall dnssec-exporter --namespace dnssec-monitoring
```

## Verify Deployment

```bash
oc get pods -n dnssec-monitoring -l app.kubernetes.io/name=prometheus-dnssec-exporter
oc logs -n dnssec-monitoring -l app.kubernetes.io/name=prometheus-dnssec-exporter
```
