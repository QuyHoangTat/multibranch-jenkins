pipeline{

    agent any

    environment {
        DOCKERHB_CREDENTIALS = credentials('dockerhub')
    }

    stages {
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
                sh 'docker push dinhcam89/dinhcam89-catalog:latest'
                sh 'docker push dinhcam89/dinhcam89-cart:latest'
                sh 'docker push dinhcam89/dinhcam89-orders:latest'
                sh 'docker push dinhcam89/dinhcam89-checkout:latest'
                sh 'docker push dinhcam89/dinhcam89-assets:latest'
                sh 'docker push dinhcam89/dinhcam89-ui:latest'
            }
        }
        stage('Deploy to Staging Environment') {
            steps {
                sh 'aws eks --region ap-southeast-1 update-kubeconfig --name eks-cicd-staging'
                sh 'kubectl apply -f dist/kubernetes/deploy.yaml'
            }
        }
        stage('Deploy to Production Environment') {
            steps {
                script {
                    try{
                        timeout(time: 5, unit: 'MINUTES') {
                            env.useChoice = input message: "Can it be deployed to the production environment?", ok: "Yes",
                            parameters: [choice(name: 'useChoice', choices: 'Yes\nNo', description: 'Choose whether to deploy to production or not')]
                        }
                        if (env.useChoice == 'Yes') {
                            sh 'sudo su - jenkins'
                            sh 'aws eks --region ap-southeast-1 update-kubeconfig --name eks-cicd-prod'
                            sh 'kubectl apply -f dist/kubernetes/deploy.yaml'
                        } else {
                            echo 'The deployment is not allowed to the production environment'
                        }
                    }
                    catch (Exception err) {
                        // handle the exception
                    }
                }
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
