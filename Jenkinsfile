pipeline {
    agent {
        docker {
            image 'python:latest' 
        }
    }
    stages {
        stage('Build') { 
            steps {
                sh 'pwd'
            }
            steps {
                sh 'ls'
            }
            steps {
                sh 'python -m unittest -v tests'
            }
        }
    }
}
