# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

```bash
# Build
go build -v .

# Run tests
go test -v .

# Get dependencies
go get -v -t -d ./...

# Run the exporter
./prometheus-dnssec-exporter -config config.sample
```

## Container Build

```bash
# Build container locally
docker build -t prometheus-dnssec-exporter .

# Run container
docker run -v $(pwd)/config.sample:/etc/dnssec-checks/config:ro -p 9204:9204 prometheus-dnssec-exporter

# Check metrics
curl localhost:9204/metrics
```

## Architecture

This is a Prometheus exporter that monitors DNSSEC signature validity and expiration. It's a single-file Go application (`main.go`) with the following structure:

**Exporter struct** - Implements `prometheus.Collector` interface with three gauge metrics:
- `dnssec_zone_record_days_left` - Days until signature expiration (from first resolver only)
- `dnssec_zone_record_resolves` - Whether record resolves and validates (1 or 0)
- `dnssec_zone_record_earliest_rrsig_expiry` - Unix timestamp of earliest RRSIG expiration

**Configuration** - TOML format, defines records to monitor:
```toml
[[records]]
  zone = "example.org"
  record = "@"
  type = "SOA"
```

**Key behaviors**:
- Uses TCP for DNS queries with EDNS0 enabled (DO flag)
- Validates both `AuthenticatedData` flag and `RcodeSuccess`
- Queries all configured resolvers concurrently
- When multiple RRSIGs cover a record, reports the earliest expiration

## Release Process

1. Ensure all changes are committed to master
2. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push --tags
   ```
3. The release workflow automatically:
   - Builds multi-arch container images (linux/amd64, linux/arm64)
   - Pushes to ghcr.io/fk-c-3po/prometheus-dnssec-exporter-container
   - Creates GitHub Release with binaries via goreleaser

## CI/CD Workflows

- **ci.yml**: Runs on push/PR to master - builds, tests, lints
- **release.yml**: Runs on version tags (v*) - builds container and creates release

## Goreleaser

Test goreleaser configuration locally:
```bash
# Validate config
goreleaser check

# Build snapshot (no publish)
goreleaser build --snapshot --clean
```

## Dependency Updates

```bash
go get -u ./...
go mod tidy
```
