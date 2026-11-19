#!/bin/bash
# Opens SoqlX logged in to an org that the Salesforce CLI (sf) is already
# authorized against, bypassing SoqlX's own OAuth connected app.
#
#   scripts/open-with-sf.sh <org alias or username>
#
# Useful when the org blocks SoqlX's connected app (Salesforce blocks
# uninstalled connected apps by default since September 2025).
#
# `sf org display` reports the CLI's cached access token, which is often already
# expired (the CLI only refreshes lazily when it makes an API call), so we use
# the refresh token from `sf org display --verbose` to get a fresh access token
# straight from Salesforce, exactly as the CLI itself does.
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

read -r HOST TOKEN < <(sf org display -o "$1" --verbose --json | python3 -c '
import json, sys
from urllib.parse import urlparse, urlencode
from urllib.request import urlopen, Request

r = json.load(sys.stdin)["result"]
instance = r["instanceUrl"]
token = r.get("accessToken", "")

# sfdxAuthUrl looks like force://<clientId>:<clientSecret>:<refreshToken>@<instanceHost>
auth_url = r.get("sfdxAuthUrl", "")
if auth_url.startswith("force://"):
    creds, _, host = auth_url[len("force://"):].rpartition("@")
    client_id, client_secret, refresh = creds.split(":", 2)
    form = {"grant_type": "refresh_token", "client_id": client_id or "PlatformCLI", "refresh_token": refresh}
    if client_secret:
        form["client_secret"] = client_secret
    try:
        req = Request(instance.rstrip("/") + "/services/oauth2/token", data=urlencode(form).encode(), method="POST")
        with urlopen(req, timeout=30) as resp:
            body = json.load(resp)
        token = body["access_token"]
        instance = body.get("instance_url", instance)
    except Exception as e:
        print("refresh failed, falling back to the cached token: %s" % e, file=sys.stderr)

print(urlparse(instance).hostname, token)
')

if [ -z "${HOST:-}" ] || [ -z "${TOKEN:-}" ]; then
    echo "Couldn't get a session for $1 from the Salesforce CLI" >&2
    exit 1
fi
open "soqlx://${HOST}/sid/${TOKEN}"
