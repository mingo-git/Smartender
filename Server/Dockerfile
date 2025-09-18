FROM golang:1.21-alpine

RUN apk add --no-cache bash curl
WORKDIR /app

# Quellcode + EntryPoint ins Image
COPY . .
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o smartender-backend main.go
RUN chmod +x smartender-backend

# Buildzeit-Check (ENV sind hier noch nicht gesetzt, Fehler ist ok)
RUN ls -la smartender-backend && ./smartender-backend --help 2>&1 || echo "Binary test done"

EXPOSE 17051
CMD ["/entrypoint.sh"]
