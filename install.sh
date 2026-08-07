#!/bin/bash
# Installs the PIH-EMR config, distro, and frontend to an OpenMRS SDK server.
#
# Order matters: config is built first (since the distro depends on it via
# Maven), the distro is then deployed to the server (which sets up the SDK
# instance), and finally the frontend bundle is built and copied into the
# server's frontend/ directory.
#
# The distro deploy command is inlined here rather than calling the distro's
# pihemrDeploy.sh, to avoid a duplicate git pull (use the update script for
# pulling). The frontend's install.sh is called directly since it does the
# build/copy work we'd otherwise have to duplicate.
#
# Sibling repos are looked up relative to this project. Each is checked for
# both "openmrs-"-prefixed and unprefixed directory names.
 
set -e
 
usage () {
    echo -e "Usage: install.sh [SERVER]\n"
    echo -e "Installs the configuration, distro, and frontend to SERVER, where SERVER is the"
    echo -e "name of an OpenMRS SDK instance at path '~/openmrs/[SERVER]'.\n"
    echo -e "Also first installs the parent config if it is at ../openmrs-config-pihemr or ../config-pihemr,"
    echo -e "then deploys the distro and runs the frontend's install.sh if those repos are present.\n"
    echo -e "Example: ./install.sh mirebalais\n"
}
 
if [ $# -eq 0 ]; then
    echo -e "Please provide the name of the server to install to as a command line argument.\n"
    usage
    exit 1
fi
 
SERVER=$1
 
# Step 1: build the parent config (this project's parent), if present
if [[ -d '../openmrs-config-pihemr' ]]; then
    echo "Building openmrs-config-pihemr..."
    (cd ../openmrs-config-pihemr && mvn clean install)
elif [[ -d '../config-pihemr' ]]; then
    echo "Building config-pihemr..."
    (cd ../config-pihemr && mvn clean install)
else
    echo "Unable to find PIH-EMR config, skipping building it"
fi
 
# Step 2: compile this config and copy to the server
echo "Compiling this config for server '$SERVER'..."
mvn clean compile -pl '!content' -DserverId="$SERVER"
 
# Step 3: deploy the distro, if present.
# Inlines the deploy command from the distro's pihemrDeploy.sh to avoid a
# duplicate git pull (the update script already handles pulling).
if [[ -d '../openmrs-distro-pihemr' ]]; then
    DISTRO_DIR='../openmrs-distro-pihemr'
elif [[ -d '../distro-pihemr' ]]; then
    DISTRO_DIR='../distro-pihemr'
else
    DISTRO_DIR=''
fi
 
if [[ -n "$DISTRO_DIR" ]]; then
    echo "Deploying distro from $DISTRO_DIR to server '$SERVER'..."
    (cd "$DISTRO_DIR" && mvn openmrs-sdk:deploy -Ddistro=openmrs-distro.properties -DserverId="$SERVER" -U)
else
    echo "Unable to find PIH-EMR distro, skipping distro deploy"
fi
 
# Step 4: build and install the frontend bundle, if present
if [[ -d '../openmrs-frontend-pihemr' ]]; then
    FRONTEND_DIR='../openmrs-frontend-pihemr'
elif [[ -d '../frontend-pihemr' ]]; then
    FRONTEND_DIR='../frontend-pihemr'
else
    FRONTEND_DIR=''
fi
 
if [[ -n "$FRONTEND_DIR" ]]; then
    if [[ -x "$FRONTEND_DIR/install.sh" ]]; then
        echo "Running frontend install.sh for server '$SERVER'..."
        (cd "$FRONTEND_DIR" && ./install.sh "$SERVER")
    else
        echo "WARNING: $FRONTEND_DIR/install.sh not found or not executable, skipping frontend install"
    fi
else
    echo "Unable to find PIH-EMR frontend, skipping frontend install"
fi
 
echo "Done."
