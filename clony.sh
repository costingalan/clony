#!/usr/bin/env bash

#Author: Costin Galan | cgalan@cloudbasesolutions.com
#License: Apache2.0 | https://www.apache.org/licenses/LICENSE-2.0
#Description: Script for cloning your repositories and add the original
#             parent fork

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: ./$0 username directory"
    exit 1
fi

function find_father () {
    for directory in $1; do
        if [[ -d "$directory" ]]; then
            pushd "$directory"
            author=$(curl -i https://api.github.com/repos/${1}/${directory} | grep -A5 parent | grep login | cut -d'"' -f4)
            git remote add $author https://github.com/${author}/${directory}
            popd
        fi
    done
}

function clone_repos () {
    pushd $2
    repos=$(curl -i https://api.github.com/users/${1}/repos\?page\=1\&per_page\=100 | grep git_url | cut -f4 -d'"')
    IFS=' ' read -a final_repos <<< $repos
    number_repos=$(curl -i https://api.github.com/users/${1}/repos\?page\=1\&per_page\=100 | grep git_url | cut -f4 -d'"' | wc -l)
    for repo in "${final_repos[@]}"; do
        git clone $repo
    done
    popd
}

clone_repos $1 $2 && find_father $1 $2 && echo "Success!"

USERNAME=$1
DIRECTORY=$2

