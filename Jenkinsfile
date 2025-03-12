pipeline {
    agent any

    environment {
        DOCKER_DEV_IMAGE = "arunkandhaswamy/dev-react-app"
        DOCKER_PROD_IMAGE = "arunkandhaswamy/prod-react-app"
        DOCKER_CREDENTIALS = "docker-hub-credentials"  
        EC2_USER = "ubuntu"
        EC2_IP = "3.110.221.225"
        SSH_CREDENTIALS = "aws-ssh-key"  
    }

    triggers {
        githubPush()  
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: "*/${GIT_BRANCH}", url: 'https://github.com/Arunkandhaswamy/Project2.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Executing build script for ${env.BRANCH_NAME}..."
                    sh './build.sh'
                    
                    if (env.BRANCH_NAME == 'dev') {
                        sh "docker tag devops-build_react-app:latest $DOCKER_DEV_IMAGE:latest"
                    } else if (env.BRANCH_NAME == 'master') {
                        sh "docker tag devops-build_react-app:latest $DOCKER_PROD_IMAGE:latest"
                    }
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        echo "Pushing to public dev repository..."
                        sh 'docker push $DOCKER_DEV_IMAGE:latest'
                    } else if (env.BRANCH_NAME == 'master') {
                        echo "Checking if dev was merged before pushing to prod..."
                        def mergeCheck = sh(script: "git log --oneline -n 1 | grep 'Merge pull request'", returnStatus: true)

                        if (mergeCheck == 0) {
                            echo "Dev branch was merged. Pushing to private prod repository..."
                            sh 'docker push $DOCKER_PROD_IMAGE:latest'
                        } else {
                            echo "No merge detected. Skipping push to prod."
                        }
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'master'
                }
            }
            steps {
                sshagent(['aws-ssh-key']) {
                    script {
                        def imageName = (env.BRANCH_NAME == 'dev') ? DOCKER_DEV_IMAGE : DOCKER_PROD_IMAGE
                        echo "Deploying $imageName to EC2..."
                        sh """
                            ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP '
                            export DOCKER_USER="${DOCKER_USER}" && export DOCKER_PASS="${DOCKER_PASS}" &&
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin &&
                            docker pull $imageName:latest &&
                            docker stop react-app || true &&
                            docker rm react-app || true &&
                            ./deploy.sh
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        success { echo 'Deployment Successful!' }
        failure { echo 'Deployment Failed. Check Logs!' }
    }
}

