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
                sh 'scripts/build-image.sh -s assets -t staging'
                sh 'scripts/build-image.sh -s cart -t staging'
                sh 'scripts/build-image.sh -s catalog -t staging'
                sh 'scripts/build-image.sh -s checkout -t staging'
                sh 'scripts/build-image.sh -s orders -t staging'
                sh 'scripts/build-image.sh -s ui -t staging'
            }
        }
        stage('View Images') {
            steps {
                sh 'docker images'
            }
        }
        stage('Push Images to Docker Hub') {
            steps {
                sh 'docker push quyhoangtat/catalog:staging'
                sh 'docker push quyhoangtat/cart:staging'
                sh 'docker push quyhoangtat/orders:staging'
                sh 'docker push quyhoangtat/checkout:staging'
                sh 'docker push quyhoangtat/assets:staging'
                sh 'docker push quyhoangtat/ui:staging'
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
