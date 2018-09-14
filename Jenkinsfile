pipeline {
    agent any
    stages {
        stage('Build') { 
            agent {
                docker {
                    image 'python:latest' 
                }
            }
            steps {
                sh 'python -m unittest -v tests 2> >(tee -a /tmp/unittest-report.log >&2)'
            }
        }
    }
    post {
        always {
            junit '/tmp/unittest-report*.log'
        }
    }
}
