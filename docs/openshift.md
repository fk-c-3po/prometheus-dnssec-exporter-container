# OpenShift Deployment Guide

This guide covers deploying prometheus-dnssec-exporter on OpenShift.

## Prerequisites

- OpenShift 4.x cluster
- `oc` CLI configured
- Prometheus Operator installed (for ServiceMonitor)

## Deployment

### 1. Create ConfigMap for DNSSEC checks

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dnssec-exporter-config
data:
  config: |
    [[records]]
      zone = "example.org"
      record = "@"
      type = "SOA"

    [[records]]
      zone = "example.com"
      record = "@"
      type = "SOA"
```

### 2. Create Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dnssec-exporter
  labels:
    app: dnssec-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dnssec-exporter
  template:
    metadata:
      labels:
        app: dnssec-exporter
    spec:
      containers:
        - name: dnssec-exporter
          image: ghcr.io/fk-c-3po/prometheus-dnssec-exporter-container:latest
          ports:
            - containerPort: 9204
              name: metrics
          args:
            - "-config"
            - "/etc/dnssec-checks/config"
            - "-resolvers"
            - "8.8.8.8:53,1.1.1.1:53"
          volumeMounts:
            - name: config
              mountPath: /etc/dnssec-checks
              readOnly: true
          resources:
            requests:
              memory: "32Mi"
              cpu: "10m"
            limits:
              memory: "64Mi"
              cpu: "100m"
          livenessProbe:
            httpGet:
              path: /metrics
              port: 9204
            initialDelaySeconds: 5
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /metrics
              port: 9204
            initialDelaySeconds: 5
            periodSeconds: 10
      volumes:
        - name: config
          configMap:
            name: dnssec-exporter-config
```

### 3. Create Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: dnssec-exporter
  labels:
    app: dnssec-exporter
spec:
  selector:
    app: dnssec-exporter
  ports:
    - port: 9204
      targetPort: 9204
      name: metrics
```

### 4. Create ServiceMonitor (for Prometheus Operator)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: dnssec-exporter
  labels:
    app: dnssec-exporter
spec:
  selector:
    matchLabels:
      app: dnssec-exporter
  endpoints:
    - port: metrics
      interval: 60s
      scrapeTimeout: 30s
```

## SecurityContextConstraints

The container image is built to run as non-root (UID 1000) and is compatible with OpenShift's restricted SCC. No special SCC is required.

If you need to run with a specific SCC:

```bash
oc adm policy add-scc-to-user restricted -z default -n <namespace>
```

## Quick Deploy

Apply all manifests at once:

```bash
# Create namespace
oc new-project dnssec-monitoring

# Apply manifests
oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: dnssec-exporter-config
data:
  config: |
    [[records]]
      zone = "example.org"
      record = "@"
      type = "SOA"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dnssec-exporter
  labels:
    app: dnssec-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dnssec-exporter
  template:
    metadata:
      labels:
        app: dnssec-exporter
    spec:
      containers:
        - name: dnssec-exporter
          image: ghcr.io/fk-c-3po/prometheus-dnssec-exporter-container:latest
          ports:
            - containerPort: 9204
              name: metrics
          volumeMounts:
            - name: config
              mountPath: /etc/dnssec-checks
              readOnly: true
          resources:
            requests:
              memory: "32Mi"
              cpu: "10m"
            limits:
              memory: "64Mi"
              cpu: "100m"
      volumes:
        - name: config
          configMap:
            name: dnssec-exporter-config
---
apiVersion: v1
kind: Service
metadata:
  name: dnssec-exporter
  labels:
    app: dnssec-exporter
spec:
  selector:
    app: dnssec-exporter
  ports:
    - port: 9204
      targetPort: 9204
      name: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: dnssec-exporter
  labels:
    app: dnssec-exporter
spec:
  selector:
    matchLabels:
      app: dnssec-exporter
  endpoints:
    - port: metrics
      interval: 60s
EOF
```

## Verify Deployment

```bash
# Check pod status
oc get pods -l app=dnssec-exporter

# Check metrics endpoint
oc port-forward svc/dnssec-exporter 9204:9204 &
curl localhost:9204/metrics

# Check logs
oc logs -l app=dnssec-exporter
```

## Troubleshooting

### Pod CrashLoopBackOff

Check if the config file is properly mounted:

```bash
oc exec -it deploy/dnssec-exporter -- cat /etc/dnssec-checks/config
```

### DNS Resolution Issues

The container needs to reach DNS resolvers. If using internal resolvers:

```yaml
args:
  - "-resolvers"
  - "10.0.0.10:53"  # Internal DNS server
```

### Metrics Not Showing

Verify ServiceMonitor is being picked up by Prometheus:

```bash
oc get servicemonitor dnssec-exporter -o yaml
```

Check Prometheus targets in the Prometheus UI.
