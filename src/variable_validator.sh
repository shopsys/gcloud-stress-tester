#! /bin/bash -ex

RED="\e[31m"
NC="\e[0m"

if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}Google Cloud Project ID has not been provided (in \$PROJECT_ID environment variable)!${NC}"
    exit 1
fi

if [[ -z "$GOOGLE_CLOUD_ZONE" ]]; then
    echo -e "${RED}Google Cloud Zone URL has not been provided (in \$GOOGLE_CLOUD_ZONE environment variable)!${NC}"
    exit 1
fi

if [[ -z "$INSTANCE_NAME" ]]; then
    echo -e "${RED}Instance Name for VM has not been provided (in \$INSTANCE_NAME environment variable)!${NC}"
    exit 1
fi

if [[ -z "$SERVICE_ACCOUNT_LOGIN" ]]; then
    echo -e "${RED}Google Cloud Login has not been provided (in \$SERVICE_ACCOUNT_LOGIN environment variable)!${NC}"
    exit 1
fi

if [[ -z "$GIT_BRANCH" ]]; then
    echo -e "${RED}Git branch has not been provided (in \$GIT_BRANCH environment variable)!${NC}"
    exit 1
fi

if [[ -z "$BUILD_NUMBER" ]]; then
    echo -e "${RED}Build number has not been provided (in \$BUILD_NUMBER environment variable)!${NC}"
    exit 1
fi
