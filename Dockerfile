# Build Stage
FROM golang:1.22-alpine AS builder

WORKDIR /src

RUN apk add --no-cache git ca-certificates tzdata

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build both saturn-server and saturn-client
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /bin/saturn-server ./cmd/saturn-server
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /bin/saturn-client ./cmd/saturn-client

# Runtime Stage
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata iptables iproute2

WORKDIR /app

COPY --from=builder /bin/saturn-server /usr/local/bin/saturn-server
COPY --from=builder /bin/saturn-client /usr/local/bin/saturn-client

EXPOSE 443 10808

ENTRYPOINT ["saturn-server"]
CMD ["-c", "/etc/saturn/config.json"]
