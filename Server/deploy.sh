#!/bin/bash

# Set the image name and tag
IMAGE_NAME="gcr.io/gothic-sequence-443115-v5/smartender"
IMAGE_TAG="latest"

# Function for loading animation
loading_animation() {
  spinner="/|\\-"
  while :; do
    for i in $(seq 0 3); do
      echo -ne "\r$1 ${spinner:$i:1}"
      sleep 0.1
    done
  done
}

# Step 1: Build the Docker image 🏗️
echo "🚀 Building Docker image... 🐳"
loading_animation "Building..." &
BUILD_PID=$!
docker build -t $IMAGE_NAME:$IMAGE_TAG . || { echo "❌ Docker build failed! Exiting."; kill $BUILD_PID; exit 1; }
kill $BUILD_PID
echo -e "\n✅ Docker image built successfully! 🎉"

# Step 2: Push the Docker image to Google Container Registry 🌐
echo "🔄 Pushing Docker image to Google Container Registry... 📦"
loading_animation "Pushing..." &
PUSH_PID=$!
docker push $IMAGE_NAME:$IMAGE_TAG || { echo "❌ Docker push failed! Exiting."; kill $PUSH_PID; exit 1; }
kill $PUSH_PID
echo -e "\n✅ Docker image pushed successfully! 🎉"

# Step 3: Update Cloud Run service with the new image 🖥️
echo "☁️ Updating Cloud Run service... 🌍"
loading_animation "Updating..." &
UPDATE_PID=$!
gcloud run services update smartender --image $IMAGE_NAME:$IMAGE_TAG --region europe-west3 || { echo "❌ Cloud Run service update failed! Exiting."; kill $UPDATE_PID; exit 1; }
kill $UPDATE_PID
echo -e "\n✅ Cloud Run service updated successfully! 🎉"

echo "🚀 Deployment completed successfully! 🎉✨"