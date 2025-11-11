# Dockerfile: Custom application with nginx and welcome page
# Built by Jenkins CI/CD pipeline
# Created by: Ismail Youssef
#
# VERSION: 1.0.0
# IMPORTANT: When you modify this Dockerfile, update the VERSION file!
# Example: echo "1.0.1" > VERSION
# This ensures the pipeline creates a unique image tag that forces ECS to pull the new image.
#
FROM nginx:alpine

# Add custom labels
LABEL maintainer="broken-pipeline"
LABEL author="Ismail Youssef"
LABEL description="Custom application built from Dockerfile by Jenkins pipeline"
LABEL version="1.0"

# Create custom HTML page with clear branding
RUN echo '<!DOCTYPE html>' > /usr/share/nginx/html/index.html && \
    echo '<html lang="en">' >> /usr/share/nginx/html/index.html && \
    echo '<head>' >> /usr/share/nginx/html/index.html && \
    echo '    <meta charset="UTF-8">' >> /usr/share/nginx/html/index.html && \
    echo '    <meta name="viewport" content="width=device-width, initial-scale=1.0">' >> /usr/share/nginx/html/index.html && \
    echo '    <title>Custom Pipeline App</title>' >> /usr/share/nginx/html/index.html && \
    echo '    <style>' >> /usr/share/nginx/html/index.html && \
    echo '        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }' >> /usr/share/nginx/html/index.html && \
    echo '        .container { max-width: 800px; margin: 100px auto; padding: 40px; background: white; border-radius: 10px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }' >> /usr/share/nginx/html/index.html && \
    echo '        h1 { color: #667eea; text-align: center; margin-bottom: 20px; }' >> /usr/share/nginx/html/index.html && \
    echo '        .badge { background: #10b981; color: white; padding: 10px 20px; border-radius: 5px; display: inline-block; margin: 10px 0; }' >> /usr/share/nginx/html/index.html && \
    echo '        .info { background: #f3f4f6; padding: 20px; border-radius: 5px; margin: 20px 0; }' >> /usr/share/nginx/html/index.html && \
    echo '        .success { color: #10b981; font-weight: bold; }' >> /usr/share/nginx/html/index.html && \
    echo '        ul { list-style: none; padding: 0; }' >> /usr/share/nginx/html/index.html && \
    echo '        li { padding: 8px 0; border-bottom: 1px solid #e5e7eb; }' >> /usr/share/nginx/html/index.html && \
    echo '        li:before { content: "✅ "; margin-right: 10px; }' >> /usr/share/nginx/html/index.html && \
    echo '    </style>' >> /usr/share/nginx/html/index.html && \
    echo '</head>' >> /usr/share/nginx/html/index.html && \
    echo '<body>' >> /usr/share/nginx/html/index.html && \
    echo '    <div class="container">' >> /usr/share/nginx/html/index.html && \
    echo '        <h1>🚀 Custom Application Successfully Deployed!</h1>' >> /usr/share/nginx/html/index.html && \
    echo '        <div class="badge">✅ BUILT FROM CUSTOM DOCKERFILE</div>' >> /usr/share/nginx/html/index.html && \
    echo '        <div class="info">' >> /usr/share/nginx/html/index.html && \
    echo '            <h2>Pipeline Information</h2>' >> /usr/share/nginx/html/index.html && \
    echo '            <ul>' >> /usr/share/nginx/html/index.html && \
    echo '                <li><strong>Source:</strong> Custom Dockerfile (not Docker Hub)</li>' >> /usr/share/nginx/html/index.html && \
    echo '                <li><strong>Built by:</strong> Jenkins CI/CD Pipeline</li>' >> /usr/share/nginx/html/index.html && \
    echo '                <li><strong>Stored in:</strong> AWS ECR</li>' >> /usr/share/nginx/html/index.html && \
    echo '                <li><strong>Deployed to:</strong> AWS ECS Fargate</li>' >> /usr/share/nginx/html/index.html && \
    echo '                <li><strong>Web Server:</strong> nginx:alpine</li>' >> /usr/share/nginx/html/index.html && \
    echo '            </ul>' >> /usr/share/nginx/html/index.html && \
    echo '        </div>' >> /usr/share/nginx/html/index.html && \
    echo '        <p class="success">✨ If you see this page, your CI/CD pipeline is working correctly! ✨</p>' >> /usr/share/nginx/html/index.html && \
    echo '        <hr>' >> /usr/share/nginx/html/index.html && \
    echo '        <p style="text-align: center; color: #6b7280; font-size: 14px;">Broken Pipeline Challenge - Custom Built Image</p>' >> /usr/share/nginx/html/index.html && \
    echo '        <p style="text-align: center; color: #667eea; font-size: 13px; font-weight: bold; margin-top: 10px;">Created by: ismail Mostafa Ismail Youssef</p>' >> /usr/share/nginx/html/index.html && \
    echo '    </div>' >> /usr/share/nginx/html/index.html && \
    echo '</body>' >> /usr/share/nginx/html/index.html && \
    echo '</html>' >> /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# nginx will start automatically from base image
CMD ["nginx", "-g", "daemon off;"]
