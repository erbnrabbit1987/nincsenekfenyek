#!/bin/bash

##############################################################################
# Git Wrapper Script
# Elnyomja a shell hibákat (base64, dump_zsh_state) Git parancsokhoz
##############################################################################

# Elnyomjuk a hibákat a shell konfigból
exec 2> >(grep -v "base64.*Operation not permitted" | grep -v "dump_zsh_state" | grep -v "command not found: dump_zsh_state")

# Futtatjuk a git parancsot
git "$@"


