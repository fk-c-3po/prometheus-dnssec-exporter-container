# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o prometheus-dnssec-exporter .

# Runtime stage - scratch for minimal image
FROM scratch

# Copy CA certs for HTTPS (DNS over TCP doesn't need this, but good practice)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /build/prometheus-dnssec-exporter /prometheus-dnssec-exporter

EXPOSE 9204

USER 65534

ENTRYPOINT ["/prometheus-dnssec-exporter"]
CMD ["-config", "/etc/dnssec-checks/config"]
