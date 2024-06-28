pipeline {
    agent none

    enviroment {
        DOCKER_HUB_CREDENTIALS = credentials('DockerHub')  
        GIT_REPO = 'https://github.com/roeealaluf/ecommerce-django-react'
        GIT_CREDENTIALS_ID = 'Github'
        SLACK_CHANNEL = 'devops-project'
        JIRA_CREDENTIALS = credentials('Jira-credentials')
        JIRA_SITE = 'https://ecommercedevops.atlassian.net/jira/your-work'
        JIRA_PROJECT_KEY = 'DevopsProject' 
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/roeealaluf/ecommerce-django-react'
            }
        }
        stage('Build') {
            steps {
                sh 'docker build -t myapp:latest .'
            }
        }
        stage('Test') {
            steps {
                sh 'test_user.py/unit'
                sh 'test_products.py/e2e'
            }
        }
        stage('Docker Push') {
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'DOCKER_HUB_CREDENTIALS') {
                        def app = docker.build("roeealaluf/myapp:${env.BUILD_NUMBER}")
                        app.push()
                        app.push('latest') 
                    }
                }
            }
        }
        stage('Deploy to AWS') {
            enviroment {
                AWS_ACCESS_KEY_ID = credentials('aws-credentials')  
                AWS_SECRET_ACCESS_KEY = credentials('aws-credentials')
            }
            steps {
                script {
                    sh 'aws ec2 start-instances --instance-ids i-1234567890abcdef0 --region il-central-1'
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: '#devops-project', color: 'good', message: "Build ${env.BUILD_NUMBER} Success: ${env.BUILD_URL}")
            echo 'Deployment successful!'
        }
        failure {
            script {
                def log = currentBuild.rawBuild.log
                emailext(
                    subject: "Build ${env.BUILD_NUMBER} Failed",
                    body: "${env.BUILD_URL} \n ${log}",
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                )
                slackSend(channel: '#devops-project', color: 'danger', message: "Build ${env.BUILD_NUMBER} Failed: ${env.BUILD_URL}")
                jiraIssue(
                    site: 'https://ecommercedevops.atlassian.net/', 
                    issueKey: 'DevopsProject',
                    issueSelector: [$class: 'DefaultIssueSelector']
                    comment: "Build ${env.BUILD_NUMBER} Failed: ${env.BUILD_URL}"
                )
            }
        }
    }
}