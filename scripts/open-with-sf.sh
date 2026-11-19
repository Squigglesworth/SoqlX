#!/bin/bash
# Opens SoqlX logged in to an org that the Salesforce CLI (sf) is already
# authorized against, bypassing SoqlX's own OAuth connected app.
#
#   scripts/open-with-sf.sh <org alias or username>
#
# Useful when the org blocks SoqlX's connected app (Salesforce blocks
# uninstalled connected apps by default since September 2025). The CLI's
# access token is a real API session, so it works where a browser sid cookie
# won't. Requires: sf org login web -a <alias>
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: $0 <sf org alias or username>" >&2
    exit 2
fi
if ! command -v sf >/dev/null 2>&1; then
    echo "The Salesforce CLI (sf) is not installed. See https://developer.salesforce.com/tools/salesforcecli" >&2
    exit 1
fi

read -r HOST TOKEN < <(sf org display -o "$1" --json | python3 -c '
import json, sys
from urllib.parse import urlparse
r = json.load(sys.stdin)["result"]
print(urlparse(r["instanceUrl"]).hostname, r["accessToken"])
')

open "soqlx://${HOST}/sid/${TOKEN}"
