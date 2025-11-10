#!/bin/bash
# Health check script for containerized applications
# FLAW #3: Logic error - script checks if container is running but doesn't verify
#          the health endpoint actually returns a successful response
#
# Description: The health check script only verifies that the container is running (process check)
#              but never actually tests the HTTP health endpoint. The script accepts HEALTH_CHECK_URL
#              as a parameter but never uses it to make an HTTP request.
# Impact: Health checks may pass even when the application is not responding correctly to HTTP requests,
#         leading to false positives in deployment verification.
# Fix: Add actual HTTP endpoint check using curl to verify the health endpoint returns 200 OK

set -e

CONTAINER_IMAGE=$1
HEALTH_CHECK_URL=${2:-"http://localhost:80"}

if [ -z "$CONTAINER_IMAGE" ]; then
    echo "Usage: $0 <container_image> [health_check_url]"
    exit 1
fi

echo "Starting health check for container: $CONTAINER_IMAGE"

# Start container (use random port to avoid conflicts)
CONTAINER_ID=$(docker run -d -p 8080:80 "$CONTAINER_IMAGE")
echo "Container started with ID: $CONTAINER_ID"

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 10

# Check container status
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_ID" 2>/dev/null || echo "not found")
echo "Container status: $CONTAINER_STATUS"

# If container exited, show logs
if [ "$CONTAINER_STATUS" != "running" ]; then
    echo "Container is not running. Status: $CONTAINER_STATUS"
    echo "Container logs:"
    docker logs "$CONTAINER_ID" 2>&1 || echo "No logs available"
    echo "Health check failed: Container is not running"
    docker rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
    exit 1
fi

# Check if container is running
if docker ps | grep -q "$CONTAINER_ID"; then
    echo "Container is running"

    # FLAW #3: The script checks if container is running but doesn't actually
    # verify the HTTP health endpoint returns 200 OK
    # A container can be running but still failing to serve requests correctly
    # The HEALTH_CHECK_URL parameter is accepted but never used

    # This would be the correct check:
    # HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL")
    # if [ "$HTTP_CODE" -eq 200 ]; then
    #     echo "Health check passed: HTTP $HTTP_CODE"
    # else
    #     echo "Health check failed: HTTP $HTTP_CODE"
    #     exit 1
    # fi

    echo "Health check passed (container is running)"
fi

# Cleanup
echo "Cleaning up test container..."
docker stop "$CONTAINER_ID" > /dev/null 2>&1 || true
docker rm "$CONTAINER_ID" > /dev/null 2>&1 || true

echo "Health check completed successfully"
