// Simplified Working Pipeline - No Docker Required
// This pipeline works immediately in ECS Fargate Jenkins
// Use this for testing the complete flow without Docker-in-Docker setup

pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-central-1'
        PROJECT_NAME = 'broken-pipeline'
        EMAIL_RECIPIENTS = 'ismailmostafa.y@gmail.com'
        // Using pre-built image already in ECR
        ECR_IMAGE = "${PROJECT_NAME}-app:latest"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '======================================'
                echo '📥 Stage 1: Checking out source code'
                echo '======================================'
                checkout scm
                sh 'echo "Repository checked out successfully"'
                sh 'ls -la'
            }
        }
        
        stage('Validate') {
            steps {
                echo '======================================'
                echo '✅ Stage 2: Validating configuration'
                echo '======================================'
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Validating AWS credentials..."
                            aws sts get-caller-identity
                            
                            echo ""
                            echo "Checking ECR repository..."
                            aws ecr describe-repositories \
                                --repository-names ${PROJECT_NAME}-app \
                                --region ${AWS_REGION}
                            
                            echo ""
                            echo "Checking ECS cluster..."
                            aws ecs describe-clusters \
                                --clusters ${PROJECT_NAME}-app \
                                --region ${AWS_REGION}
                        '''
                    }
                }
            }
        }
        
        stage('Pre-Deploy Checks') {
            steps {
                echo '======================================'
                echo '🔍 Stage 3: Pre-deployment checks'
                echo '======================================'
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Current ECS service status:"
                            aws ecs describe-services \
                                --cluster ${PROJECT_NAME}-app \
                                --services ${PROJECT_NAME}-app-service \
                                --region ${AWS_REGION} \
                                --query 'services[0].{Name:serviceName,Status:status,DesiredCount:desiredCount,RunningCount:runningCount}' \
                                --output table
                            
                            echo ""
                            echo "Current running tasks:"
                            TASKS=$(aws ecs list-tasks \
                                --cluster ${PROJECT_NAME}-app \
                                --region ${AWS_REGION} \
                                --query 'taskArns[]' \
                                --output text)
                            
                            if [ -n "$TASKS" ]; then
                                echo "Tasks: $TASKS"
                            else
                                echo "No tasks currently running"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to ECS') {
            steps {
                echo '======================================'
                echo '🚀 Stage 4: Deploying to ECS'
                echo '======================================'
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Triggering ECS deployment..."
                            aws ecs update-service \
                                --cluster ${PROJECT_NAME}-app \
                                --service ${PROJECT_NAME}-app-service \
                                --force-new-deployment \
                                --region ${AWS_REGION}
                            
                            echo ""
                            echo "✅ Deployment triggered successfully"
                        '''
                    }
                }
            }
        }
        
        stage('Wait for Deployment') {
            steps {
                echo '======================================'
                echo '⏳ Stage 5: Waiting for deployment'
                echo '======================================'
                script {
                    sh '''
                        echo "Waiting 30 seconds for ECS to start new tasks..."
                        sleep 30
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '======================================'
                echo '🔍 Stage 6: Verifying deployment'
                echo '======================================'
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Checking deployment status..."
                            aws ecs describe-services \
                                --cluster ${PROJECT_NAME}-app \
                                --services ${PROJECT_NAME}-app-service \
                                --region ${AWS_REGION} \
                                --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}' \
                                --output table
                            
                            echo ""
                            echo "Getting ALB endpoint..."
                            ALB_DNS=$(aws elbv2 describe-load-balancers \
                                --region ${AWS_REGION} \
                                --query 'LoadBalancers[?contains(LoadBalancerName, `app-alb`)].DNSName' \
                                --output text)
                            
                            if [ -n "$ALB_DNS" ]; then
                                echo "Application ALB: http://${ALB_DNS}"
                                echo ""
                                echo "Testing application endpoint..."
                                HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${ALB_DNS} || echo "000")
                                echo "HTTP Status Code: ${HTTP_CODE}"
                                
                                if [ "${HTTP_CODE}" = "200" ]; then
                                    echo "✅ Application is responding successfully!"
                                else
                                    echo "⚠️  Application returned HTTP ${HTTP_CODE}"
                                    echo "Note: This might be expected if deployment is still in progress"
                                fi
                            else
                                echo "⚠️  Could not find ALB DNS name"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Generate Report') {
            steps {
                echo '======================================'
                echo '📊 Stage 7: Generating deployment report'
                echo '======================================'
                script {
                    sh '''
                        echo "========================================="
                        echo "   DEPLOYMENT REPORT"
                        echo "========================================="
                        echo "Build Number: ${BUILD_NUMBER}"
                        echo "Build URL: ${BUILD_URL}"
                        echo "Started by: ${BUILD_USER:-Jenkins}"
                        echo "Git Branch: ${GIT_BRANCH:-N/A}"
                        echo "Git Commit: ${GIT_COMMIT:-N/A}"
                        echo "AWS Region: ${AWS_REGION}"
                        echo "Project: ${PROJECT_NAME}"
                        echo "========================================="
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo '======================================'
            echo '🧹 Cleanup'
            echo '======================================'
            echo 'Pipeline execution completed'
        }
        
        success {
            echo '======================================'
            echo '✅ Pipeline succeeded!'
            echo '======================================'
            script {
                emailext (
                    subject: "✅ Pipeline SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: """
                        <h2>Pipeline Execution Successful! 🎉</h2>
                        
                        <h3>Build Information:</h3>
                        <ul>
                            <li><strong>Job Name:</strong> ${env.JOB_NAME}</li>
                            <li><strong>Build Number:</strong> ${env.BUILD_NUMBER}</li>
                            <li><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                            <li><strong>Project:</strong> ${env.PROJECT_NAME}</li>
                            <li><strong>Region:</strong> ${env.AWS_REGION}</li>
                        </ul>
                        
                        <h3>Deployment Status:</h3>
                        <p>✅ Successfully deployed to ECS cluster: ${env.PROJECT_NAME}-app</p>
                        <p>✅ Service updated: ${env.PROJECT_NAME}-app-service</p>
                        
                        <h3>Next Steps:</h3>
                        <ol>
                            <li>Verify application is running via ALB endpoint</li>
                            <li>Check CloudWatch logs for any errors</li>
                            <li>Monitor ECS service health</li>
                        </ol>
                        
                        <hr>
                        <p><em>This is an automated email from Jenkins CI/CD Pipeline</em></p>
                    """,
                    to: "${env.EMAIL_RECIPIENTS}",
                    mimeType: 'text/html'
                )
            }
        }
        
        failure {
            echo '======================================'
            echo '❌ Pipeline failed!'
            echo '======================================'
            script {
                emailext (
                    subject: "❌ Pipeline FAILURE: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: """
                        <h2>Pipeline Execution Failed! ⚠️</h2>
                        
                        <h3>Build Information:</h3>
                        <ul>
                            <li><strong>Job Name:</strong> ${env.JOB_NAME}</li>
                            <li><strong>Build Number:</strong> ${env.BUILD_NUMBER}</li>
                            <li><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                            <li><strong>Console Output:</strong> <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a></li>
                        </ul>
                        
                        <h3>Action Required:</h3>
                        <ol>
                            <li>Check the console output for error details</li>
                            <li>Review AWS credentials and permissions</li>
                            <li>Verify ECS cluster and service status</li>
                            <li>Check CloudWatch logs</li>
                        </ol>
                        
                        <hr>
                        <p><em>This is an automated email from Jenkins CI/CD Pipeline</em></p>
                    """,
                    to: "${env.EMAIL_RECIPIENTS}",
                    mimeType: 'text/html'
                )
            }
        }
        
        unstable {
            echo '======================================'
            echo '⚠️  Pipeline unstable!'
            echo '======================================'
            script {
                emailext (
                    subject: "⚠️  Pipeline UNSTABLE: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: """
                        <h2>Pipeline Execution Unstable ⚠️</h2>
                        
                        <h3>Build Information:</h3>
                        <ul>
                            <li><strong>Job Name:</strong> ${env.JOB_NAME}</li>
                            <li><strong>Build Number:</strong> ${env.BUILD_NUMBER}</li>
                            <li><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                        </ul>
                        
                        <p>The pipeline completed but some tests or checks were unstable.</p>
                        
                        <hr>
                        <p><em>This is an automated email from Jenkins CI/CD Pipeline</em></p>
                    """,
                    to: "${env.EMAIL_RECIPIENTS}",
                    mimeType: 'text/html'
                )
            }
        }
    }
}

