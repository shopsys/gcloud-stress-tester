#! /bin/bash

gcloud auth activate-service-account --key-file /tmp/infrastructure/google-cloud/service-account.json

# Set project by ID into gcloud config
gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

gcloud compute instances delete ${INSTANCE_NAME} -q
