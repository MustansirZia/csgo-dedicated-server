#!/usr/bin/env bash

set -ueo pipefail

: "${CSGO_DIR:?'ERROR: CSGO_DIR IS NOT SET!'}"
: "${STEAM_DIR:?'ERROR: STEAM_DIR IS NOT SET!'}"

SOURCEMOD_CONFIG_DIR="$CSGO_DIR/csgo/addons/sourcemod/configs"
SOURCEMOD_CVAR_CONFIG_DIR="$CSGO_DIR/csgo/cfg/sourcemod"

mv $STEAM_DIR/sourcemod_configs/* $SOURCEMOD_CONFIG_DIR
rm -r $STEAM_DIR/sourcemod_configs

mv $STEAM_DIR/source_cvar_configs/* $SOURCEMOD_CVAR_CONFIG_DIR
rm -r $STEAM_DIR/source_cvar_configs