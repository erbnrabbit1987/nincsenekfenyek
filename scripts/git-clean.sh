#!/bin/bash

##############################################################################
# Clean Git Commands for Cursor
# Elnyomja a shell hibákat és futtatja a git parancsot
##############################################################################

# Suppress problematic shell variables
export ZSH_PROMPT_COMMAND=""
export ZSH_DUMP_STATE=""

# Run git and filter errors
command git "$@" 2>&1 | grep -v "base64.*Operation not permitted" | grep -v "dump_zsh_state" | grep -v "command not found: dump_zsh_state" | cat

