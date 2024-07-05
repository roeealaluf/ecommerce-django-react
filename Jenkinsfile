pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('DockerHub')
        GIT_REPO = 'https://github.com/roeealaluf/ecommerce-django-react.git'
        SLACK_CHANNEL = '#devops-project'
        SLACK_CREDENTIALS = "Slack-token"
        AWS_CREDENTIALS = credentials('AWS-CREDENTIALS')
        // JIRA_CREDENTIALS = credentials('Jira-credential')
        // jirasite = 'https://ecommercedevops.atlassian.net'
        // JIRA_PROJECT_KEY = 'DevopsProject'
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
        // Commented out the Test stage
        // stage('Test') {
        //     agent { label 'My-Ubuntu' }
        //     steps {
        //         sh 'pip3 install -r requirements.txt'
        //         sh 'python3 -m pytest'
        //     }
        // }
        stage('Docker Push') {
            agent { label 'My-Ubuntu' }
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_HUB_CREDENTIALS) {
                        def app = docker.build("roeealaluf/ecommerceproject:${env.BUILD_NUMBER}")
                        app.push()
                        app.push('latest')
                    }
                }
            }
        }
        stage('Deploy to AWS') {
            agent { label 'My-Ubuntu' }
            environment {
                AWS_ACCESS_KEY_ID = credentials('AWS-CREDENTIALS')
                AWS_SECRET_ACCESS_KEY = credentials('AWS-CREDENTIALS')
            }
            steps {
                script {
                    sh 'aws ec2 start-instances --instance-ids i-0b7c78d04d47e4379 --region il-central-1'
                    sh python -m pytest
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

                // def jirasite = 'https://ecommercedevops.atlassian.net'
                // jiraNewIssue site: jirasite, issue: [
                //     fields: [
                //         project: [key: "${env.JIRA_PROJECT_KEY}"],
                //         summary: "Build ${env.BUILD_NUMBER} Failed: ${env.BUILD_URL}",
                //         description: 'Build failed',
                //         issuetype: [name: 'Bug']
                //     ]
                // ]
            }
        }
    }
}
