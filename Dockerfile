FROM ubuntu:18.04

RUN apt update -y
RUN apt install \
	curl \
	gnupg2 \
	openssh-client \
	-y

# Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y	

WORKDIR /code
COPY src/deployer.sh deployer.sh
COPY src/destroyer.sh destroyer.sh
