#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest-cli-credential hari mypassword
#
#  Author: Hari Sekhon
#  Date: 2022-06-28 18:34:34 +0100 (Tue, 28 Jun 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a Jenkins credential in the given credential store and domain

Defaults to the 'system::system::jenkins' provider store and global domain '_'

If credential, user and password aren't given as arguments, then reads from stdin, reading in KEY=VALUE
or standard shell export format - useful for piping from tools like aws_csv_creds.sh

In cases where you are reading secrets from stdin, you can set the store and domain via the environment variables
\$JENKINS_SECRET_STORE and \$JENKINS_SECRET_DOMAIN

Uses the adjacent jenkins_cli.sh - see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<credential_id> <user> <password> <store> <domain> <description>]"

help_usage "$@"

id="${1:-}"
user="${2:-}"
password="${3:-}"
store="${4:-${JENKINS_SECRET_STORE:-system::system::jenkins}}"
domain="${5:-${JENKINS_SECRET_DOMAIN:-_}}"
description="${6:-}"

create_credential(){
    local id="$1"
    local key_value="$2"
    parse_export_key_value "$key_value"
    # key/value are exported by above function
    # shellcheck disable=SC2154
    local user="$key"
    # shellcheck disable=SC2154
    local password="$value"
    local domain_name="$domain"
    if [ "$domain_name" = '_' ]; then
        domain_name='GLOBAL'
    fi
    xml="<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>$domain_name</scope>
  <id>$id</id>
  <description>$description</description>
  <username>$user</username>
  <password>$password</password>
  <usernameSecret>false</usernameSecret>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>"
    timestamp "Creating Jenkins username/password secret '$id' in store '$store' domain '$domain_name'"
    "$srcdir/jenkins_cli.sh" create-credentials-by-xml "$store" "$domain" <<< "$xml"
    timestamp "Secret '$id' created"
}

if [ -n "$password" ]; then
    create_credential "$id" "$user"="$password"
else
    while read -r id user_password; do
        if [ -z "${user_password:-}" ] && [[ "$id" =~ = ]]; then
            user_password="$id"
            id="${id%%=*}"
            id="$(tr '[:upper:]' '[:lower:]' <<< "$id")"
        else
            timestamp "WARNING: invalid line detected, skipping creating credential"
            continue
        fi
        create_credential "$id" "$user_password"
    done < <(sed 's/^[[:space:]]*export[[:space:]]*//; /^[[:space:]]*$/d')
fi
