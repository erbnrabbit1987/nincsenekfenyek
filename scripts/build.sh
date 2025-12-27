#!/bin/bash

##############################################################################
# Interaktív Build Script
# Nincsenek Fények! - Development Build és Tesztelés
##############################################################################

set -e

# Színek a kimenethez
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Projekt gyökérkönyvtár
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Nincsenek Fények! - Interaktív Build Script              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

##############################################################################
# Helper Functions
##############################################################################

print_step() {
    echo -e "\n${GREEN}[LÉPÉS]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[FIGYELMEZTETÉS]${NC} $1"
}

print_error() {
    echo -e "${RED}[HIBA]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SIKERES]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 nincs telepítve!"
        return 1
    fi
    return 0
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer
    
    if [ "$default" = "y" ]; then
        read -p "$(echo -e ${BLUE}$prompt [I/n]: ${NC})" answer
        answer="${answer:-i}"
    else
        read -p "$(echo -e ${BLUE}$prompt [i/N]: ${NC})" answer
        answer="${answer:-n}"
    fi
    
    case "$answer" in
        [Ii]*) return 0 ;;
        *) return 1 ;;
    esac
}

##############################################################################
# Előfeltételek ellenőrzése
##############################################################################

print_step "Előfeltételek ellenőrzése..."

MISSING_DEPS=()

check_command python3 || MISSING_DEPS+=("python3")
check_command pip3 || MISSING_DEPS+=("pip3")
check_command docker || MISSING_DEPS+=("docker")
check_command docker-compose || MISSING_DEPS+=("docker-compose")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    print_error "Hiányzó függőségek: ${MISSING_DEPS[*]}"
    echo "Kérlek telepítsd ezeket a parancsokat, mielőtt folytatnád."
    exit 1
fi

print_success "Minden előfeltétel telepítve van"

# Python verzió ellenőrzése
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
if [ "$(printf '%s\n' "3.11" "$PYTHON_VERSION" | sort -V | head -n1)" != "3.11" ]; then
    print_warning "Python 3.11+ ajánlott. Jelenlegi verzió: $PYTHON_VERSION"
    if ! ask_yes_no "Folytatod a build-et ezzel a verzióval?"; then
        exit 1
    fi
fi

##############################################################################
# Környezeti változók ellenőrzése
##############################################################################

print_step "Környezeti változók ellenőrzése..."

if [ ! -f ".env" ]; then
    print_warning ".env fájl nem található"
    if ask_yes_no "Szeretnél létrehozni egy .env.example fájlból?"; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_info ".env fájl létrehozva. Kérlek szerkeszd a SECRET_KEY-t és egyéb beállításokat!"
            if ask_yes_no "Megnyitom a .env fájlt szerkesztéshez?"; then
                ${EDITOR:-nano} .env
            fi
        else
            print_error ".env.example fájl sem található!"
            exit 1
        fi
    else
        print_error ".env fájl szükséges a build-hez!"
        exit 1
    fi
fi

print_success ".env fájl megtalálva"

##############################################################################
# Build mód választása
##############################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Build Mód Választása                                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "1) Teljes build (Docker build + dependencies telepítése)"
echo "2) Csak Python dependencies telepítése"
echo "3) Csak Docker build"
echo "4) Tesztelés futtatása"
echo "5) Lint és formázás ellenőrzése"
echo "6) Minden (teljes build + tesztek + lint)"
echo ""
read -p "$(echo -e ${BLUE}Válassz módot [1-6]: ${NC})" BUILD_MODE
BUILD_MODE=${BUILD_MODE:-1}

##############################################################################
# Virtual Environment
##############################################################################

if [ "$BUILD_MODE" != "3" ]; then
    print_step "Virtual Environment beállítása..."
    
    if [ ! -d "venv" ]; then
        print_info "Virtual environment létrehozása..."
        python3 -m venv venv
        print_success "Virtual environment létrehozva"
    else
        print_info "Virtual environment már létezik"
    fi
    
    print_info "Virtual environment aktiválása..."
    source venv/bin/activate
    
    # Pip frissítése
    print_info "pip frissítése..."
    pip install --upgrade pip setuptools wheel
fi

##############################################################################
# Python Dependencies
##############################################################################

if [ "$BUILD_MODE" = "1" ] || [ "$BUILD_MODE" = "2" ] || [ "$BUILD_MODE" = "6" ]; then
    print_step "Python dependencies telepítése..."
    
    if [ "$BUILD_MODE" != "3" ]; then
        source venv/bin/activate
    fi
    
    print_info "Production dependencies telepítése..."
    pip install -r requirements.txt
    
    if [ -f "requirements-dev.txt" ]; then
        print_info "Development dependencies telepítése..."
        pip install -r requirements-dev.txt
    fi
    
    # SpaCy magyar modell ellenőrzése
    print_info "SpaCy magyar modell ellenőrzése..."
    if ! python3 -c "import spacy; spacy.load('hu_core_news_lg')" 2>/dev/null; then
        if ! python3 -c "import spacy; spacy.load('hu_core_news_sm')" 2>/dev/null; then
            print_warning "SpaCy magyar modell nincs telepítve!"
            if ask_yes_no "Szeretnéd telepíteni a hu_core_news_lg modellt? (ajánlott)"; then
                python3 -m spacy download hu_core_news_lg
                print_success "SpaCy magyar modell telepítve"
            elif ask_yes_no "Telepítsük a kisebb hu_core_news_sm modellt?"; then
                python3 -m spacy download hu_core_news_sm
                print_success "SpaCy magyar modell (small) telepítve"
            else
                print_warning "Fact-checking funkciók korlátozottan működnek NLP modell nélkül"
            fi
        else
            print_info "SpaCy magyar modell (small) telepítve van"
        fi
    else
        print_success "SpaCy magyar modell telepítve van"
    fi
    
    print_success "Dependencies telepítve"
fi

##############################################################################
# Docker Build
##############################################################################

if [ "$BUILD_MODE" = "1" ] || [ "$BUILD_MODE" = "3" ] || [ "$BUILD_MODE" = "6" ]; then
    print_step "Docker build..."
    
    if ask_yes_no "Szeretnéd build-elni a Docker image-eket?" "y"; then
        print_info "Docker image-ek build-elése..."
        docker-compose build
        
        if [ $? -eq 0 ]; then
            print_success "Docker image-ek sikeresen build-elve"
        else
            print_error "Docker build sikertelen!"
            exit 1
        fi
    fi
fi

##############################################################################
# Lint és Formázás
##############################################################################

if [ "$BUILD_MODE" = "5" ] || [ "$BUILD_MODE" = "6" ]; then
    print_step "Code lint és formázás ellenőrzése..."
    
    if [ "$BUILD_MODE" != "3" ]; then
        source venv/bin/activate
    fi
    
    # Black formázás ellenőrzése
    if command -v black &> /dev/null; then
        print_info "Black formázás ellenőrzése..."
        if black --check src/ tests/ 2>/dev/null; then
            print_success "Black: Minden fájl formázva"
        else
            print_warning "Black: Találhatók formázandó fájlok"
            if ask_yes_no "Szeretnéd automatikusan formázni?"; then
                black src/ tests/
                print_success "Fájlok formázva"
            fi
        fi
    fi
    
    # Flake8 lint
    if command -v flake8 &> /dev/null; then
        print_info "Flake8 lint ellenőrzése..."
        flake8 src/ tests/ --max-line-length=120 --exclude=venv,__pycache__ || true
    fi
    
    # isort import rendezés
    if command -v isort &> /dev/null; then
        print_info "Import rendezés ellenőrzése..."
        if isort --check-only src/ tests/ 2>/dev/null; then
            print_success "isort: Minden import rendezve"
        else
            print_warning "isort: Találhatók rendezendő importok"
            if ask_yes_no "Szeretnéd automatikusan rendezni az importokat?"; then
                isort src/ tests/
                print_success "Importok rendezve"
            fi
        fi
    fi
fi

##############################################################################
# Tesztek
##############################################################################

if [ "$BUILD_MODE" = "4" ] || [ "$BUILD_MODE" = "6" ]; then
    print_step "Tesztek futtatása..."
    
    if [ "$BUILD_MODE" != "3" ]; then
        source venv/bin/activate
    fi
    
    # Szolgáltatások ellenőrzése
    print_info "MongoDB ellenőrzése..."
    if ! docker-compose ps mongodb | grep -q "Up"; then
        print_warning "MongoDB nincs futva. Indítom..."
        docker-compose up -d mongodb
        sleep 5
    fi
    
    print_info "Redis ellenőrzése..."
    if ! docker-compose ps redis | grep -q "Up"; then
        print_warning "Redis nincs futva. Indítom..."
        docker-compose up -d redis
        sleep 2
    fi
    
    # Tesztek futtatása
    if ask_yes_no "Szeretnéd futtatni a teszteket?" "y"; then
        print_info "Pytest futtatása..."
        pytest tests/ -v --cov=src --cov-report=html --cov-report=term || {
            print_warning "Néhány teszt sikertelen lehet. Nézd meg a részleteket fent."
        }
        
        print_success "Tesztek futtatva (ha voltak)"
    fi
fi

##############################################################################
# Összefoglaló
##############################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Build Összefoglaló                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_success "Build folyamat befejezve!"

if ask_yes_no "Szeretnéd elindítani a szolgáltatásokat Docker Compose-szal?"; then
    print_step "Szolgáltatások indítása..."
    docker-compose up -d
    print_success "Szolgáltatások elindítva!"
    print_info "API dokumentáció: http://localhost:8000/docs"
    print_info "Logok megtekintése: docker-compose logs -f"
fi

echo ""
print_info "Következő lépések:"
echo "  - API tesztelése: http://localhost:8000/docs"
echo "  - Celery worker indítása: celery -A src.celery_app worker --loglevel=info"
echo "  - Celery beat indítása: celery -A src.celery_app beat --loglevel=info"
echo ""


