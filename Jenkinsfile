pipeline {
    agent any

    environment {
        DOCKERHB_CREDENTIALS = credentials('dockerhub')
    }

    stages {
        stage('Check SCM') {
            steps {
                checkout scm
            }
        }
        stage('Install Libraries') {
            steps {
                sh 'scripts/install-libraries.sh'
            }
        }
        stage('Run Tests') {
            steps {
                sh 'scripts/run-tests.sh'
            }
        }
        stage('Deploy to Test Server') {
            steps {
                sh 'aws eks --region ap-southeast-1 update-kubeconfig --name eks-cicd-staging'
                sh 'kubectl apply -f dist/kubernetes/deploy.yaml'
            }
        }
        stage('Run Application on Test Environment') {
            steps {
                sh 'docker-compose -f docker-compose-test.yml up -d'
            }
        }
    }
    post {
        always {
            cleanWs()
            sh 'docker-compose -f docker-compose-test.yml down'
        }
    }
}
