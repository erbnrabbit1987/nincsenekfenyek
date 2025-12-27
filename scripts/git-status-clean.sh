#!/bin/bash

##############################################################################
# Clean Git Status
# Git status hibák nélkül
##############################################################################

# Suppress problematic shell variables
export ZSH_PROMPT_COMMAND=""
export ZSH_DUMP_STATE=""

# Run git status and filter errors
command git status "$@" 2>&1 | grep -v "base64.*Operation not permitted" | grep -v "dump_zsh_state" | grep -v "command not found: dump_zsh_state" | cat

