#!/bin/bash

##############################################################################
# Interaktív .env Fájl Létrehozása
# Kérdezi be a szükséges környezeti változókat és létrehozza a .env fájlt
##############################################################################

# Színek
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Projekt gyökér
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Interaktív .env Fájl Létrehozása                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Helper functions
ask_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local value
    local prompt_text
    
    if [ -n "$default" ]; then
        prompt_text=$(echo -e "${CYAN}$prompt ${YELLOW}[$default]: ${NC}")
        read -p "$prompt_text" value
        value="${value:-$default}"
    else
        prompt_text=$(echo -e "${CYAN}$prompt: ${NC}")
        read -p "$prompt_text" value
    fi
    
    eval "$var_name='$value'"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer
    local prompt_text
    
    if [ "$default" = "y" ]; then
        prompt_text=$(echo -e "${CYAN}$prompt ${YELLOW}[I/n]: ${NC}")
        read -p "$prompt_text" answer
        answer="${answer:-i}"
    else
        prompt_text=$(echo -e "${CYAN}$prompt ${YELLOW}[i/N]: ${NC}")
        read -p "$prompt_text" answer
        answer="${answer:-n}"
    fi
    
    case "$answer" in
        [Ii]*) return 0 ;;
        *) return 1 ;;
    esac
}

generate_secret_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32
    else
        # Fallback: használunk dátumot és random számot
        date +%s | sha256sum | base64 | head -c 64
    fi
}

# Ellenőrzés: már létezik-e .env fájl
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC} A .env fájl már létezik!"
    if ask_yes_no "Szeretnéd felülírni?"; then
        echo -e "${YELLOW}⚠${NC} A régi .env fájl mentésre kerül .env.backup néven"
        cp .env .env.backup
    else
        echo -e "${GREEN}✓${NC} Megtartjuk a meglévő .env fájlt"
        exit 0
    fi
fi

echo -e "${BLUE}Kezdjük el a beállításokat...${NC}"
echo ""

# ===========================================
# Alkalmazás Beállítások
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Alkalmazás Beállítások${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

ask_with_default "Alkalmazás neve" "Nincsenek Fények!" APP_NAME

echo ""
echo "Környezet típus:"
echo "  1) development (fejlesztés)"
echo "  2) production (éles)"
echo "  3) staging (tesztelés)"
env_prompt=$(echo -e "${CYAN}Válassz környezetet [1-3] (1): ${NC}")
read -p "$env_prompt" env_choice
env_choice="${env_choice:-1}"

case $env_choice in
    1) APP_ENV="development" ;;
    2) APP_ENV="production" ;;
    3) APP_ENV="staging" ;;
    *) APP_ENV="development" ;;
esac

if [ "$APP_ENV" = "production" ]; then
    DEBUG="false"
else
    DEBUG="true"
fi

echo ""
if ask_yes_no "Generáljak egy erős SECRET_KEY-et automatikusan?" "y"; then
    SECRET_KEY=$(generate_secret_key)
    echo -e "${GREEN}✓${NC} SECRET_KEY generálva"
else
    ask_with_default "SECRET_KEY (minimum 32 karakter)" "" SECRET_KEY
    if [ ${#SECRET_KEY} -lt 32 ]; then
        echo -e "${YELLOW}⚠${NC} A SECRET_KEY rövidebb mint 32 karakter. Ajánlott erős kulcs használata!"
    fi
fi

# ===========================================
# API Beállítások
# ===========================================
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  API Beállítások${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

ask_with_default "API Host (0.0.0.0 = minden interfész, 127.0.0.1 = csak localhost)" "0.0.0.0" API_HOST
ask_with_default "API Port" "8000" API_PORT

# ===========================================
# Adatbázis Beállítások
# ===========================================
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Adatbázis Beállítások${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Használsz Docker-t?"
echo "  1) Igen (Docker Compose)"
echo "  2) Nem (lokális telepítés)"
docker_prompt=$(echo -e "${CYAN}Választás [1-2] (1): ${NC}")
read -p "$docker_prompt" docker_choice
docker_choice="${docker_choice:-1}"

if [ "$docker_choice" = "1" ]; then
    MONGODB_HOST="mongodb"
    POSTGRES_HOST="postgres"
    REDIS_HOST="redis"
    echo -e "${GREEN}✓${NC} Docker környezeti változók használata"
else
    MONGODB_HOST="localhost"
    POSTGRES_HOST="localhost"
    REDIS_HOST="localhost"
    echo -e "${GREEN}✓${NC} Lokális környezeti változók használata"
fi

echo ""
echo -e "${YELLOW}MongoDB Beállítások:${NC}"
ask_with_default "MongoDB Host" "$MONGODB_HOST" MONGODB_HOST
ask_with_default "MongoDB Port" "27017" MONGODB_PORT
ask_with_default "MongoDB Adatbázis neve" "nincsenekfenyek" MONGODB_DB_NAME

MONGODB_URL="mongodb://${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DB_NAME}"

echo ""
echo -e "${YELLOW}PostgreSQL Beállítások:${NC}"
ask_with_default "PostgreSQL Host" "$POSTGRES_HOST" POSTGRES_HOST
ask_with_default "PostgreSQL Port" "5432" POSTGRES_PORT
ask_with_default "PostgreSQL Adatbázis neve" "nincsenekfenyek" POSTGRES_DB
ask_with_default "PostgreSQL Felhasználó" "postgres" POSTGRES_USER

if ask_yes_no "Szeretnél egy erős jelszót generálni a PostgreSQL-hez?" "y"; then
    POSTGRES_PASSWORD=$(generate_secret_key | head -c 32)
    echo -e "${GREEN}✓${NC} PostgreSQL jelszó generálva"
else
    postgres_pw_prompt=$(echo -e "${CYAN}PostgreSQL Jelszó: ${NC}")
    read -sp "$postgres_pw_prompt" POSTGRES_PASSWORD
    echo ""
fi

POSTGRESQL_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

echo ""
echo -e "${YELLOW}Redis Beállítások:${NC}"
ask_with_default "Redis Host" "$REDIS_HOST" REDIS_HOST
ask_with_default "Redis Port" "6379" REDIS_PORT
ask_with_default "Redis Database szám" "0" REDIS_DB

REDIS_URL="redis://${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}"

# ===========================================
# Celery Beállítások
# ===========================================
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Celery Beállítások${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

CELERY_BROKER_URL="$REDIS_URL"
CELERY_RESULT_BACKEND="$REDIS_URL"

echo -e "${GREEN}✓${NC} Celery Broker: $CELERY_BROKER_URL"
echo -e "${GREEN}✓${NC} Celery Result Backend: $CELERY_RESULT_BACKEND"

# ===========================================
# Logging Beállítások
# ===========================================
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Logging Beállítások${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Log szint:"
echo "  1) DEBUG (részletes)"
echo "  2) INFO (alapértelmezett)"
echo "  3) WARNING (csak figyelmeztetések)"
echo "  4) ERROR (csak hibák)"
log_prompt=$(echo -e "${CYAN}Válassz log szintet [1-4] (2): ${NC}")
read -p "$log_prompt" log_choice
log_choice="${log_choice:-2}"

case $log_choice in
    1) LOG_LEVEL="DEBUG" ;;
    2) LOG_LEVEL="INFO" ;;
    3) LOG_LEVEL="WARNING" ;;
    4) LOG_LEVEL="ERROR" ;;
    *) LOG_LEVEL="INFO" ;;
esac

ask_with_default "Log fájl elérési út" "logs/app.log" LOG_FILE

# ===========================================
# .env Fájl Létrehozása
# ===========================================
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  .env Fájl Létrehozása${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

cat > .env << EOF
# ===========================================
# Nincsenek Fények! - Environment Variables
# ===========================================
# Automatikusan generálva: $(date '+%Y-%m-%d %H:%M:%S')
# Script: interactive-env-setup.sh

# ===========================================
# Alkalmazás Beállítások
# ===========================================

APP_NAME=${APP_NAME}
APP_ENV=${APP_ENV}
DEBUG=${DEBUG}
SECRET_KEY=${SECRET_KEY}

# ===========================================
# API Beállítások
# ===========================================

API_HOST=${API_HOST}
API_PORT=${API_PORT}

# ===========================================
# MongoDB Beállítások
# ===========================================

MONGODB_URL=${MONGODB_URL}
MONGODB_DB_NAME=${MONGODB_DB_NAME}

# ===========================================
# PostgreSQL Beállítások
# ===========================================

POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRESQL_URL=${POSTGRESQL_URL}

# ===========================================
# Redis Beállítások
# ===========================================

REDIS_URL=${REDIS_URL}

# ===========================================
# Celery Beállítások
# ===========================================

CELERY_BROKER_URL=${CELERY_BROKER_URL}
CELERY_RESULT_BACKEND=${CELERY_RESULT_BACKEND}

# ===========================================
# Logging Beállítások
# ===========================================

LOG_LEVEL=${LOG_LEVEL}
LOG_FILE=${LOG_FILE}
EOF

# Jogosultságok beállítása
chmod 600 .env

echo -e "${GREEN}✓${NC} .env fájl létrehozva!"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓${NC} Sikeresen beállított környezeti változók:"
echo ""
echo -e "  ${CYAN}Alkalmazás:${NC} ${APP_NAME} (${APP_ENV})"
echo -e "  ${CYAN}API:${NC} http://${API_HOST}:${API_PORT}"
echo -e "  ${CYAN}MongoDB:${NC} ${MONGODB_URL}"
echo -e "  ${CYAN}PostgreSQL:${NC} ${POSTGRES_DB}@${POSTGRES_HOST}"
echo -e "  ${CYAN}Redis:${NC} ${REDIS_URL}"
echo -e "  ${CYAN}Log szint:${NC} ${LOG_LEVEL}"
echo ""
echo -e "${YELLOW}⚠${NC} FONTOS: Ellenőrizd a .env fájlt és módosítsd szükség esetén!"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

