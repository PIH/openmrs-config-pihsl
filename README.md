# openmrs-config-pihsl

### Prerequisites

Some utility scripts — `pull.sh`, `install.sh`, and `watch.sh` — have been written to ease setting up
and updating an OpenMRS SDK server with the full PIH-EMR stack: configuration, distro, and frontend.

These scripts are designed to be friendly to **informaticians** who primarily make configuration changes
and want a working server without manually managing the distro or frontend builds. Developers working
on the distro or frontend directly can continue to use the underlying Maven and `pihemrDeploy.sh` commands.

The scripts look for sibling repositories relative to this project. Each sibling is checked under both
its `openmrs-`-prefixed and unprefixed name. Repos not found locally will be cloned from GitHub by `pull.sh`.

Expected sibling repositories:

- `openmrs-config-pihemr` (or `config-pihemr`) — **required**, the shared parent config
- `openmrs-distro-pihemr` (or `distro-pihemr`) — optional, for distro deploy
- `openmrs-frontend-pihemr` (or `frontend-pihemr`) — optional, for frontend bundle

Example directory structure:

```
openmrs-config-pihemr
openmrs-config-pihsl
openmrs-distro-pihemr
openmrs-frontend-pihemr
```

or, with unprefixed names:

```
config-pihemr
config-pihsl
distro-pihemr
frontend-pihemr
```

### Pulling the latest source

Run `./pull.sh` to update this repo and all sibling PIH-EMR repos in one step. If a sibling repo is
not present locally, it will be cloned from GitHub.

This script is optimized for low-bandwidth connections: clones are shallow and single-branch, pulls
use fetch + fast-forward-only to avoid leaving repos in a mid-rebase state if the connection drops,
and up-to-date repos skip the pull entirely. To get full history for a shallow repo later, run
`git fetch --unshallow` in it.

### Steps to deploy new changes to your local development server

Run `./install.sh [serverId]` where `[serverId]` is the name of the SDK server you are deploying to.
The script performs the following steps in order:

1. Builds the parent `openmrs-config-pihemr` (so this project picks up any changes to it)
2. Builds this `openmrs-config-pihsl` project and copies it to `~/openmrs/[serverId]/configuration`
3. Deploys the distro to the SDK server, if `openmrs-distro-pihemr` is present
4. Builds and installs the frontend bundle, if `openmrs-frontend-pihemr` is present

Steps 3 and 4 are skipped with a warning if the corresponding sibling repos are not found, so this
script can be used for config-only iteration even without the distro or frontend checked out.

#### To enable watching, you run the following:

`./watch.sh [serverId]` where `[serverId]` is the name of the SDK server you are deploying to. This
will watch _both_ the `config-pihemr` and `config-pihsl` projects for changes and redeploy when there
are changes. It runs indefinitely, so you will need to cancel it with `Ctrl-C`. Watch does not
currently rebuild the distro or frontend on changes.

### Typical workflow

For a fresh setup or after pulling in upstream changes:

```
./pull.sh                  # update all sibling repos (clones any that are missing)
./install.sh pihsl         # build and deploy config, distro, and frontend
```

For ongoing config development:

```
./watch.sh pihsl           # auto-redeploy config changes as you edit
```

### General usage

`mvn clean compile` — Will generate your configurations into `target/openmrs-packager-config/configuration`

`mvn clean package` — Will compile as above, and generate a zip package at `target/${artifactId}-${version}.zip`

In order to facilitate deploying configurations easily into an OpenMRS SDK server, one can add an additional parameter
to either of the above commands to specify that the compiled configuration should also be copied to an existing
OpenMRS SDK server:

`mvn clean compile -DserverId=pihsl` — Will compile as above, and copy the resulting configuration to `~/openmrs/pihsl/configuration`

If the configuration package you are building will be depended upon by another configuration package, you must "install" it
in order for the other package to be able to pick it up.

`mvn clean install` — Will compile and package as above, and install as an available dependency on your system

For more details regarding the available commands please see: <https://github.com/openmrs/openmrs-contrib-packager-maven-plugin>