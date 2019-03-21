#!/bin/bash

set -e

REVISION=$(git show-ref origin/master |cut -f 1 -d ' ')
TAGGED_IMAGE=gcr.io/${GOOGLE_PROJECT}/libraries.io:${REVISION}
gcloud --quiet container images describe ${TAGGED_IMAGE} || exit "Container not finished building"

#gcloud --quiet container images add-tag ${TAGGED_IMAGE} gcr.io/${GOOGLE_PROJECT}/libraries.io:latest

kubectl run --rm=true -i --tty db-migration --image=${TAGGED_IMAGE} --restart=Never --overrides="`cat kube/migrate.json`"

#kubectl set image deployment/libraries-sidekiq-worker-deploy libraries-sidekiq-worker=${TAGGED_IMAGE}
#kubectl set image deployment/libraries-rails libraries-rails=${TAGGED_IMAGE}



