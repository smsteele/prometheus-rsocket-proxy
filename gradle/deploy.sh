#!/bin/bash
# This script will deploy the project artifacts.

SWITCHES="-s --console=plain"

if [ $CIRCLE_PR_NUMBER ]; then
  echo -e "WARN: Should not be here => Found Pull Request #$CIRCLE_PR_NUMBER => Branch [$CIRCLE_BRANCH]"
  echo -e "Not attempting to publish"
elif [ -z $CIRCLE_TAG ]; then
  echo -e "Publishing Snapshot => Branch ['$CIRCLE_BRANCH']"
  openssl enc -d -aes-256-cbc -md sha512 -pbkdf2 -iter 1000 -in gradle.properties.enc -out gradle.properties -pass "pass:$KEY"
  ./gradlew snapshot dockerPushImage $SWITCHES -x release -x test
elif [ $CIRCLE_TAG ]; then
  echo -e "Publishing Release => Branch ['$CIRCLE_BRANCH']  Tag ['$CIRCLE_TAG']"
  openssl enc -d -aes-256-cbc -md sha512 -pbkdf2 -iter 1000 -in gradle.properties.enc -out gradle.properties -pass "pass:$KEY"
  case "$CIRCLE_TAG" in
  *-rc\.*)
    ./gradlew -Prelease.disableGitChecks=true -Prelease.useLastTag=true candidate bintrayUpload $SWITCHES -x release -x bintrayPublish
    ./gradlew -Prelease.disableGitChecks=true -Prelease.useLastTag=true :prometheus-rsocket-client:bintrayPublish dockerPushImage $SWITCHES -x bintrayUpload
    ;;
  *)
    ./gradlew -Prelease.disableGitChecks=true -Prelease.useLastTag=true final bintrayUpload $SWITCHES -x release -x artifactoryPublish -x bintrayPublish
    ./gradlew -Prelease.disableGitChecks=true -Prelease.useLastTag=true :prometheus-rsocket-client:bintrayPublish dockerPushImage $SWITCHES -x bintrayUpload
    ./gradlew -Doverride.docker.springBootApplication.tag=micrometermetrics/prometheus-rsocket-proxy:latest dockerPushImage
    ;;
  esac
else
  echo -e "WARN: Should not be here => Branch ['$CIRCLE_BRANCH']  Tag ['$CIRCLE_TAG']  Pull Request ['$CIRCLE_PR_NUMBER']"
  echo -e "Not attempting to publish"
fi

EXIT=$?

exit $EXIT
