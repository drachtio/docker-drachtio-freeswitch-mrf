#!/bin/bash

# Check if .env file exists
if [ ! -f ".env" ]; then
  echo "Error: .env file not found"
  exit 1
fi

# Extract versions from the .env file
cmakeVersion=$(grep cmakeVersion .env | awk -F '=' '{print $2}')
grpcVersion=$(grep grpcVersion .env | awk -F '=' '{print $2}')
libwebsocketsVersion=$(grep libwebsocketsVersion .env | awk -F '=' '{print $2}')
speechSdkVersion=$(grep speechSdkVersion .env | awk -F '=' '{print $2}')
spandspVersion=$(grep spandspVersion .env | awk -F '=' '{print $2}')
sofiaVersion=$(grep sofiaVersion .env | awk -F '=' '{print $2}')
awsSdkCppVersion=$(grep awsSdkCppVersion .env | awk -F '=' '{print $2}')
freeswitchModulesVersion=$(grep freeswitchModulesVersion .env | awk -F '=' '{print $2}')
freeswitchVersion=$(grep freeswitchVersion .env | awk -F '=' '{print $2}')
dockerImageRepo=$(grep dockerImageRepo .env | awk -F '=' '{print $2}')
dockerImageVersion=$(grep dockerImageVersion .env | awk -F '=' '{print $2}')

# Specify the image name and tag
imageName="drachtio/drachtio-freeswitch-mrf"
imageTag="latest"

# Create and use a new Buildx builder instance (if not already done)
docker buildx create --use --name mybuilder --bootstrap || docker buildx use mybuilder

# Build and push multi-architecture images
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg CMAKE_VERSION="${cmakeVersion}" \
  --build-arg GRPC_VERSION="${grpcVersion}" \
  --build-arg LIBWEBSOCKETS_VERSION="${libwebsocketsVersion}" \
  --build-arg SPEECH_SDK_VERSION="${speechSdkVersion}" \
  --build-arg SPANDSP_VERSION="${spandspVersion}" \
  --build-arg SOFIA_VERSION="${sofiaVersion}" \
  --build-arg AWS_SDK_CPP_VERSION="${awsSdkCppVersion}" \
  --build-arg FREESWITCH_MODULES_VERSION="${freeswitchModulesVersion}" \
  --build-arg FREESWITCH_VERSION="${freeswitchVersion}" \
  . --tag "${dockerImageRepo}:${dockerImageVersion}"

# Optional: remove the builder after the build to clean up
docker buildx rm mybuilder
