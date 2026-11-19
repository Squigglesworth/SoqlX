#!/bin/bash
# Opens SoqlX logged in to an org that the Salesforce CLI (sf) is already
# authorized against, bypassing SoqlX's own OAuth connected app.
#
#   scripts/open-with-sf.sh <org alias or username>
#
# Useful when the org blocks SoqlX's connected app (Salesforce blocks
# uninstalled connected apps by default since September 2025).
#
# Note: `sf org display` reports the CLI's cached access token, which is often
# already expired (the CLI refreshes it lazily when it makes an API call). So we
# ask for the "open in browser" URL instead: the CLI refreshes the token to
# build that URL, and the sid parameter in it is the live access token.
# Requires: sf org login web -a <alias>
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: $0 <sf org alias or username>" >&2
    exit 2
fi
if ! command -v sf >/dev/null 2>&1; then
    echo "The Salesforce CLI (sf) is not installed. See https://developer.salesforce.com/tools/salesforcecli" >&2
    exit 1
fi

read -r HOST TOKEN < <(sf org open -o "$1" --url-only --json | python3 -c '
import json, sys
from urllib.parse import urlparse, parse_qs
u = urlparse(json.load(sys.stdin)["result"]["url"])
print(u.hostname, parse_qs(u.query)["sid"][0])
')

if [ -z "${HOST:-}" ] || [ -z "${TOKEN:-}" ]; then
    echo "Couldn't get a session for $1 from the Salesforce CLI" >&2
    exit 1
fi
open "soqlx://${HOST}/sid/${TOKEN}"
