pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_USERNAME = 'alexj77'
        TAG = "${GIT_COMMIT[0..6]}"
        SHELL = "C:\\Program Files\\Git\\bin\\bash.exe"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Lint & Test') {
            parallel {
                stage('auth') {
                    steps {
                        dir('auth') {
                            bat 'npm ci'
                        }
                    }
                }
                stage('tickets') {
                    steps {
                        dir('tickets') {
                            bat 'npm ci'
                        }
                    }
                }
                stage('orders') {
                    steps {
                        dir('orders') {
                            bat 'npm ci'
                        }
                    }
                }
                stage('payments') {
                    steps {
                        dir('payments') {
                            bat 'npm ci'
                        }
                    }
                }
            }
        }
        stage('Build Images') {
            steps {
                dir('client') {
                    bat 'npm install'
                }
                bat """
                    docker build -t %DOCKER_USERNAME%/ticketflow-auth:%TAG% ./auth
                    docker build -t %DOCKER_USERNAME%/ticketflow-tickets:%TAG% ./tickets
                    docker build -t %DOCKER_USERNAME%/ticketflow-orders:%TAG% ./orders
                    docker build -t %DOCKER_USERNAME%/ticketflow-payments:%TAG% ./payments
                    docker build -t %DOCKER_USERNAME%/ticketflow-expiration:%TAG% ./expiration
                    docker build -t %DOCKER_USERNAME%/ticketflow-client:%TAG% ./client
                """
            }
        }
        stage('Push to Registry') {
            steps {
                bat """
                    echo %DOCKER_HUB_CREDENTIALS_PSW% | docker login -u %DOCKER_HUB_CREDENTIALS_USR% --password-stdin
                    docker push %DOCKER_USERNAME%/ticketflow-auth:%TAG%
                    docker push %DOCKER_USERNAME%/ticketflow-tickets:%TAG%
                    docker push %DOCKER_USERNAME%/ticketflow-orders:%TAG%
                    docker push %DOCKER_USERNAME%/ticketflow-payments:%TAG%
                    docker push %DOCKER_USERNAME%/ticketflow-expiration:%TAG%
                    docker push %DOCKER_USERNAME%/ticketflow-client:%TAG%
                """
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                bat """
                    kubectl set image deployment/auth-depl auth=%DOCKER_USERNAME%/ticketflow-auth:%TAG%
                    kubectl set image deployment/tickets-depl tickets=%DOCKER_USERNAME%/ticketflow-tickets:%TAG%
                    kubectl set image deployment/orders-depl orders=%DOCKER_USERNAME%/ticketflow-orders:%TAG%
                    kubectl set image deployment/payments-depl payments=%DOCKER_USERNAME%/ticketflow-payments:%TAG%
                    kubectl set image deployment/expiration-depl expiration=%DOCKER_USERNAME%/ticketflow-expiration:%TAG%
                    kubectl set image deployment/client-depl client=%DOCKER_USERNAME%/ticketflow-client:%TAG%
                """
            }
        }
    }

    post {
        failure {
            bat """
                docker rmi %DOCKER_USERNAME%/ticketflow-auth:%TAG% 2>nul
                docker rmi %DOCKER_USERNAME%/ticketflow-tickets:%TAG% 2>nul
                docker rmi %DOCKER_USERNAME%/ticketflow-orders:%TAG% 2>nul
                docker rmi %DOCKER_USERNAME%/ticketflow-payments:%TAG% 2>nul
                docker rmi %DOCKER_USERNAME%/ticketflow-expiration:%TAG% 2>nul
                docker rmi %DOCKER_USERNAME%/ticketflow-client:%TAG% 2>nul
            """
        }
        always {
            bat 'docker logout'
        }
    }
}