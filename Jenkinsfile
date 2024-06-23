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
        stage('Login to Docker Hub') {
            steps {
                sh 'sudo su - jenkins'
                sh 'echo $DOCKERHB_CREDENTIALS_PSW | echo $DOCKERHB_CREDENTIALS_USR | docker login -u $DOCKERHB_CREDENTIALS_USR -p $DOCKERHB_CREDENTIALS_PSW'
            }
        }
        stage('Build Docker Images') {
            steps {
                sh "chmod +x -R ${env.WORKSPACE}"
                sh 'scripts/build-image.sh -s assets -t latest'
                sh 'scripts/build-image.sh -s cart -t latest'
                sh 'scripts/build-image.sh -s catalog -t latest'
                sh 'scripts/build-image.sh -s checkout -t latest'
                sh 'scripts/build-image.sh -s orders -t latest'
                sh 'scripts/build-image.sh -s ui -t latest'
            }
        }
        stage('View Images') {
            steps {
                sh 'docker images'
            }
        }
        stage('Push Images to Docker Hub') {
            steps {
                sh 'docker push quyhoangtat/catalog:latest'
                sh 'docker push quyhoangtat/cart:latest'
                sh 'docker push quyhoangtat/orders:latest'
                sh 'docker push quyhoangtat/checkout:latest'
                sh 'docker push quyhoangtat/assets:latest'
                sh 'docker push quyhoangtat/ui:latest'
            }
        }
        stage('Deploy to Staging Environment') {
            steps {
                sh 'aws eks --region ap-southeast-1 update-kubeconfig --name eks-cicd-staging'
                sh 'kubectl apply -f dist/kubernetes/deploy.yaml'
            }
        }
    }
    post {
        always {
            cleanWs()
            sh 'docker logout'
        }
    }
}
