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

        stage('Login to Docker Hub') {
            steps {
                sh 'echo $DOCKERHB_CREDENTIALS_PSW | docker login -u $DOCKERHB_CREDENTIALS_USR --password-stdin'
            }
        }

        stage('Build and Push Docker Images') {
            steps {
                script {
                    // Xây dựng và đẩy image cho từng service với tag là phiên bản cụ thể
                    buildAndPushImage('assets')
                    buildAndPushImage('cart')
                    buildAndPushImage('catalog')
                    buildAndPushImage('checkout')
                    buildAndPushImage('orders')
                    buildAndPushImage('ui')
                }
            }
        }

        stage('Update Deployment Images') {
            steps {
                script {
                    // Đọc phiên bản (tag) của từng service từ rollback_tag.txt
                    def previousTag = readFile('rollback_tag.txt').trim()

                    // Cập nhật images trong deployment.yaml
                    updateDeploymentImage('assets', previousTag)
                    updateDeploymentImage('cart', previousTag)
                    updateDeploymentImage('catalog', previousTag)
                    updateDeploymentImage('checkout', previousTag)
                    updateDeploymentImage('orders', previousTag)
                    updateDeploymentImage('ui', previousTag)

                    // Áp dụng các thay đổi vào Kubernetes cluster
                    sh "kubectl apply -f dist/kubernetes/deploy.yaml"
                }
            }
        }

        stage('Conditional Deploy to Production Environment') {
            when {
                branch 'main'
            }
            steps {
                script {
                    deployToEnvironment('eks-cicd-prod')
                }
            }
        }

        stage('Rollback Deployed Images') {
            steps {
                script {
                    runStageRollback()
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
                // Xây dựng image với tag là phiên bản cụ thể
                sh "scripts/build-image.sh -s ${service} -t ${BUILD_NUMBER}"

                // Đổi tên và đẩy image lên Docker Hub
                sh "docker tag quyhoangtat/${service}:${BUILD_NUMBER} quyhoangtat/${service}:${BUILD_NUMBER}"
                sh "docker push quyhoangtat/${service}:${BUILD_NUMBER}"

                // Lưu trữ tag của image đã triển khai vào biến PREV_IMAGE_TAG
                PREV_IMAGE_TAG = "${BUILD_NUMBER}"
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
                    sh "docker tag quyhoangtat/${service}:${previousTag} quyhoangtat/${service}:${previousTag}"
                    sh "docker push quyhoangtat/${service}:${previousTag}"

                    // Cập nhật lại biến lưu trữ tag của image đã triển khai
                    PREV_IMAGE_TAG = previousTag
                }
            }
        }
    }
}

def updateDeploymentImage(service, newTag) {
    stage("Update ${service} Deployment Image") {
        steps {
            script {
                // Đọc và chỉnh sửa deployment.yaml
                sh "sed -i \"s/image: quyhoangtat/${service}:.*/image: quyhoangtat/${service}:${newTag}/\" dist/kubernetes/deploy.yaml"
                sh "kubectl apply -f dist/kubernetes/deploy.yaml"
            }
        }
    }
}
