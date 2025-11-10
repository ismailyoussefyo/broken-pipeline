// Quick Test Pipeline - Demonstrates Jenkins Working Without Docker
// This pipeline tests that Jenkins can interact with AWS services

pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-central-1'
        PROJECT_NAME = 'broken-pipeline'
    }
    
    stages {
        stage('Test Jenkins Setup') {
            steps {
                echo '====================================='
                echo 'Testing Jenkins is properly configured'
                echo '====================================='
                sh 'echo "Jenkins is running!"'
                sh 'pwd'
                sh 'whoami'
            }
        }
        
        stage('Test AWS Credentials') {
            steps {
                echo '====================================='
                echo 'Testing AWS credentials are configured'
                echo '====================================='
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials', variable: 'AWS_CREDENTIALS')]) {
                        sh '''
                            echo "Testing AWS access..."
                            aws sts get-caller-identity --region ${AWS_REGION}
                        '''
                    }
                }
            }
        }
        
        stage('Test ECR Access') {
            steps {
                echo '====================================='
                echo 'Testing ECR repository access'
                echo '====================================='
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials', variable: 'AWS_CREDENTIALS')]) {
                        sh '''
                            echo "Checking ECR repositories..."
                            aws ecr describe-repositories --region ${AWS_REGION}
                            
                            echo ""
                            echo "Checking images in broken-pipeline-app repository..."
                            aws ecr list-images --repository-name ${PROJECT_NAME}-app --region ${AWS_REGION} || echo "No images yet"
                        '''
                    }
                }
            }
        }
        
        stage('Test ECS Access') {
            steps {
                echo '====================================='
                echo 'Testing ECS cluster access'
                echo '====================================='
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials', variable: 'AWS_CREDENTIALS')]) {
                        sh '''
                            echo "Checking ECS clusters..."
                            aws ecs list-clusters --region ${AWS_REGION}
                            
                            echo ""
                            echo "Checking Application cluster details..."
                            aws ecs describe-clusters --clusters ${PROJECT_NAME}-app --region ${AWS_REGION}
                            
                            echo ""
                            echo "Checking Jenkins cluster details..."
                            aws ecs describe-clusters --clusters ${PROJECT_NAME}-jenkins --region ${AWS_REGION}
                            
                            echo ""
                            echo "Checking Application service..."
                            aws ecs describe-services --cluster ${PROJECT_NAME}-app --services ${PROJECT_NAME}-app-service --region ${AWS_REGION}
                        '''
                    }
                }
            }
        }
        
        stage('Test S3 Access') {
            steps {
                echo '====================================='
                echo 'Testing S3 bucket access'
                echo '====================================='
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials', variable: 'AWS_CREDENTIALS')]) {
                        sh '''
                            echo "Checking S3 buckets..."
                            aws s3 ls --region ${AWS_REGION} | grep ${PROJECT_NAME}
                        '''
                    }
                }
            }
        }
        
        stage('Test SNS Access') {
            steps {
                echo '====================================='
                echo 'Testing SNS topic access'
                echo '====================================='
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials', variable: 'AWS_CREDENTIALS')]) {
                        sh '''
                            echo "Checking SNS topics..."
                            aws sns list-topics --region ${AWS_REGION} | grep ${PROJECT_NAME}
                        '''
                    }
                }
            }
        }
        
        stage('Test ALB Access') {
            steps {
                echo '====================================='
                echo 'Testing ALB endpoints'
                echo '====================================='
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials', variable: 'AWS_CREDENTIALS')]) {
                        sh '''
                            echo "Checking Application Load Balancers..."
                            APP_ALB_DNS=$(aws elbv2 describe-load-balancers --region ${AWS_REGION} --query 'LoadBalancers[?contains(LoadBalancerName, `app-alb`)].DNSName' --output text)
                            echo "Application ALB: http://${APP_ALB_DNS}"
                            
                            JENKINS_ALB_DNS=$(aws elbv2 describe-load-balancers --region ${AWS_REGION} --query 'LoadBalancers[?contains(LoadBalancerName, `jenkins-alb`)].DNSName' --output text)
                            echo "Jenkins ALB: http://${JENKINS_ALB_DNS}"
                            
                            echo ""
                            echo "Testing Application endpoint..."
                            curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://${APP_ALB_DNS} || echo "Endpoint not accessible"
                        '''
                    }
                }
            }
        }
        
        stage('Summary') {
            steps {
                echo '====================================='
                echo '✅ PIPELINE TEST COMPLETED'
                echo '====================================='
                echo 'All AWS services are accessible from Jenkins!'
                echo ''
                echo 'Jenkins can:'
                echo '  ✅ Execute shell commands'
                echo '  ✅ Access AWS services'
                echo '  ✅ Query ECR repositories'
                echo '  ✅ Query ECS clusters and services'
                echo '  ✅ Query S3 buckets'
                echo '  ✅ Query SNS topics'
                echo '  ✅ Query ALB endpoints'
                echo ''
                echo 'Next steps:'
                echo '  1. Install Docker in Jenkins container for image builds'
                echo '  2. Configure Git repository for source code'
                echo '  3. Run full CI/CD pipeline'
            }
        }
    }
    
    post {
        always {
            echo 'Test pipeline execution completed'
        }
        success {
            echo '🎉 All tests passed! Jenkins is properly configured.'
        }
        failure {
            echo '❌ Some tests failed. Check the logs above.'
        }
    }
}


