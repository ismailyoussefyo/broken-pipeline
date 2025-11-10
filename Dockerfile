# Dockerfile: Customizes tutum/hello-world
# This Dockerfile extends the base hello-world image with customizations

FROM tutum/hello-world:latest

# Add custom labels
LABEL maintainer="broken-pipeline"
LABEL description="Customized hello-world application for broken pipeline challenge"

# Expose port 80
EXPOSE 80

# The base image already has the application configured
# This Dockerfile can be extended with additional customizations if needed
# For example:
# - Custom environment variables
# - Additional configuration files
# - Health check scripts
# - Logging configuration

