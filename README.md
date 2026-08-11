# PIH Sierra Leone EMR Distribution

This repository defines the OpenMRS distribution for PIH Sierra Leone. It packages together the [PIH EMR](https://github.com/PIH/openmrs-distro-pihemr) parent distribution,
Sierra Leone-specific content, and the PIH EMR frontend into a single deployable artifact.
For more background on OpenMRS distributions, see the [OpenMRS wiki](https://wiki.openmrs.org/display/docs/OpenMRS+Distributions).

## Repository Structure

| Directory | Description |
|---|---|
| [`content/`](content/README.md) | Sierra Leone-specific OpenMRS content package (Initializer configuration files) |
| [`distro/`](distro/README.md) | Distribution definition — resolves all component versions into `openmrs-distro.properties` |

## Components

| Component | Artifact |
|---|---|
| PIH EMR parent distro | `org.openmrs.distro:pihemr` |
| PIH EMR shared content | `org.pih.openmrs:pihemr-content` |
| Sierra Leone content | `org.pih.openmrs:pihsl-content` |
| PIH EMR frontend | `org.pih.openmrs:openmrs-frontend-pihemr` |

Component versions are defined in `distro/pom.xml` and resolved into `distro/openmrs-distro.properties` at build time.

## Supported Configuration Profiles

| Site | PIH Config |
|---|---|
| `kgh` | `sierraLeone,sierraLeone-kgh` |
| `wellbody` | `sierraLeone,sierraLeone-wellbody` |
| `kgh-test` | `sierraLeone,sierraLeone-kgh,sierraLeone-kgh-test` |
| `gladi` | `sierraLeone,sierraLeone-wellbody,sierraLeone-wellbody-gladi` |

## Developer Guide

Local development runs through the shared
[`openmrs-contrib-distro-tools`](https://github.com/PIH/openmrs-contrib-distro-tools) CLI
(`openmrs-docker`/`openmrs-sdk`), installed once per machine rather than embedded in this repo.
Follow that repo's [Install](https://github.com/PIH/openmrs-contrib-distro-tools#install) section first — the commands below assume `openmrs-docker`/`openmrs-sdk` are already on your `PATH`.

### Docker (`openmrs-docker`)

For each supported configuration profile, an example environment file is provided in the repo root to get started quickly.
Because this file is found in the distribution repository, it is assumed that this is checked out on your machine, and
that `openmrs-docker` commands are running from the root of the distribution repository — it sets `DISTRO_SOURCE_DIR`
to this location. If you're using it as an example for running elsewhere, you may need to change or remove that.

To use the example environment file for `kgh` to get up and running with a new instance:

```bash
source kgh.env
openmrs-docker create kgh
openmrs-docker kgh initialize # Optional, but speeds up initial startup
openmrs-docker kgh start
openmrs-docker kgh wait  # Tails logs until OpenMRS is ready, then exits
```

Once created, day-to-day commands only need the instance name:

```bash
openmrs-docker kgh stop
openmrs-docker kgh logs
openmrs-docker kgh destroy
```

The same pattern applies to `wellbody.env`, `kgh-test.env`, and `gladi.env` — substitute the instance name accordingly.

### OpenMRS SDK (`openmrs-sdk`)

Use `openmrs-sdk` to run a site using the [OpenMRS SDK](https://wiki.openmrs.org/display/docs/OpenMRS+SDK), which sets up a local Tomcat server with its own MySQL instance.

```
openmrs-sdk <command> <server-id>
```

**Example — first-time setup:**
```bash
PIH_CONFIG=sierraLeone,sierraLeone-kgh openmrs-sdk create pihsl
openmrs-sdk run pihsl
```

**Example — after updating component versions:**
```bash
openmrs-sdk update pihsl
openmrs-sdk run pihsl
```

## CI and Publishing

CI is handled by GitHub Actions. On every push to `master`, the [Build and deploy](.github/workflows/build-and-deploy.yml) workflow:

1. Builds and publishes the Maven artifact to [Maven Central](https://central.sonatype.com/artifact/org.pih.openmrs/pihsl-distro) as `org.pih.openmrs:pihsl-distro`.
2. Builds and pushes a multi-platform Docker image (amd64 + arm64) to Docker Hub at [`partnersinhealth/pihsl-emr`](https://hub.docker.com/r/partnersinhealth/pihsl-emr), tagged with both `latest` and the Maven project version.
3. Fires the existing Bamboo `kgh-test` and `gladi` deploy triggers, exactly as the legacy `deploy.yml` workflow did.

A separate [Build seeded images](.github/workflows/build-seeded-images.yml) workflow runs nightly and publishes pre-initialized seed images to Docker Hub for all four sites (`partnersinhealth/pihsl-emr-seed-kgh`, `-seed-wellbody`, `-seed-kgh-test`, `-seed-gladi`).

A separate [Update Versions](.github/workflows/update-versions.yml) workflow runs hourly and automatically commits any available snapshot dependency updates to `master`.
