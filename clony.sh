#!/usr/bin/env bash

#Author: Costin Galan | cgalan@cloudbasesolutions.com
#License: Apache2.0 | https://www.apache.org/licenses/LICENSE-2.0
#Description: Script for cloning your repositories and add the original
#             parent fork

set -euo pipefail

#In order to not trigger the rate limiting on the Github API
# we will use authentificated requests
source github_oauth_token.txt

if [[ $# -lt 2 ]]; then
    echo "Not enough parameters"
    echo "Usage: ./$0 username directory"
    exit 1
fi

function find_father {
    for directory in "${2}"/*; do
        if [[ -d $directory ]]; then
            pushd "$directory"
            repo=$(basename "$directory")
            set +e
            author=$(curl -s -H "Authorization: token $GITHUB_OAUTH_TOKEN" https://api.github.com/repos/"${1}"/"${repo}" | grep -A5 parent | grep login | cut -d'"' -f4)
            set -e
            if [[ -n $author ]]; then
                git remote add "$author" https://github.com/"${author}"/"${repo}"
            fi
            popd
            sleep 1
        fi
    done
}

function clone_repos {
    mkdir -p "$2"
    pushd "$2"
    index=1
    repo=$(curl -s -H "Authorization: token $GITHUB_OAUTH_TOKEN" https://api.github.com/users/"${1}"/repos\?page\=${index}\&per_page\=1 | grep git_url | cut -f4 -d'"')
    while [[ -n $repo ]]; do
        ((index++))
        git clone "$repo"
        sleep 1
        set +e
        repo=$(curl -s -H "Authorization: token $GITHUB_OAUTH_TOKEN" https://api.github.com/users/"${1}"/repos\?page\=${index}\&per_page\=1 | grep git_url | cut -f4 -d'"')
        set -e
    done
    popd
}

function update_repos {
    for directory in "${1}"/*; do
        if [[ -d $directory ]]; then
            pushd "$directory"
            git fetch --all
            upstream=$(git remote -v | grep -v origin | awk '{print $1}' | uniq)
            branch=$(git branch | grep '*' | awk '{print $2}')
            git pull "$upstream" "$branch"
            git push origin "$branch"
            popd
        fi
    done
}

clone_repos "$1" "$2" && find_father "$1" "$2" && update_repos "$2"
