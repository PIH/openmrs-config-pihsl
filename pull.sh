#!/bin/bash
# Updates this repo and related PIH-EMR sibling repos in the parent directory.
# If a sibling repo is not found locally, it will be cloned from GitHub.
# Repos are checked for both "openmrs-"-prefixed and unprefixed directory names.
#
# Optimized for low-bandwidth connections:
#   - Clones are shallow (--depth=1) and single-branch to minimize transfer size
#   - Pulls use fetch + fast-forward-only to avoid mid-rebase state on dropped connections
#   - Up-to-date repos are detected via SHA comparison and skip the pull entirely
# To get full history for a shallow repo later, run 'git fetch --unshallow' in it.
 
set -e
 
# Helper to update a repo using fetch + fast-forward-only pull.
# Avoids leaving the repo in a mid-rebase state if the connection drops,
# and skips the pull entirely when already up to date (saves a round trip).
pull_ff_only() {
    local dir=$1
    if ! (cd "$dir" && git fetch --progress); then
        echo "ERROR: git fetch failed in $dir. Check network connection."
        exit 1
    fi
    # Skip pull if local HEAD already matches remote tracking branch
    local local_sha remote_sha
    local_sha=$(cd "$dir" && git rev-parse HEAD)
    remote_sha=$(cd "$dir" && git rev-parse '@{u}' 2>/dev/null || echo "")
    if [[ -n "$remote_sha" && "$local_sha" == "$remote_sha" ]]; then
        echo "  Already up to date."
        return
    fi
    if ! (cd "$dir" && git pull --rebase --ff-only); then
        echo "ERROR: git pull --ff-only failed in $dir."
        echo "       The local branch has diverged from remote and cannot fast-forward."
        echo "       Resolve manually in that directory (e.g. 'git rebase' or 'git reset')."
        exit 1
    fi
}
 
# Helper to clone a repo with bandwidth-saving options (shallow, single branch).
# History is not fetched - run 'git fetch --unshallow' later if full history is needed.
shallow_clone() {
    local url=$1
    (cd .. && git clone --depth=1 --single-branch --progress "$url")
}
 
# Update openmrs-config-pihemr
echo "Updating openmrs-config-pihemr..."
if [[ -d '../openmrs-config-pihemr' ]]; then
    pull_ff_only ../openmrs-config-pihemr
elif [[ -d '../config-pihemr' ]]; then
    pull_ff_only ../config-pihemr
else
    echo "Unable to find openmrs-config-pihemr, cloning from GitHub..."
    shallow_clone https://github.com/PIH/openmrs-config-pihemr.git
fi
 
# Update openmrs-distro-pihemr
echo "Updating openmrs-distro-pihemr..."
if [[ -d '../openmrs-distro-pihemr' ]]; then
    pull_ff_only ../openmrs-distro-pihemr
elif [[ -d '../distro-pihemr' ]]; then
    pull_ff_only ../distro-pihemr
else
    echo "Unable to find openmrs-distro-pihemr, cloning from GitHub..."
    shallow_clone https://github.com/PIH/openmrs-distro-pihemr.git
fi
 
# Update openmrs-frontend-pihemr
echo "Updating openmrs-frontend-pihemr..."
if [[ -d '../openmrs-frontend-pihemr' ]]; then
    pull_ff_only ../openmrs-frontend-pihemr
elif [[ -d '../frontend-pihemr' ]]; then
    pull_ff_only ../frontend-pihemr
else
    echo "Unable to find openmrs-frontend-pihemr, cloning from GitHub..."
    shallow_clone https://github.com/PIH/openmrs-frontend-pihemr.git
fi
 
# Update this repo
echo "Updating this repo..."
pull_ff_only .
