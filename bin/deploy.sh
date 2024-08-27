#!/bin/bash

set -e

REVISION=$(git show-ref origin/main |cut -f 1 -d ' ')
TAGGED_IMAGE=gcr.io/${GOOGLE_PROJECT}/libraries.io:${REVISION}
gcloud --quiet container images describe ${TAGGED_IMAGE} || { status=$?; echo "Container not finished building" >&2; exit $status; }

gcloud --quiet container images add-tag ${TAGGED_IMAGE} gcr.io/${GOOGLE_PROJECT}/libraries.io:latest

kubectl run --rm=true --force --grace-period=0 --pod-running-timeout=5m -i --tty db-migration --image=${TAGGED_IMAGE} --restart=Never --overrides="`cat kube/migrate.json`"

kubectl set image deployment/libraries-sidekiq-worker-deploy libraries-sidekiq-worker=${TAGGED_IMAGE}
kubectl set image deployment/libraries-rails libraries-rails=${TAGGED_IMAGE}



