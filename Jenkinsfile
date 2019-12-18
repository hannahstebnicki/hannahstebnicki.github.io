#!groovy
@Library('aereus.pipeline') _

import aereus.pipeline.DeploymentTargets

def APPLICATION_VERSION = "latest"
def DOCKERHUB_SERVER = "dockerhub.aereus.com"
def PROJECT_NAME = 'www_hannahstebnicki_com'
def dockerImage;

pipeline {
    agent { node { label 'linux' } }
    stages {
        stage('Build') {
            steps {
                script {
                    sh 'env'
                    checkout scm
                    dockerimage = docker.build("${DOCKERHUB_SERVER}/${PROJECT_NAME}:${APPLICATION_VERSION}")
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    dir('.clair') {
                        def nodeIp = sh(
                            script: "ip addr show dev eth0  | grep 'inet ' | sed -e 's/^[ \t]*//' | cut -d ' ' -f 2 | cut -d '/' -f 1",
                            returnStdout: true
                        ).trim();

                        // Pull the clairscanner binary
                        git branch: 'master',
                            credentialsId: '9862b4cf-a692-43c5-9614-9d93114f93a7',
                            url: 'ssh://git@src.aereus.com:222/source/clair.aereus.com.git'

                        sh 'chmod +x ./bin/clair-scanner_linux_amd64'

                        // Fail if any critical security vulnerabilities are found
                        sh "./bin/clair-scanner_linux_amd64 -t 'Critical' -c http://dev1.aereus.com:6060 --ip=${nodeIp} ${DOCKERHUB_SERVER}/${PROJECT_NAME}:${APPLICATION_VERSION}"
                   }
                }
            }
        }

        stage('Publish') {
            steps {
                script {
                    docker.withRegistry('https://dockerhub.aereus.com', 'aereusdev-dockerhub') {
                        sh "docker push ${DOCKERHUB_SERVER}/${PROJECT_NAME}:${APPLICATION_VERSION}"
                    }
                }
            }
        }

        stage('Integration') {
            steps {
                script {
                    deployToSwarm(
                        environment: DeploymentTargets.INTEGRATION,
                        stackName: PROJECT_NAME,
                        imageTag: APPLICATION_VERSION,
                        serviceDomain: 'www_hannahstebnicki_com.aereus.com'
                    )
                }
            }
        }

        stage('Production') {
            steps {
                // Call stack deploy to upgrade
                script {
                    script {
                        deployToSwarm(
                            environment: DeploymentTargets.PRODUCTION_PRESENTATION_DALLAS,
                            stackName: PROJECT_NAME,
                            imageTag: APPLICATION_VERSION,
                            serviceDomain: 'www.hannahstebnicki.com'
                        )
                    }
                }
            }
        }
    }
     post {
        always {
            cleanWs()
        }
        failure {
            emailext (
                subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
     }
}