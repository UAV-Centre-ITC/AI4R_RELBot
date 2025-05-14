#!/usr/bin/env bash
set -euo pipefail

# Configuration
CONTAINER_NAME="relbot_ai4r_assignment1"
IMAGE_NAME="gstream-ros2-jazzy-ubuntu24"
HOST_FOLDER="${1:-$(pwd)/ai4r_ws/src}"    # default to $(pwd)/ai4r_ws/src
CONTAINER_FOLDER="/ai4r_ws/src"

# Build image if missing
if ! docker image inspect "${IMAGE_NAME}" > /dev/null 2>&1; then
  echo "Building Docker image: ${IMAGE_NAME}..."
  docker build -t "${IMAGE_NAME}" .
fi

# Reminder for ROS_DOMAIN_ID
echo "Reminder: Set your ROS_DOMAIN_ID in ~/.bashrc or export before each session."

echo "Enabling X11 access for Docker containers..."
xhost +local:docker

# Attach or create container
if docker ps --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q .; then
  echo "Attaching to running container: ${CONTAINER_NAME}"
  docker exec -it "${CONTAINER_NAME}" bash
elif docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q .; then
  echo "Starting existing container: ${CONTAINER_NAME}"
  docker start "${CONTAINER_NAME}"
  docker exec -it "${CONTAINER_NAME}" bash
else
  echo "Creating and launching container: ${CONTAINER_NAME} (with GPU support)"
  echo "Note: Ensure that an NVIDIA GPU is available, the required NVIDIA drivers are installed, and the NVIDIA Container Toolkit is properly set up for GPU access."
  docker run -it \
    --name "${CONTAINER_NAME}" \
    --net=host \
    --gpus all\
    -e DISPLAY="$DISPLAY" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v "${HOST_FOLDER}":"${CONTAINER_FOLDER}" \
    -e QT_X11_NO_MITSHM=1 \
    --privileged \
    "${IMAGE_NAME}" bash
fi
