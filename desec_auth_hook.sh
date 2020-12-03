#!/bin/bash

# This script is to be used as certbot pre-validation hook when run in manual
# mode to validate domains by DNS challenge via deSEC.
#
# See:
# https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks
# https://desec.readthedocs.io/en/latest/dyndns/lets-encrypt.html
#
# It is based upon the script provided by Peter Thomassen and Nils Wisiol to
# allow dedyn.io DNS challenge validation:
# https://github.com/desec-utils/certbot-hook

# Set DEBUG=1 for additional output
DEBUG=

# Check if this script is run from certbot, i.e. if CERTBOT_DOMAIN is set
[ -z "$CERTBOT_DOMAIN" ] && echo -e "\e[31m\$CERTBOT_DOMAIN is unset!\e[0m Run this script from certbot with --manual-auth-hook=$(realpath $0)" >&2 && exit 1

[[ $DEBUG ]] && echo "\$CERTBOT_DOMAIN = $CERTBOT_DOMAIN"

# Check if the file CERTBOT_DOMAIN.desecauth exists, which should contain the
# deSEC authorization token for the current domain as DESEC_TOKEN
DESECAUTH="$(dirname $0)/$CERTBOT_DOMAIN.desecauth"
[ ! -f "$DESECAUTH" ] && echo -e "\e[31mFile $DESECAUTH not found!\e[0m" && exit 2
. "$DESECAUTH"

# Read the file desec.conf, which contains some variables for further process
DESECCONF="$(dirname $0)/desec.conf"
[ ! -f "$DESECCONF" ] && echo -e "\e[31mFile $DESECCONF not found!\e[0m" && exit 3
. "$DESECCONF"

# Only proceed if curl and jq are found
[ -z "$CURL_BIN" ] && >&2 echo "Please install curl to use certbot with desec.de!" && exit 4
[ -z "$JQ_BIN" ] && >&2 echo "Please install jq to use certbot with desec.de!" && exit 5

echo "Setting challenge to ${CERTBOT_VALIDATION} ..."

# Prepend "_acme-challenge." or whatever is in variable ACME_PREFIX to the domain
DOMAIN="${ACME_PREFIX}.${CERTBOT_DOMAIN}"

[[ $DEBUG ]] && echo "\$DOMAIN = $DOMAIN"

# If TTL not set, find minimum_ttl for the domain and use this
[ -z "$TTL" ] && TTL=$($CURL_BIN "${CURL_ARGS[@]}" -X GET "$DESEC_API_URL/$CERTBOT_DOMAIN/" | $JQ_BIN -j '.minimum_ttl')

[[ $DEBUG ]] && echo "\$TTL = $TTL"

# Fetch and parse the current rrset for manipulation below
ACME_RECORDS=$($CURL_BIN "${CURL_ARGS[@]}" -X GET "$DESEC_API_URL/$CERTBOT_DOMAIN/rrsets/?subname=$ACME_PREFIX&type=TXT" | $JQ_BIN '.[].records[]' | paste -s -d ",")

[[ $DEBUG ]] && echo "\$ACME_RECORDS = $ACME_RECORDS (fetched from provider)"

# If the current rrset is empty, we simply publish the new challenge. If the
# current rrset contains records and we have a new challenge, we append the new
# challenge to the current rrset. If for some reason the new challenge is
# already in the rrset, we re-publish the current rrset as-is.
if [ -z "$ACME_RECORDS" ]; then
  ACME_RECORDS='"\"'"$CERTBOT_VALIDATION"'\""'
elif [[ ! $ACME_RECORDS =~ "$CERTBOT_VALIDATION" ]]; then
  ACME_RECORDS+=',"\"'"$CERTBOT_VALIDATION"'\""'
fi

[[ $DEBUG ]] && echo "\$ACME_RECORDS = $ACME_RECORDS (after manipulation)"

# Set ACME challenge (overwrite if possible, create otherwise)
$CURL_BIN "${CURL_ARGS[@]}" -X PUT -o /dev/null "$DESEC_API_URL/$CERTBOT_DOMAIN/rrsets/" '-d [{"subname":"'"$ACME_PREFIX"'", "type":"TXT", "records":['"$ACME_RECORDS"'], "ttl":'"$TTL"'}]'

echo "Waiting ${SLEEP}s for changes to be published" && sleep $SLEEP

echo -e '\e[32mToken published. Returning to certbot\e[0m'
