# DNSSEC Exporter for Prometheus

Check for validity and expiration in DNSSEC signatures and expose metrics for Prometheus

## Installation

### Binary

Download the latest release from [GitHub Releases](https://github.com/fk-c-3po/prometheus-dnssec-exporter-container/releases).

### From Source

```bash
go install github.com/chrj/prometheus-dnssec-exporter@latest
```

### Container

```bash
# Docker
docker run -v /path/to/config:/etc/dnssec-checks:ro -p 9204:9204 \
  ghcr.io/fk-c-3po/prometheus-dnssec-exporter-container:latest

# Podman
podman run -v /path/to/config:/etc/dnssec-checks:ro -p 9204:9204 \
  ghcr.io/fk-c-3po/prometheus-dnssec-exporter-container:latest
```

## Usage

```
Usage of prometheus-dnssec-exporter:
  -config string
      Configuration file (default "/etc/dnssec-checks")
  -listen-address string
      Prometheus metrics port (default ":9204")
  -resolvers string
      Resolvers to use (comma separated) (default "8.8.8.8:53,1.1.1.1:53")
  -timeout duration
      Timeout for network operations (default 10s)
```

## Container Usage

The container image expects:
- Config file mounted at `/etc/dnssec-checks/config`
- Port 9204 exposed for metrics

```bash
# With custom resolvers
docker run -v $(pwd)/config.sample:/etc/dnssec-checks/config:ro -p 9204:9204 \
  ghcr.io/fk-c-3po/prometheus-dnssec-exporter-container:latest \
  -resolvers "8.8.8.8:53,1.1.1.1:53"
```

## Kubernetes/OpenShift Deployment

### Helm Chart

```bash
helm install dnssec-exporter ./charts/prometheus-dnssec-exporter -f my-values.yaml
```

Example `my-values.yaml`:

```yaml
records:
  - zone: "example.org"
    record: "@"
    type: "SOA"
  - zone: "example.com"
    record: "@"
    type: "SOA"

resolvers: "8.8.8.8:53,1.1.1.1:53"
```

### Metrics Scraping Options

The chart supports multiple ways to expose metrics for scraping:

| Value | Use with |
|-------|----------|
| `serviceMonitor.enabled=true` | Prometheus Operator (via Service) |
| `podMonitor.enabled=true` | Prometheus Operator (direct to pod) |
| `metrics.annotations.enabled=true` | Alloy / Prometheus with annotation discovery |

**Prometheus Operator:**

```yaml
serviceMonitor:
  enabled: true
  interval: 60s

prometheusRule:
  enabled: true  # includes default DNSSEC alerts
```

**Grafana Alloy** (annotation-based discovery):

```yaml
metrics:
  annotations:
    enabled: true
```

Then configure Alloy to discover pods with `prometheus.io/*` annotations:

```alloy
discovery.kubernetes "pods" {
  role = "pod"
}

discovery.relabel "annotated_pods" {
  targets = discovery.kubernetes.pods.targets

  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
    regex         = "true"
    action        = "keep"
  }
  rule {
    source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
    regex         = "([^:]+)(?::\\d+)?;(\\d+)"
    replacement   = "$1:$2"
    target_label  = "__address__"
  }
}

prometheus.scrape "pods" {
  targets    = discovery.relabel.annotated_pods.output
  forward_to = [prometheus.remote_write.default.receiver]
}
```

Alternatively, if you have Prometheus Operator CRDs installed, Alloy can discover ServiceMonitors directly:

```alloy
prometheus.operator.servicemonitors "default" {
  forward_to = [prometheus.remote_write.default.receiver]
}
```

### Raw Manifests

See [OpenShift Deployment Guide](docs/openshift.md) for raw manifest examples including:
- ConfigMap for configuration
- Deployment manifests
- ServiceMonitor for Prometheus Operator
- SecurityContextConstraints considerations

## Metrics

### Gauge: `dnssec_zone_record_days_left`

Number of days the signature will be valid.

Labels:

* `zone`
* `record`
* `type`

If more than one resolver is configured, the metric will be calculated from the
resolver that is configured first.  If more than one RRSIG covers the record,
the number of days until the first one expires will be returned.  If the record
is not signed of the signature cannot be validated, this metric will contain a
bogus timestamp.

### Gauge: `dnssec_zone_record_earliest_rrsig_expiry`

Earliest expiring RRSIG covering the record on resolver in unixtime.

Labels:

* `resolver`
* `zone`
* `record`
* `type`

If more than one RRSIG covers the record, the expiration time returned will be
of the one that expires earliest.  If the record does not resolve or cannot be
validated, this metric will be absent.

### Gauge: `dnssec_zone_record_resolves`

Does the record resolve using the specified DNSSEC enabled resolvers.

Labels:

* `resolver`
* `zone`
* `record`
* `type`

This metric will return 1 only if the record resolves **and** validates.

### Examples

```
# HELP dnssec_zone_record_days_left Number of days the signature will be valid
# TYPE dnssec_zone_record_days_left gauge
dnssec_zone_record_days_left{record="@",type="SOA",zone="ietf.org"} 320.3333333333333
dnssec_zone_record_days_left{record="@",type="SOA",zone="verisigninc.com"} 9.333333333333334
# HELP dnssec_zone_record_resolves Does the record resolve using the specified DNSSEC enabled resolvers
# TYPE dnssec_zone_record_resolves gauge
dnssec_zone_record_resolves{record="@",resolver="1.1.1.1:53",type="SOA",zone="ietf.org"} 1
dnssec_zone_record_resolves{record="@",resolver="1.1.1.1:53",type="SOA",zone="verisigninc.com"} 1
dnssec_zone_record_resolves{record="@",resolver="8.8.8.8:53",type="SOA",zone="ietf.org"} 1
dnssec_zone_record_resolves{record="@",resolver="8.8.8.8:53",type="SOA",zone="verisigninc.com"} 1
# HELP dnssec_zone_record_earliest_rrsig_expiry Earliest expiring RRSIG covering the record on resolver in unixtime
# TYPE dnssec_zone_record_earliest_rrsig_expiry gauge
dnssec_zone_record_earliest_rrsig_expiry{record="@",resolver="1.1.1.1:53",type="SOA",zone="ietf.org"} 1.664872679e+09
dnssec_zone_record_earliest_rrsig_expiry{record="@",resolver="1.1.1.1:53",type="SOA",zone="verisigninc.com"} 1.664778306e+09
dnssec_zone_record_earliest_rrsig_expiry{record="@",resolver="8.8.8.8:53",type="SOA",zone="ietf.org"} 1.664872679e+09
dnssec_zone_record_earliest_rrsig_expiry{record="@",resolver="8.8.8.8:53",type="SOA",zone="verisigninc.com"} 1.664778306e+09
```

## Configuration

Supply a configuration file path with `-config` (optionally, defaults to `/etc/dnssec-checks`). Uses [TOML](https://github.com/toml-lang/toml).

[Sample configuration file](config.sample)

## Prometheus target

Supply a listen address with `-addr` (optionally, defaults to `:9204`), and configure a Prometheus job:

```yaml
- job_name: "dnssec"
  scrape_interval: "1m"
  static_configs:
    - targets:
        - "server:9204"
```

## Prometheus alert

The real benefit is getting an alert triggered when a signature is nearing expiration or is not longer valid. Check this [sample alert definition](dnssec.rules).

## Releases

Releases are automated via GitHub Actions:

1. Tag a new version: `git tag v1.0.0 && git push --tags`
2. The release workflow builds:
   - Multi-platform binaries (linux/amd64, linux/arm64, darwin/amd64, darwin/arm64, windows/amd64)
   - Multi-arch container images (linux/amd64, linux/arm64)
3. Artifacts are published to GitHub Releases and ghcr.io
