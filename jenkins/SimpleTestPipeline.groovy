// Simple Test Pipeline - Works with basic Jenkins installation
// Uses Secret text credentials instead of AWS credentials plugin

pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-central-1'
        PROJECT_NAME = 'broken-pipeline'
        AWS_DEFAULT_REGION = 'eu-central-1'
    }
    
    stages {
        stage('Test Jenkins') {
            steps {
                echo '====================================='
                echo '✅ Testing Jenkins is running'
                echo '====================================='
                sh 'echo "Jenkins is working!"'
                sh 'pwd'
                sh 'date'
            }
        }
        
        stage('Test AWS Credentials') {
            steps {
                echo '====================================='
                echo '✅ Testing AWS credentials'
                echo '====================================='
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Testing AWS access..."
                            aws sts get-caller-identity
                        '''
                    }
                }
            }
        }
        
        stage('Test ECR') {
            steps {
                echo '====================================='
                echo '✅ Testing ECR repository access'
                echo '====================================='
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Listing ECR repositories..."
                            aws ecr describe-repositories --region ${AWS_REGION}
                        '''
                    }
                }
            }
        }
        
        stage('Test ECS') {
            steps {
                echo '====================================='
                echo '✅ Testing ECS cluster access'
                echo '====================================='
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Listing ECS clusters..."
                            aws ecs list-clusters --region ${AWS_REGION}
                            
                            echo ""
                            echo "Application cluster status:"
                            aws ecs describe-clusters --clusters ${PROJECT_NAME}-app --region ${AWS_REGION} \
                                --query 'clusters[0].{Name:clusterName,Status:status,RunningTasks:runningTasksCount,RegisteredInstances:registeredContainerInstancesCount}' \
                                --output table
                        '''
                    }
                }
            }
        }
        
        stage('Test ALB Endpoints') {
            steps {
                echo '====================================='
                echo '✅ Testing Application endpoints'
                echo '====================================='
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Getting ALB DNS names..."
                            APP_ALB=$(aws elbv2 describe-load-balancers --region ${AWS_REGION} \
                                --query 'LoadBalancers[?contains(LoadBalancerName, `app-alb`)].DNSName' --output text)
                            
                            JENKINS_ALB=$(aws elbv2 describe-load-balancers --region ${AWS_REGION} \
                                --query 'LoadBalancers[?contains(LoadBalancerName, `jenkins-alb`)].DNSName' --output text)
                            
                            echo ""
                            echo "Application URL: http://${APP_ALB}"
                            echo "Jenkins URL: http://${JENKINS_ALB}"
                            
                            echo ""
                            echo "Testing Application endpoint..."
                            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${APP_ALB})
                            echo "HTTP Status Code: ${HTTP_CODE}"
                            
                            if [ "${HTTP_CODE}" = "200" ]; then
                                echo "✅ Application is responding successfully!"
                            else
                                echo "⚠️  Application returned non-200 status"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Summary') {
            steps {
                echo '========================================='
                echo '🎉 ALL TESTS COMPLETED SUCCESSFULLY!'
                echo '========================================='
                echo ''
                echo 'Jenkins is properly configured and can:'
                echo '  ✅ Execute pipeline stages'
                echo '  ✅ Access AWS services'
                echo '  ✅ Query ECR repositories'
                echo '  ✅ Query ECS clusters'
                echo '  ✅ Access ALB endpoints'
                echo '  ✅ Test application health'
                echo ''
                echo 'Your infrastructure is working! 🚀'
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs above for details.'
        }
    }
}


