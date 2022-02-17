#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-17 11:32:45 +0000 (Thu, 17 Feb 2022)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Merges one branch into another in the current or given repo, creating and merging Pull Requests for full audit tracking all changes

Useful Git terminology reminder:

The HEAD branch is the branch you want to merge FROM, eg. 'my-feature-branch'
The BASE branch is the branch you want to merge INTO, eg. 'master' or 'main'

One very good use case for this script, aside from just quickly PR and merge from your branch,
is to use in automation to automatically backport changes such as hotfixes from higher environments
such as Staging or Production branches back into your main trunk branch such as master, main, dev or develop branches

Requires GitHub CLI to be installed and configured

Depends on adjacent script:

    github_create_pull_request.sh

Used by adjacent script:

    github_repo_fork_update.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner>/<repo>] <from_head_branch> <to_base_branch>"

help_usage "$@"

min_args 2 "$@"
max_args 3 "$@"

output="$("$srcdir/github_create_pull_request.sh" "$@")"

if [ -n "$output" ]; then
    pr_url="$(grep '/pull/' <<< "$output" || die "Failed to generate Pull Request or couldn't find pull URL in output")"
    timestamp "Merging Pull Request $pr_url"
    gh pr merge --merge "$pr_url"
    echo >&2
fi
