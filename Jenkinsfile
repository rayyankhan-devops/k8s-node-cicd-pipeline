pipeline {
    agent any

    environment {
        DOCKER_HUB = 'rayyan12311/node-k8s-cicd'
    }

    stages {
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_HUB}:latest ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${DOCKER_HUB}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // Apply namespace first, then all other yaml files
                sh "kubectl apply -f kubernetes/namespace.yml"
                sh "kubectl apply -f kubernetes/"
                sh "kubectl rollout restart deployment/k8s-cicd-deployment -n k8s-cicd-ns"
                // Wait for the pod to be Running and Ready before port-forwarding
                sh "kubectl rollout status deployment/k8s-cicd-deployment -n k8s-cicd-ns --timeout=60s"
            }
        }

        stage('Port Forward') {
            steps {
                sh """
                    pkill -f "kubectl port-forward.*6767" || true
                    sleep 2
                    JENKINS_NODE_COOKIE=dontKillMe nohup kubectl port-forward svc/k8s-cicd-svc 6767:6767 -n k8s-cicd-ns --address 0.0.0.0 > /tmp/port-forward.log 2>&1 &
                    sleep 3
                """
            }
        } 
    }
}