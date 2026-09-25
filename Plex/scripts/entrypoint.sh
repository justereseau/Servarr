#!/bin/sh
set -e

export PLEX_MEDIA_SERVER_INFO_MODEL="$(uname -m)"
export PLEX_MEDIA_SERVER_INFO_PLATFORM_VERSION="$(uname -r)"

pref="$PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR/Plex Media Server/Preferences.xml"

if [ ! -f "$pref" ]; then
  mkdir -p "$(dirname "$pref")"
  printf '<?xml version="1.0" encoding="utf-8"?>\n<Preferences/>\n' > "$pref"
fi

set_pref() {
  if [ "$(xmlstarlet sel -t -v "count(/Preferences/@$1)" "$pref")" -gt 0 ]; then
    xmlstarlet ed -L -u "/Preferences/@$1" -v "$2" "$pref"
  else
    xmlstarlet ed -L -i /Preferences -t attr -n "$1" -v "$2" "$pref"
  fi
}

# Same env-driven preferences as the upstream pms-docker first-run script
if [ -n "$ADVERTISE_IP" ]; then set_pref customConnections "$ADVERTISE_IP"; fi
if [ -n "$ALLOWED_NETWORKS" ]; then set_pref allowedNetworks "$ALLOWED_NETWORKS"; fi
if [ "$(xmlstarlet sel -t -v "count(/Preferences/@TranscoderTempDirectory)" "$pref")" -eq 0 ]; then
  set_pref TranscoderTempDirectory /transcode
fi

exec "$PLEX_MEDIA_SERVER_HOME/Plex Media Server"
