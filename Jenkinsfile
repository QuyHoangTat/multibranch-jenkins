pipeline {
    agent any

    environment {
        DOCKERHB_CREDENTIALS = credentials('dockerhub')
        PREV_IMAGE_TAG = ""  // Biến lưu trữ tag của image trước khi triển khai
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

        stage('Login to Docker Hub') {
            steps {
                sh 'echo $DOCKERHB_CREDENTIALS_PSW | docker login -u $DOCKERHB_CREDENTIALS_USR --password-stdin'
            }
        }

        stage('Build and Push Docker Images') {
            steps {
                script {
                    // Xây dựng và đẩy image cho từng service
                    buildAndPushImage('assets')
                    buildAndPushImage('cart')
                    buildAndPushImage('catalog')
                    buildAndPushImage('checkout')
                    buildAndPushImage('orders')
                    buildAndPushImage('ui')
                }
            }
        }

        stage('Deploy to Staging Environment') {
            steps {
                script {
                    deployToEnvironment('eks-cicd-staging')
                }
            }
        }

        stage('Deploy to Production Environment') {
            steps {
                script {
                    deployToEnvironment('eks-cicd-prod')
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            sh 'docker logout'
            // Lưu lại tag của image đã triển khai vào rollback_tag.txt để sử dụng cho rollback
            writeFile(file: 'rollback_tag.txt', text: PREV_IMAGE_TAG)
        }
    }
}

def buildAndPushImage(service) {
    stage("Build and Push ${service} Image") {
        steps {
            script {
                // Xây dựng image
                sh "scripts/build-image.sh -s ${service} -t latest"

                // Đổi tên và đẩy image lên Docker Hub
                sh "docker tag quyhoangtat/${service}:latest quyhoangtat/${service}:latest"
                sh "docker push quyhoangtat/${service}:latest"

                // Lưu trữ tag của image đã triển khai vào biến PREV_IMAGE_TAG
                PREV_IMAGE_TAG = 'latest'
            }
        }
    }
}

def deployToEnvironment(environmentName) {
    stage("Deploy to ${environmentName} Environment") {
        steps {
            script {
                try {
                    timeout(time: 5, unit: 'MINUTES') {
                        input message: "Deploy to ${environmentName} environment?", ok: 'Yes'
                    }
                    // Đổi kubeconfig và triển khai ứng dụng
                    sh "aws eks --region ap-southeast-1 update-kubeconfig --name ${environmentName}"
                    sh "kubectl apply -f dist/kubernetes/deploy.yaml"
                } catch (Exception err) {
                    echo "Error occurred while deploying to ${environmentName}. Rolling back..."
                    runStageRollback()
                    currentBuild.result = 'FAILURE'
                    error("Failed to deploy to ${environmentName} environment")
                }
            }
        }
    }
}

def runStageRollback() {
    // Đọc danh sách services từ một tệp hoặc biến môi trường
    def services = ['assets', 'cart', 'catalog', 'checkout', 'orders', 'ui']

    // Duyệt qua từng service để thực hiện rollback
    services.each { service ->
        stage("Rollback ${service} Image") {
            steps {
                script {
                    // Đọc phiên bản (tag) trước đó từ tệp rollback_tag.txt
                    def previousTag = readFile("rollback_tag.txt").trim()

                    // Thực hiện rollback bằng cách kéo image về từ Docker Hub và đặt lại tag
                    sh "docker pull quyhoangtat/${service}:${previousTag}"
                    sh "docker tag quyhoangtat/${service}:${previousTag} quyhoangtat/${service}:latest"
                    sh "docker push quyhoangtat/${service}:latest"

                    // Cập nhật lại biến lưu trữ tag của image đã triển khai
                    PREV_IMAGE_TAG = previousTag
                }
            }
        }
    }
}
