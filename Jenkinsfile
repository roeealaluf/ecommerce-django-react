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
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_HUB_CREDENTIALS) {
                        def app = docker.build("roeealaluf/myapp:${env.BUILD_NUMBER}")
                        app.push()
                        app.push('latest')
                    }
                }
            }
        }
        stage('Deploy to AWS') {
            agent { label 'My-Ubuntu' }
            environment {
                AWS_ACCESS_KEY_ID = "${AWS_CREDENTIALS_USR}"
                AWS_SECRET_ACCESS_KEY = "${AWS_CREDENTIALS_PSW}"
            }
            steps {
                script {
                    def instanceId = sh(script: "aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag:Name,Values=${INSTANCE_NAME} --query 'Reservations[0].Instances[0].InstanceId' --output text", returnStdout: true).trim()
                    sh "aws ec2 start-instances --instance-ids ${instanceId} --region ${AWS_REGION}"
        }
    }             
}
          // stage('Test') {
        //     agent { label 'My-Ubuntu' }
        //     steps {
        //         sh 'test_user.py/unit'
        //         sh 'test_products.py/e2e'
        //         sh 'pip3 install -r requirements.txt'
        //         sh 'python3 -m pytest'
        //     }
        // }
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
