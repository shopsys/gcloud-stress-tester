#! /bin/bash -ex

./src/variable_validator.sh

gcloud auth activate-service-account --key-file /tmp/infrastructure/google-cloud/service-account.json

# Set project by ID into gcloud config
gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

gcloud compute instances create \
    ${INSTANCE_NAME} \
    --machine-type=n1-standard-4 \
    --boot-disk-size=100GB \
    --image-family=ubuntu-minimal-1804-lts \
    --image-project=ubuntu-os-cloud

gcloud compute ssh ${SERVICE_ACCOUNT_LOGIN}@${INSTANCE_NAME} \
    --command="sudo apt-get update -y &&
        sudo apt-get -f install -y &&
        sudo apt-get autoremove -y &&
        sudo apt-get install curl git software-properties-common -y &&
        sudo apt-get update -y &&
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
        sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable' &&
        sudo apt-get update -y &&
        sudo apt-get install docker docker-compose -y &&
        sudo usermod -aG docker ${SERVICE_ACCOUNT_LOGIN} &&
        git clone https://github.com/shopsys/shopsys.git &&
        cd shopsys &&
        git checkout ${GIT_BRANCH}"

# Save IP address to file to be available outside of container for running gatling
EXTERNAL_IP=$(gcloud compute instances describe ${INSTANCE_NAME} --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo ${EXTERNAL_IP} > /code/build-${BUILD_NUMBER}/ip-address

# These seds are required for older versions of Shopsys which was not prepared for automated installing (fixing user rights and allocating a pseudo TTY)
gcloud compute ssh ${SERVICE_ACCOUNT_LOGIN}@${INSTANCE_NAME} \
    --command='cd shopsys/project-base &&
        sed -i -r "s#www_data_uid: [0-9]+#www_data_uid: $(id -u)#" docker/conf/docker-compose.yml.dist &&
        sed -i -r "s#www_data_gid: [0-9]+#www_data_gid: $(id -g)#" docker/conf/docker-compose.yml.dist &&
        sed -i -r "s#docker-compose exec php-fpm#docker-compose exec -T php-fpm#" ./scripts/install.sh &&
        echo 1 | ./scripts/install.sh'

gcloud compute ssh ${SERVICE_ACCOUNT_LOGIN}@${INSTANCE_NAME} \
    --command="cd shopsys/project-base &&
        sed -i -r \"s#127\.0\.0\.1#${EXTERNAL_IP}#\" ./app/config/domains_urls.yml &&
        docker-compose exec -T php-fpm php phing test-db-performance &&
        sed -i -r \"s#database_name: shopsys#database_name: shopsys-test#g\" ./app/config/parameters.yml &&
        docker-compose exec -T php-fpm bin/console shopsys:environment:change prod &&
        docker-compose exec -T php-fpm php phing clean"
