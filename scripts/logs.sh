#!/bin/bash

# Nincsenek Fények! - View Logs Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SERVICE=""
FOLLOW=false
LINES=100

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        *)
            SERVICE="$1"
            shift
            ;;
    esac
done

cd "$PROJECT_ROOT"

if [ "$FOLLOW" = true ]; then
    if [ -n "$SERVICE" ]; then
        docker-compose logs -f "$SERVICE"
    else
        docker-compose logs -f
    fi
else
    if [ -n "$SERVICE" ]; then
        docker-compose logs --tail="$LINES" "$SERVICE"
    else
        docker-compose logs --tail="$LINES"
    fi
fi


