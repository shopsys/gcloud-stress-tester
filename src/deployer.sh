#! /bin/bash -ex

# Validate required ENV variables
./src/variable_validator.sh

gcloud auth activate-service-account --key-file /tmp/infrastructure/google-cloud/service-account.json

# Set project by ID into gcloud config
gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

gcloud compute instances create \
    ${INSTANCE_NAME} \
    --machine-type=n1-standard-4 \
    --boot-disk-size=100GB \
    --image-family=debian-10 \
    --image-project=debian-cloud

gcloud compute ssh ${SERVICE_ACCOUNT_LOGIN}@${INSTANCE_NAME} \
    --command="sudo apt-get update -y &&
        sudo apt-get install git software-properties-common -y &&
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - &&
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
    --command='cd shopsys &&
        sed -i -r "s#www_data_uid: [0-9]+#www_data_uid: $(id -u)#" docker/conf/docker-compose.yml.dist &&
        sed -i -r "s#www_data_gid: [0-9]+#www_data_gid: $(id -g)#" docker/conf/docker-compose.yml.dist &&
        sed -i -r "s#docker-compose exec php-fpm#docker-compose exec -T php-fpm#" ./project-base/scripts/install.sh &&
        echo 1 | ./project-base/scripts/install.sh'

if gcloud compute ssh ${SERVICE_ACCOUNT_LOGIN}@${INSTANCE_NAME} --command="test -d shopsys/project-base/app/config"; then
    CONFIG_PATH='project-base/app/config'
else
    CONFIG_PATH='project-base/config'
fi

gcloud compute ssh ${SERVICE_ACCOUNT_LOGIN}@${INSTANCE_NAME} \
    --command="cd shopsys &&
        sed -i -r \"s#127\.0\.0\.1#${EXTERNAL_IP}#\" ./${CONFIG_PATH}/domains_urls.yaml &&
        docker-compose exec -T php-fpm php phing test-db-performance &&
        sed -i -r \"s#database_name: shopsys#database_name: shopsys-test#g\" ./${CONFIG_PATH}/parameters.yaml &&
        docker-compose exec -T php-fpm bin/console shopsys:environment:change prod &&
        docker-compose exec -T php-fpm php phing clean"
