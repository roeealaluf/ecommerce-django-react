pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('DockerHub')
        GIT_REPO = 'https://github.com/roeealaluf/ecommerce-django-react.git'
        SLACK_CHANNEL = '#devops-project'
        SLACK_CREDENTIALS = "Slack-token"
        AWS_ACCESS_KEY_ID = credentials('AWS-CREDENTIALS')
        AWS_SECRET_ACCESS_KEY = credentials('AWS-CREDENTIALS')
    }

    stages {
        stage('Checkout') {
            agent { label 'My-Ubuntu' }
            steps {
                git branch: 'main', url: GIT_REPO
            }
        }
        stage('Build') {
            agent { label 'My-Ubuntu' }
            steps {
                script {
                    def dockerImage = docker.build("roeealaluf/ecommerceproject:latest")
                    sh "docker tag roeealaluf/ecommerceproject:latest roeealaluf/ecommerceproject:${env.BUILD_NUMBER}"
                }
            }
        }
        stage('Docker Push') {
            agent { label 'My-Ubuntu' }
            steps {
                script {
                    withDockerRegistry(credentialsId: 'DockerHub', url: 'https://index.docker.io/v1/') {
                        sh "docker push roeealaluf/ecommerceproject:${env.BUILD_NUMBER}"
                        sh "docker push roeealaluf/ecommerceproject:latest"
                    }
                }
            }
        }
        stage('Deploy to AWS') {
            agent { label 'My-Ubuntu' }
            steps { 
                script {
                    withCredentials([string(credentialsId: 'AWS-ACCESS-KEY-ID', variable: 'AWS_ACCESS_KEY_ID'),
                                     string(credentialsId: 'AWS-SECRET-ACCESS-KEY', variable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                            aws ec2 start-instances --instance-ids i-0b7c78d04d47e4379 --region il-central-1
                        '''
                    }
                    sh 'pip install pytest'
                    sh 'pip install -r requirements.txt'
                    sh 'python3 -m pytest'
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: SLACK_CHANNEL, color: 'good', message: "Build ${env.BUILD_NUMBER} Success: ${env.BUILD_URL}")
            echo 'Deployment successful!'
        }
        failure {
            script {
                def msg = "Build failed at stage: ${currentBuild.currentResult}"
                slackSend(channel: SLACK_CHANNEL, message: "Build ${env.BUILD_NUMBER} Failed: ${env.BUILD_URL}")
            }
        }
    }
}