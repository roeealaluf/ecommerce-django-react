pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('DockerHub')
        GIT_REPO = 'https://github.com/roeealaluf/ecommerce-django-react.git'
        SLACK_CHANNEL = '#devops-project'
        SLACK_CREDENTIALS = "Slack-token"
        AWS_CREDENTIALS = credentials('AWS-CREDENTIALS')
        AWS_REGION = 'il-central-1' 
        INSTANCE_NAME = 'Jenkins2'
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
                sh 'docker build -t myapp:latest .'
            }
        }
        stage('Docker Push') {
            agent { label 'My-Ubuntu' }
            steps {
                script {
                    withDockerRegistry(credentialsId: 'DockerHub', url: 'https://index.docker.io/v1/') {
                        sh "docker push roeealaluf/ecommerceproject:latest"
                    }
                }
            }
        }

        stage('Run Docker Container') {
            agent { label 'My-Ubuntu' }
            steps {
                script {
                    sh "docker run -d -p 8000:8000 roeealaluf/ecommerceproject:latest"
        }
    }             
}
        stage('Test') {
            agent { label 'My-Ubuntu' }
            steps {
                sh 'test_user.py/unit'
                sh 'test_products.py/e2e'
                sh 'pip3 install -r requirements.txt'
                sh 'python3 -m pytest'
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
