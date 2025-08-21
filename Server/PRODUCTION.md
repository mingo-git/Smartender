# 🚀 Smartender Backend V2 - Production Guide

## Quick Start

### 1. Deployment
```bash
# Executable machen
chmod +x deploy-production.sh backup.sh monitor.sh

# Deployen
./deploy-production.sh
```

### 2. Reverse Proxy Setup
**Port weiterleiten:** `17051`
```nginx
location / {
    proxy_pass http://localhost:17051;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}
```

## 📋 Management Commands

### Status & Monitoring
```bash
./monitor.sh                  # Vollständiger Status-Check
docker-compose ps             # Container Status
docker-compose logs -f        # Live Logs
curl http://localhost:17051/status  # Backend Health
```

### Backup & Restore
```bash
./backup.sh                   # Database Backup erstellen
ls ./backups/                 # Backups anzeigen
```

### Service Management
```bash
docker-compose up -d          # Services starten
docker-compose down           # Services stoppen
docker-compose restart        # Services neustarten
docker-compose build --no-cache  # Neu bauen
```

### Logs & Debugging
```bash
docker-compose logs -f smartender-app  # Backend Logs
docker-compose logs -f smartender-db   # Database Logs
docker exec -it smartender-postgres-prod psql -U smartender_user -d smartender_db  # DB Shell
```

## 🔒 Security Checklist

- [x] `ENVIRONMENT=prod` in .env
- [x] Sichere JWT_SECRET gesetzt
- [x] Sichere API Keys gesetzt
- [x] Database Passwort geändert
- [x] Container läuft nicht als root
- [x] Logs sind rotiert (max 10MB, 3 Dateien)

## 📊 Service URLs

- **Backend API:** `http://localhost:17051`
- **WebSocket:** `ws://localhost:17051/api/ws`
- **Health Check:** `http://localhost:17051/status`
- **Database:** `localhost:5432` (nur intern)

## 🆘 Troubleshooting

### Backend startet nicht
```bash
docker-compose logs smartender-app
# Check .env file (ENVIRONMENT=prod)
# Check database connection
```

### Database Probleme
```bash
docker-compose logs smartender-db
docker exec smartender-postgres-prod pg_isready -U smartender_user
```

### WebSocket Probleme
```bash
# Test WebSocket Endpoint
curl -I http://localhost:17051/api/ws
# Should return 426 Upgrade Required
```