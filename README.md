# GCP SSFW Deployer

Internal package. Designed to automated deploying SSFW in GCP for stress testing.

Scripts for easy managing GCP.
Creates a single virtual machine and run SSFW via docker-compose.
Huge amount of data are loaded into in and production environment is set.
Whole instance might be easily deleted as well.  

## Usage
### Deploying a new instance

```bash
docker run \
    -e PROJECT_ID \
    -e GOOGLE_CLOUD_ZONE \
    -e INSTANCE_NAME \
    -e SERVICE_ACCOUNT_LOGIN \
    -e GIT_BRANCH \
    -e BUILD_NUMBER \
    -v <<path/to/your/srvice-account.json>>:/tmp/infrastructure/google-cloud/service-account.json \
    -v "${WORKSPACE}/build-${BUILD_NUMBER}/":"/code/build-${BUILD_NUMBER}/" \
    -v "${WORKSPACE}/src":/src \
    --rm \
    google/cloud-sdk:slim \
    /src/deployer.sh
```

#### ENV variable explanation:

- `PROJECT_ID` - Google Cloud Project ID
- `GOOGLE_CLOUD_ZONE` - Google Cloud Zone 
- `INSTANCE_NAME` - VM instance name in Google Cloud (it is recommended to be unique to prevent conflicts)
- `SERVICE_ACCOUNT_LOGIN` - Google Cloud service account username 
- `GIT_BRANCH` - Specify the branch you want to put under the stress
- `BUILD_NUMBER` - Number of current build
- `WORKSPACE` - Current workdir

### Removing an existing instance

```bash
docker run \
    -e PROJECT_ID \
    -e GOOGLE_CLOUD_ZONE \
    -e INSTANCE_NAME \
    -v <<path/to/your/srvice-account.json>>:/tmp/infrastructure/google-cloud/service-account.json \
    -v "${WORKSPACE}/src":/src \
    --rm \
    google/cloud-sdk:slim \
    /src/destroyer.sh 
```
