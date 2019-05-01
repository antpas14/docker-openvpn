#!/bin/bash

# This script builds the Dockerfile file for current system architecture and pushs it to a dockerhub 

REPO_PATH="antpas14/openvpn"

main() {
        build_image
}

build_image() {
        DOCKERFILE="./Dockerfile."
        ARCH=$( get_current_arch )
        docker build -f ${DOCKERFILE}${ARCH} -t $REPO_PATH:$ARCH .
        docker push $REPO_PATH:$ARCH
}

get_current_arch() {
        uname -m
}

main $@

