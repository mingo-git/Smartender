#!/bin/bash

# =============================================================================
# Smartender Backend V2 Development Setup - WebSocket Upgrade
# Upgradet bestehende Smartender Installation (Port 17051)
# =============================================================================

set -e

# Farben für bessere Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Konfiguration
SMARTENDER_PORT=17051
SMARTENDER_DB_PORT=5432
EXISTING_DB_IP="172.20.0.3"  # IP deiner bestehenden smartender-db

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    SMARTENDER BACKEND V2                        ║"
    echo "║                   WebSocket Upgrade Setup                       ║"
    echo "║                                                                  ║"
    echo "║  🔄 Upgradet bestehende Installation (Port 17051)              ║"
    echo "║  📡 Fügt WebSocket Real-time Support hinzu                     ║"
    echo "║  🗄️  Nutzt bestehende PostgreSQL Datenbank                     ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Funktionen
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_important() {
    echo -e "${PURPLE}[IMPORTANT]${NC} $1"
}

print_step() {
    echo -e "${WHITE}[STEP]${NC} $1"
}

# Bestehende Smartender Installation analysieren
analyze_existing_installation() {
    print_step "Analysiere bestehende Smartender Installation..."
    
    # Prüfe auf laufende Smartender Container
    if docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" | grep -E "(smartender|17051)" >/dev/null 2>&1; then
        print_warning "Gefundene Smartender Container:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" | head -1
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" | grep -E "(smartender|17051)"
        echo ""
        
        # Frage nach Backup
        print_important "⚠️  Das Upgrade wird den bestehenden Backend-Container ersetzen!"
        read -p "🔄 Soll vor dem Upgrade ein Backup erstellt werden? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            create_backup
        fi
    else
        print_status "Keine laufenden Smartender Container gefunden"
    fi
    
    # Prüfe Datenbank
    if docker ps --format "{{.Names}}" | grep -q "smartender-db"; then
        print_success "✅ Smartender Datenbank gefunden und läuft"
        DB_STATUS="running"
    else
        print_warning "❌ Smartender Datenbank Container nicht gefunden"
        DB_STATUS="missing"
    fi
    
    # Prüfe Netzwerk
    if docker network ls --format "{{.Name}}" | grep -q "server_default"; then
        print_success "✅ Docker Netzwerk 'server_default' gefunden"
        NETWORK_STATUS="exists"
    else
        print_warning "❌ Erwartetes Docker Netzwerk nicht gefunden"
        NETWORK_STATUS="missing"
    fi
}

# Backup erstellen
create_backup() {
    print_step "Erstelle Backup der bestehenden Installation..."
    
    BACKUP_DIR="./backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Container Status speichern
    print_status "Speichere Container-Informationen..."
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$BACKUP_DIR/containers.txt"
    
    # Database Backup (falls möglich)
    if [ "$DB_STATUS" = "running" ]; then
        print_status "Erstelle Datenbank-Backup..."
        docker exec smartender-db pg_dump -U smartender_user smartender_db > "$BACKUP_DIR/database_backup.sql" 2>/dev/null || {
            print_warning "Datenbank-Backup fehlgeschlagen (falsche Credentials?)"
        }
    fi
    
    # Docker Compose Files sichern
    if [ -f "docker-compose.yaml" ]; then
        cp docker-compose.yaml "$BACKUP_DIR/"
        print_status "Docker Compose Konfiguration gesichert"
    fi
    
    # .env Files sichern
    if [ -f ".env" ]; then
        cp .env "$BACKUP_DIR/env_backup"
        print_status "Environment-Konfiguration gesichert"
    fi
    
    print_success "📦 Backup erstellt in: $BACKUP_DIR"
}

# Überprüfe Abhängigkeiten
check_dependencies() {
    print_step "Überprüfe System-Abhängigkeiten..."
    
    local missing_deps=()
    
    # Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    else
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_status "✅ Docker $DOCKER_VERSION gefunden"
    fi
    
    # Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("docker-compose")
    else
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        print_status "✅ Docker Compose $COMPOSE_VERSION gefunden"
    fi
    
    # Optional: Go für lokale Entwicklung
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | cut -d' ' -f3)
        print_status "✅ Go $GO_VERSION gefunden (für lokale Entwicklung)"
        GO_AVAILABLE=true
    else
        print_warning "⚠️  Go nicht installiert (nur Docker-Entwicklung möglich)"
        GO_AVAILABLE=false
    fi
    
    # curl für Health Checks
    if ! command -v curl &> /dev/null; then
        print_warning "⚠️  curl nicht gefunden (Health Checks möglicherweise nicht verfügbar)"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "❌ Fehlende kritische Abhängigkeiten: ${missing_deps[*]}"
        print_status "Bitte installiere die fehlenden Pakete:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
    
    print_success "✅ Alle kritischen Abhängigkeiten vorhanden"
}

# Erstelle sichere .env falls nicht vorhanden oder upgrade
create_or_upgrade_env_file() {
    print_step "Konfiguriere Environment (.env)..."
    
    # Sichere Schlüssel generieren
    generate_secure_key() {
        if command -v openssl &> /dev/null; then
            openssl rand -hex 32
        else
            # Fallback ohne openssl
            cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 64 | head -n 1
        fi
    }
    
    if [ ! -f .env ]; then
        print_status "Erstelle neue .env Datei mit sicheren Schlüsseln..."
        
        JWT_SECRET="SmRt2024_$(generate_secure_key | cut -c1-32)"
        API_KEY="Smartender_Prod_$(generate_secure_key | cut -c1-24)_2024"
        HARDWARE_KEY="Hardware_WS_$(generate_secure_key | cut -c1-24)_2024"
        
        cat > .env << EOF
# =============================================================================
# Smartender Backend V2 Configuration - Generated $(date)
# WebSocket Upgrade für bestehende Installation
# =============================================================================

# Environment
ENVIROMENT=dev

# Server Configuration (Bestehender Port)
APP_PORT=17051

# Database Configuration (Bestehende Smartender DB)
APP_DB_USERNAME=smartender_user
APP_DB_PASSWORD=smartender_secure_2024
APP_DB_NAME=smartender_db

# Database Connection
DB_HOST=$EXISTING_DB_IP
DB_PORT=5432

# Security Keys (Auto-generated - SICHER AUFBEWAHREN!)
JWT_SECRET=$JWT_SECRET
X-API-Key=$API_KEY
HARDWARE_AUTH_KEY=$HARDWARE_KEY

# Optional: Erweiterte Konfiguration
LOG_LEVEL=info
WS_PING_INTERVAL=30

# =============================================================================
# WICHTIG: Diese Datei enthält Sicherheitsschlüssel!
# Niemals in Git committen oder öffentlich teilen!
# =============================================================================
EOF
        print_success "✅ Sichere .env Datei erstellt"
    else
        print_status "Bestehende .env Datei gefunden"
        
        # Prüfe ob wichtige Felder vorhanden sind
        if ! grep -q "APP_PORT=" .env; then
            echo "APP_PORT=17051" >> .env
            print_status "APP_PORT hinzugefügt"
        fi
        
        if ! grep -q "JWT_SECRET=" .env; then
            JWT_SECRET="SmRt2024_$(generate_secure_key | cut -c1-32)"
            echo "JWT_SECRET=$JWT_SECRET" >> .env
            print_status "JWT_SECRET hinzugefügt"
        fi
        
        if ! grep -q "HARDWARE_AUTH_KEY=" .env; then
            HARDWARE_KEY="Hardware_WS_$(generate_secure_key | cut -c1-24)_2024"
            echo "HARDWARE_AUTH_KEY=$HARDWARE_KEY" >> .env
            print_status "HARDWARE_AUTH_KEY hinzugefügt"
        fi
        
        print_success "✅ .env Datei aktualisiert"
    fi
}

# Stoppe alte Smartender Services
stop_old_services() {
    print_step "Stoppe alte Smartender Services..."
    
    # Stoppe alte Backend Container
    OLD_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -E "(smartender-app|server-app)" || true)
    
    if [ ! -z "$OLD_CONTAINERS" ]; then
        print_status "Stoppe alte Backend Container..."
        echo "$OLD_CONTAINERS" | xargs -r docker stop
        print_success "✅ Alte Backend Container gestoppt"
    else
        print_status "Keine alten Backend Container gefunden"
    fi
    
    # Entferne alte Container (optional)
    read -p "🗑️  Sollen alte Backend Container entfernt werden? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        OLD_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -E "(smartender-app|server-app)" || true)
        if [ ! -z "$OLD_CONTAINERS" ]; then
            echo "$OLD_CONTAINERS" | xargs -r docker rm
            print_success "✅ Alte Container entfernt"
        fi
    fi
}

# Starte neue Services
start_upgraded_services() {
    print_step "Starte Smartender Backend V2..."
    
    # Build neues Image
    print_status "Baue neues Backend Image..."
    docker-compose -f docker-compose.local.yaml build --no-cache smartender-app
    
    # Starte nur Backend (DB läuft bereits)
    print_status "Starte neues Backend..."
    docker-compose -f docker-compose.local.yaml up -d smartender-app
    
    # Warte auf Backend
    print_status "Warte auf Backend-Initialisierung..."
    timeout=60
    while ! curl -s http://localhost:$SMARTENDER_PORT/status &>/dev/null; do
        echo -n "."
        sleep 2
        timeout=$((timeout - 2))
        if [ $timeout -eq 0 ]; then
            print_warning "Backend antwortet nicht auf /status nach 60s"
            print_status "Überprüfe Logs mit: docker-compose -f docker-compose.local.yaml logs smartender-app"
            break
        fi
    done
    echo ""
    
    # Test WebSocket Endpoint
    print_status "Teste WebSocket Endpoint..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$SMARTENDER_PORT/api/ws | grep -q "426"; then
        print_success "✅ WebSocket Endpoint verfügbar (HTTP 426 = Upgrade Required)"
    else
        print_warning "⚠️  WebSocket Endpoint möglicherweise nicht verfügbar"
    fi
    
    print_success "🚀 Smartender Backend V2 gestartet!"
}

# Lokale Go-Entwicklung (nutzt bestehende DB)
start_local_development() {
    print_step "Starte lokale Go-Entwicklung..."
    
    if [ "$GO_AVAILABLE" != true ]; then
        print_error "Go ist nicht installiert. Verwende 'upgrade-docker' stattdessen."
        exit 1
    fi
    
    # Prüfe ob bestehende DB erreichbar ist
    if docker ps --format "{{.Names}}" | grep -q "smartender-db"; then
        print_status "Nutze bestehende Smartender Datenbank"
        export DB_HOST=$EXISTING_DB_IP
        export DB_PORT=5432
    else
        print_warning "Bestehende DB nicht gefunden, starte lokale Development DB..."
        docker-compose -f docker-compose.local.yaml --profile dev up -d smartender-db-dev
        export DB_HOST=localhost
        export DB_PORT=5432
        
        # Warte auf DB
        timeout=30
        while ! docker-compose -f docker-compose.local.yaml exec -T smartender-db-dev pg_isready -U smartender_user &>/dev/null; do
            echo -n "."
            sleep 2
            timeout=$((timeout - 2))
            if [ $timeout -eq 0 ]; then
                print_error "Development DB konnte nicht gestartet werden"
                exit 1
            fi
        done
        echo ""
    fi
    
    # Go Dependencies
    print_status "Installiere Go Dependencies..."
    go mod download
    go mod tidy
    
    # Server starten
    print_success "🚀 Starte Go Server lokal..."
    print_important "Lokale Entwicklung aktiv - Backend läuft außerhalb Docker"
    show_service_urls
    go run main.go
}

# Zeige Service URLs
show_service_urls() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 SMARTENDER V2 AKTIV                  ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}🌐 Backend API:${NC}        http://localhost:$SMARTENDER_PORT"
    echo -e "${GREEN}📡 WebSocket:${NC}          ws://localhost:$SMARTENDER_PORT/api/ws"
    echo -e "${GREEN}🏥 Health Check:${NC}       http://localhost:$SMARTENDER_PORT/status"
    echo -e "${GREEN}🔧 Hardware WebSocket:${NC} ws://localhost:$SMARTENDER_PORT/smartender/socket"
    echo ""
    echo -e "${BLUE}📋 Nützliche Befehle:${NC}"
    echo "   Logs anzeigen:     docker-compose -f docker-compose.local.yaml logs -f"
    echo "   Services stoppen:  docker-compose -f docker-compose.local.yaml down"
    echo "   Neubau:           docker-compose -f docker-compose.local.yaml build --no-cache"
    echo ""
    echo -e "${YELLOW}🔑 WebSocket Test (mit JWT Token):${NC}"
    echo "   wscat -c 'ws://localhost:$SMARTENDER_PORT/api/ws?token=YOUR_JWT_TOKEN'"
    echo ""
}

# Services stoppen
stop_services() {
    print_step "Stoppe Smartender V2 Services..."
    docker-compose -f docker-compose.local.yaml down
    print_success "✅ Services gestoppt!"
}

# Logs anzeigen
show_logs() {
    print_step "Zeige Smartender V2 Logs..."
    docker-compose -f docker-compose.local.yaml logs -f
}

# System-Status anzeigen
show_status() {
    print_step "Smartender V2 System Status..."
    echo ""
    
    # Container Status
    echo -e "${BLUE}📦 Container Status:${NC}"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "(smartender|NAMES)" || echo "Keine Smartender Container aktiv"
    echo ""
    
    # Service Health
    echo -e "${BLUE}🏥 Service Health:${NC}"
    if curl -s http://localhost:$SMARTENDER_PORT/status >/dev/null 2>&1; then
        echo "✅ Backend:     http://localhost:$SMARTENDER_PORT (OK)"
        
        # API Test
        API_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:$SMARTENDER_PORT/status -o /dev/null)
        echo "   Status Code: $API_RESPONSE"
        
    else
        echo "❌ Backend:     http://localhost:$SMARTENDER_PORT (Nicht erreichbar)"
    fi
    
    # WebSocket Test
    WS_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:$SMARTENDER_PORT/api/ws -o /dev/null)
    if [ "$WS_RESPONSE" = "426" ]; then
        echo "✅ WebSocket:   ws://localhost:$SMARTENDER_PORT/api/ws (OK - Upgrade Required)"
    else
        echo "❌ WebSocket:   Status Code $WS_RESPONSE"
    fi
    
    echo ""
    
    # Database Status
    echo -e "${BLUE}🗄️  Database Status:${NC}"
    if docker ps --format "{{.Names}}" | grep -q "smartender-db"; then
        echo "✅ PostgreSQL:  smartender-db (Running)"
    else
        echo "❌ PostgreSQL:  smartender-db (Nicht gefunden)"
    fi
    
    echo ""
}

# Tests ausführen
run_tests() {
    print_step "Führe Tests aus..."
    if [ "$GO_AVAILABLE" = true ]; then
        go test ./tests/... -v
    else
        docker run --rm -v "$PWD":/app -w /app golang:1.21-alpine go test ./tests/... -v
    fi
}

# Reset (komplette Neuinstallation)
reset_installation() {
    print_warning "⚠️  ACHTUNG: Dies entfernt alle Smartender V2 Container und Daten!"
    read -p "Wirklich fortfahren? (Tippe 'RESET' um zu bestätigen): " -r
    if [ "$REPLY" = "RESET" ]; then
        print_step "Setze Smartender V2 zurück..."
        
        # Stoppe und entferne Container
        docker-compose -f docker-compose.local.yaml down -v --remove-orphans
        
        # Entferne Images
        docker images | grep smartender | awk '{print $3}' | xargs -r docker rmi -f
        
        # Entferne .env
        rm -f .env
        
        print_success "✅ Reset abgeschlossen"
    else
        print_status "Reset abgebrochen"
    fi
}

# Hilfe anzeigen
show_help() {
    echo -e "${CYAN}Smartender Backend V2 - WebSocket Upgrade Setup${NC}"
    echo "=================================================="
    echo ""
    echo -e "${WHITE}VERWENDUNG:${NC} $0 [COMMAND]"
    echo ""
    echo -e "${WHITE}UPGRADE COMMANDS:${NC}"
    echo "  upgrade-docker    🔄 Upgrade zu V2 mit Docker (bestehende DB)"
    echo "  upgrade-local     🔄 Upgrade zu V2 mit Go lokal (Development)"
    echo ""
    echo -e "${WHITE}MANAGEMENT COMMANDS:${NC}"
    echo "  start            🚀 Starte Services"
    echo "  stop             ⏹️  Stoppe Services"  
    echo "  restart          🔄 Neustart Services"
    echo "  status           📊 Zeige System-Status"
    echo "  logs             📋 Zeige Logs"
    echo ""
    echo -e "${WHITE}DEVELOPMENT COMMANDS:${NC}"
    echo "  test             🧪 Führe Tests aus"
    echo "  build            🔨 Rebuild Container"
    echo "  reset            💥 Kompletter Reset (VORSICHT!)"
    echo ""
    echo -e "${WHITE}INFORMATION:${NC}"
    echo "  help             ❓ Zeige diese Hilfe"
    echo ""
    echo -e "${GREEN}💡 Empfohlen für den Start:${NC}"
    echo "   $0 upgrade-docker    # Upgrade bestehende Installation"
    echo "   $0 upgrade-local     # Development mit Go lokal"
    echo ""
}

# Main Function
main() {
    print_banner
    
    case "${1:-help}" in
        "upgrade-docker")
            check_dependencies
            analyze_existing_installation
            create_or_upgrade_env_file
            stop_old_services
            start_upgraded_services
            show_service_urls
            ;;
        "upgrade-local")
            check_dependencies
            analyze_existing_installation
            create_or_upgrade_env_file
            stop_old_services
            start_local_development
            ;;
        "start")
            docker-compose -f docker-compose.local.yaml up -d
            show_service_urls
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 2
            docker-compose -f docker-compose.local.yaml up -d
            show_service_urls
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "test")
            run_tests
            ;;
        "build")
            docker-compose -f docker-compose.local.yaml build --no-cache
            print_success "✅ Build abgeschlossen"
            ;;
        "reset")
            reset_installation
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Script starten
main "$@"