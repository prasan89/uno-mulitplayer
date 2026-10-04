# ---- Build Stage ----
FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server ./cmd/server

# ---- Runtime Stage ----
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /app/server /server

EXPOSE 8080 9090

ENTRYPOINT ["/server"]
