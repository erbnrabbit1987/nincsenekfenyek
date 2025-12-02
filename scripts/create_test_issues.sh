#!/bin/bash
# ===========================================
# Nincsenek Fények! - Tesztesetek Issue Létrehozása
# ===========================================
# Ez a script a docs/TEST_CASES_ISSUES.md fájl alapján
# létrehozza az összes tesztesetet Git issue-ként.
# ===========================================

set -e

# Színek
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script könyvtár
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_CASES_FILE="${PROJECT_ROOT}/docs/TEST_CASES_ISSUES.md"

# Log függvény
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Ellenőrzések
check_requirements() {
    log "Követelmények ellenőrzése..."
    
    # Git repository ellenőrzés
    if [ ! -d "${PROJECT_ROOT}/.git" ]; then
        error "Nem Git repository könyvtárban vagyunk!"
        exit 1
    fi
    
    # Test cases fájl ellenőrzés
    if [ ! -f "${TEST_CASES_FILE}" ]; then
        error "Tesztesetek fájl nem található: ${TEST_CASES_FILE}"
        exit 1
    fi
    
    # GitHub CLI ellenőrzés
    if command -v gh &> /dev/null; then
        log "GitHub CLI (gh) található"
        CLI_TOOL="gh"
        if ! gh auth status &> /dev/null; then
            error "GitHub CLI nincs bejelentkezve! Futtasd: gh auth login"
            exit 1
        fi
    else
        error "GitHub CLI (gh) nincs telepítve!"
        error "Telepítsd: https://cli.github.com/"
        exit 1
    fi
    
    log "✓ Minden követelmény teljesül"
}

# Teszteset kinyerése a markdown fájlból
extract_test_case() {
    local file="$1"
    local test_id="$2"
    
    # Keresés a teszteset ID alapján
    awk -v test_id="$test_id" '
        BEGIN { in_test = 0; content = "" }
        /^### TC-/ {
            if ($0 ~ test_id) {
                in_test = 1
                content = $0 "\n"
            } else if (in_test) {
                exit
            }
            next
        }
        in_test {
            if (/^## / && !/^## Issue/) {
                exit
            }
            if (/^### TC-/) {
                exit
            }
            content = content $0 "\n"
        }
        END { print content }
    ' "$file"
}

# Issue body generálása
generate_issue_body() {
    local test_case_content="$1"
    echo "$test_case_content"
}

# Issue címkék kinyerése
extract_labels() {
    local test_case_content="$1"
    local labels=""
    
    # Prioritás
    if echo "$test_case_content" | grep -qF "**Prioritás:** P1"; then
        labels="${labels}priority-p1,"
    elif echo "$test_case_content" | grep -qF "**Prioritás:** P2"; then
        labels="${labels}priority-p2,"
    elif echo "$test_case_content" | grep -qF "**Prioritás:** P3"; then
        labels="${labels}priority-p3,"
    elif echo "$test_case_content" | grep -qF "**Prioritás:** P4"; then
        labels="${labels}priority-p4,"
    fi
    
    # Típus
    if echo "$test_case_content" | grep -qF "**Típus:** Funkcionális"; then
        labels="${labels}type-functional,"
    elif echo "$test_case_content" | grep -qF "**Típus:** Integration"; then
        labels="${labels}type-integration,"
    elif echo "$test_case_content" | grep -qF "**Típus:** Biztonsági"; then
        labels="${labels}type-security,"
    elif echo "$test_case_content" | grep -qF "**Típus:** Teljesítmény"; then
        labels="${labels}type-performance,"
    fi
    
    # Címkék a dokumentumból
    if echo "$test_case_content" | grep -qF "**Címkék:**"; then
        local doc_labels=$(echo "$test_case_content" | grep -F "**Címkék:**" | sed 's/.*\*\*Címkék:\*\* //' | tr -d '`' | tr ',' '\n' | tr -d ' ' | grep -v '^$' | tr '\n' ',' | sed 's/,$//')
        if [ -n "$doc_labels" ]; then
            labels="${labels}${doc_labels},"
        fi
    fi
    
    # Mindig hozzáadjuk a testing címkét
    labels="testing,test-case,${labels}"
    
    # Duplikációk eltávolítása
    echo "$labels" | tr ',' '\n' | sort -u | grep -v '^$' | tr '\n' ',' | sed 's/,$//'
}

# Issue cím kinyerése
extract_title() {
    local test_case_content="$1"
    echo "$test_case_content" | head -n 1 | sed 's/^### //'
}

# Teszteset ID-k kinyerése
extract_test_case_ids() {
    local file="$1"
    grep "^### TC-" "$file" | sed 's/^### //' | sed 's/:.*//'
}

# Szükséges címkék
get_required_labels() {
    echo "testing,test-case,priority-p1,priority-p2,priority-p3,priority-p4,type-functional,type-integration,type-security,type-performance,source,collection,factcheck,search"
}

# Címkék létrehozása GitHub-on
create_github_labels() {
    local repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    local labels=$(get_required_labels | tr ',' '\n')
    local created=0
    local existing=0
    
    log "Címkék ellenőrzése és létrehozása..."
    
    local existing_labels=$(gh label list --repo "$repo" --json name -q '.[].name' 2>/dev/null || echo "")
    
    while IFS= read -r label; do
        if [ -z "$label" ]; then
            continue
        fi
        
        if echo "$existing_labels" | grep -qF "^${label}$"; then
            ((existing++))
            continue
        fi
        
        # Címke szín meghatározása
        local color="ededed"
        case "$label" in
            testing|test-case) color="1f883d" ;;
            priority-p1) color="d73a4a" ;;
            priority-p2) color="f85149" ;;
            priority-p3) color="fbca04" ;;
            priority-p4) color="0e8a16" ;;
            type-functional) color="0052cc" ;;
            type-integration) color="5319e7" ;;
            type-security) color="b60205" ;;
            type-performance) color="0e8a16" ;;
            source|collection|factcheck|search) color="7057ff" ;;
        esac
        
        if gh label create "$label" --color "$color" --repo "$repo" --force 2>/dev/null; then
            log "✓ Címke létrehozva: $label"
            ((created++))
        fi
        
        sleep 0.5
        
    done <<< "$labels"
    
    if [ "$created" -gt 0 ]; then
        log "Címkék létrehozva: $created"
    fi
    if [ "$existing" -gt 0 ]; then
        log "Már létező címkék: $existing"
    fi
}

# Meglévő issue-k lekérése
get_existing_github_issues() {
    local repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    gh issue list --repo "$repo" --state all --json title -q '.[].title' 2>/dev/null | \
        grep -oE 'TC-[A-Z0-9-]+' || echo ""
}

# Issue létrehozása GitHub-on
create_github_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    
    log "GitHub issue létrehozása: $title"
    
    local body_file=$(mktemp)
    echo "$body" > "$body_file"
    
    local repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    local output_file=$(mktemp)
    
    if [ -n "$labels" ]; then
        if gh issue create \
            --title "$title" \
            --body-file "$body_file" \
            --label "$labels" \
            --repo "$repo" > "$output_file" 2>&1; then
            cat "$output_file"
            rm "$body_file" "$output_file"
            return 0
        else
            if grep -q "could not add label" "$output_file"; then
                warning "Címkék nem léteznek, issue létrehozása címkék nélkül..."
                rm "$output_file"
                if gh issue create \
                    --title "$title" \
                    --body-file "$body_file" \
                    --repo "$repo" > "$output_file" 2>&1; then
                    cat "$output_file"
                    rm "$body_file" "$output_file"
                    return 0
                fi
            fi
            cat "$output_file" >&2
            rm "$body_file" "$output_file"
            return 1
        fi
    else
        if gh issue create \
            --title "$title" \
            --body-file "$body_file" \
            --repo "$repo" > "$output_file" 2>&1; then
            cat "$output_file"
            rm "$body_file" "$output_file"
            return 0
        else
            cat "$output_file" >&2
            rm "$body_file" "$output_file"
            return 1
        fi
    fi
}

# Új tesztesetek szűrése
filter_new_test_cases() {
    local all_test_ids="$1"
    local existing_issues="$2"
    local new_test_ids=""
    
    while IFS= read -r test_id; do
        if [ -z "$test_id" ]; then
            continue
        fi
        
        if echo "$existing_issues" | grep -qF "$test_id"; then
            continue
        fi
        
        new_test_ids="${new_test_ids}${test_id}\n"
        
    done <<< "$all_test_ids"
    
    echo -e "$new_test_ids" | grep -v '^$'
}

# Fő függvény
main() {
    echo "=========================================="
    echo "🧪 Nincsenek Fények! - Tesztesetek Issue Létrehozása"
    echo "=========================================="
    echo ""
    
    check_requirements
    
    log "Tesztesetek fájl: ${TEST_CASES_FILE}"
    log "CLI eszköz: ${CLI_TOOL}"
    echo ""
    
    # Címkék létrehozása
    create_github_labels
    echo ""
    
    # Teszteset ID-k kinyerése
    log "Tesztesetek keresése a dokumentációban..."
    local all_test_ids=$(extract_test_case_ids "$TEST_CASES_FILE")
    local total_count=$(echo "$all_test_ids" | grep -v '^$' | wc -l | tr -d ' ')
    
    if [ "$total_count" -eq 0 ]; then
        error "Nem található teszteset a fájlban!"
        exit 1
    fi
    
    log "Összes teszteset a dokumentációban: $total_count"
    echo ""
    
    # Meglévő issue-k lekérése
    log "Meglévő issue-k ellenőrzése..."
    local existing_issues=$(get_existing_github_issues)
    local existing_count=$(echo "$existing_issues" | grep -v '^$' | wc -l | tr -d ' ')
    log "Meglévő issue-k száma: $existing_count"
    echo ""
    
    # Új tesztesetek szűrése
    log "Új tesztesetek azonosítása..."
    local new_test_ids=$(filter_new_test_cases "$all_test_ids" "$existing_issues")
    local new_count=$(echo "$new_test_ids" | grep -v '^$' | wc -l | tr -d ' ')
    
    if [ "$new_count" -eq 0 ]; then
        log "✓ Minden teszteset már létezik GitHub-on!"
        exit 0
    fi
    
    log "Új tesztesetek száma: $new_count"
    echo ""
    
    # Megerősítés
    warning "Ez a script létre fog hozni $new_count új issue-t!"
    read -p "Folytatod? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Művelet megszakítva."
        exit 0
    fi
    
    echo ""
    log "Issue-k létrehozása..."
    echo ""
    
    local created=0
    local skipped=0
    local failed=0
    
    while IFS= read -r test_id; do
        if [ -z "$test_id" ]; then
            continue
        fi
        
        log "Feldolgozás: $test_id"
        
        local test_case_content=$(extract_test_case "$TEST_CASES_FILE" "$test_id")
        
        if [ -z "$test_case_content" ]; then
            warning "Nem található tartalom: $test_id"
            ((skipped++))
            continue
        fi
        
        local title=$(extract_title "$test_case_content")
        local body=$(generate_issue_body "$test_case_content")
        local labels=$(extract_labels "$test_case_content")
        
        if create_github_issue "$title" "$body" "$labels"; then
            ((created++))
            log "✓ Létrehozva: $test_id"
        else
            error "✗ Hiba: $test_id"
            ((failed++))
        fi
        
        sleep 1
        
    done <<< "$new_test_ids"
    
    echo ""
    echo "=========================================="
    log "Kész!"
    echo "=========================================="
    log "Összes teszteset: $total_count"
    log "Meglévő issue-k: $existing_count"
    log "Új issue-k létrehozva: $created"
    if [ "$skipped" -gt 0 ]; then
        warning "Kihagyva: $skipped"
    fi
    if [ "$failed" -gt 0 ]; then
        error "Sikertelen: $failed"
    fi
    echo ""
}

# Script futtatása
main "$@"

