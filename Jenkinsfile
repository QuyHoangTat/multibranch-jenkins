pipeline {
    agent any

    environment {
        DOCKERHB_CREDENTIALS = credentials('dockerhub')
        CURRENT_IMAGE_TAG = ""  // Biến lưu trữ tag của image hiện tại sau khi triển khai
        PREVIOUS_IMAGE_TAG = ""  // Biến lưu trữ tag của image trước khi triển khai
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
                    // Gán quyền thực thi cho build-image.sh
                    sh 'chmod +x scripts/build-image.sh'

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
                    // Đọc phiên bản (tag) của từng service từ rollback_tag.txt nếu tồn tại
                    if (fileExists('rollback_tag.txt')) {
                        env.PREVIOUS_IMAGE_TAG = readFile('rollback_tag.txt').trim()
                    }

                    // Cập nhật images trong deployment.yaml
                    updateDeploymentImage('assets', env.PREVIOUS_IMAGE_TAG)
                    updateDeploymentImage('cart', env.PREVIOUS_IMAGE_TAG)
                    updateDeploymentImage('catalog', env.PREVIOUS_IMAGE_TAG)
                    updateDeploymentImage('checkout', env.PREVIOUS_IMAGE_TAG)
                    updateDeploymentImage('orders', env.PREVIOUS_IMAGE_TAG)
                    updateDeploymentImage('ui', env.PREVIOUS_IMAGE_TAG)

                    // Lưu tag của image hiện tại để sử dụng cho rollback nếu cần
                    env.CURRENT_IMAGE_TAG = "${env.BUILD_NUMBER}"
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
            // Kiểm tra biến env.PREVIOUS_IMAGE_TAG trước khi sử dụng
            script {
                if (env.PREVIOUS_IMAGE_TAG) {
                    writeFile(file: 'rollback_tag.txt', text: env.PREVIOUS_IMAGE_TAG)
                } else {
                    echo "env.PREVIOUS_IMAGE_TAG is not set, skipping writeFile."
                }
            }
        }
    }
}

def buildAndPushImage(service) {
    stage("Build and Push ${service} Image") {
        script {
            // Xây dựng image với tag là phiên bản cụ thể
            sh "scripts/build-image.sh -s ${service} -t ${env.BUILD_NUMBER}"

            // Đổi tên và đẩy image lên Docker Hub
            sh "docker tag quyhoangtat/${service}:${env.BUILD_NUMBER} quyhoangtat/${service}:${env.BUILD_NUMBER}"
            sh "docker push quyhoangtat/${service}:${env.BUILD_NUMBER}"

            // Lưu trữ tag của image đã triển khai vào biến PREVIOUS_IMAGE_TAG
            env.PREVIOUS_IMAGE_TAG = "${env.BUILD_NUMBER}"
        }
    }
}

def deployToEnvironment(environmentName) {
    stage("Deploy to ${environmentName} Environment") {
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

def runStageRollback() {
    // Đọc danh sách services từ một tệp hoặc biến môi trường
    def services = ['assets', 'cart', 'catalog', 'checkout', 'orders', 'ui']

    // Duyệt qua từng service để thực hiện rollback
    services.each { service ->
        stage("Rollback ${service} Image") {
            script {
                // Đọc phiên bản (tag) trước đó từ tệp rollback_tag.txt
                def previousTag = readFile("rollback_tag.txt").trim()

                // Thực hiện rollback bằng cách kéo image về từ Docker Hub và đặt lại tag
                sh "docker pull quyhoangtat/${service}:${previousTag}"
                sh "docker tag quyhoangtat/${service}:${previousTag} quyhoangtat/${service}:${previousTag}"
                sh "docker push quyhoangtat/${service}:${previousTag}"

                // Cập nhật lại biến lưu trữ tag của image đã triển khai
                env.CURRENT_IMAGE_TAG = previousTag

                // Cập nhật lại deployment.yaml sau khi rollback
                updateDeploymentImage(service, previousTag)
            }
        }
    }
}

def updateDeploymentImage(service, newTag) {
    stage("Update ${service} Deployment Image") {
        script {
            // Đọc và chỉnh sửa deployment.yaml
            sh "sed -i \"s|image: quyhoangtat/${service}:.*|image: quyhoangtat/${service}:${newTag}|\" dist/kubernetes/deploy.yaml"

            // Commit và push lại deployment.yaml lên GitHub
            sh "git config --global user.email 'admin@admin.com'"
            sh "git config --global user.name 'Jenkins Automation'"
            sh "git add dist/kubernetes/deploy.yaml"
            sh "git commit -m 'Update ${service} deployment image tag to ${newTag}'"
            sh "git push origin main"
        }
    }
}
