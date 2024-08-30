pipeline {
    agent any
    tools {
        jdk 'jdk'
        maven 'maven'
    }
    environment {
        SCANNER_HOME = tool 'scanner'
    }
    stages {
        stage('1.0 Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout From Git') {
            steps {
                git branch: 'main', url: 'https://github.com/FortressTechnologiesInc/Petclinic2.0.git'
            }
        }
        stage('Maven Compile') {
            steps {
                sh 'mvn clean compile'
            }
        }
        stage('Maven Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh ''' 
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=Petshop:3.0 \
                    -Dsonar.java.binaries=. \
                    -Dsonar.projectKey=Petshop:3.0 
                    '''
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar'
                }
            }
        }
        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
                sh 'mvn install'
            }
        }
        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --format HTML', odcInstallation: 'DP'
                dependencyCheckPublisher pattern: '**/dependency-check-report.html'
            }
        }
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh "docker build -t iscanprint/petshop:3.0 ."
                        sh "docker push iscanprint/petshop:3.0"
                    }
                }
            }
        }
        stage('TRIVY') {
            steps {
                sh "trivy image iscanprint/petshop:3.0 > trivy.txt"
            }
        }
        stage('Clean Up Containers') {
            steps {
                script {
                    try {
                        sh 'docker stop petshop'
                        sh 'docker rm petshop'
                    } catch (Exception e) {
                        echo "Container petshop not found, moving to next stage"
                    }
                }
            }
        }
        stage('Manual Approval') {
            steps {
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        def approvalMailContent = """
                        Project: ${env.JOB_NAME}
                        Build Number: ${env.BUILD_NUMBER}
                        Go to build URL and approve the deployment request.
                        Build URL: ${env.BUILD_URL}
                        """
                        mail to: 'deniferdavies@gmail.com',
                             subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}",
                             body: approvalMailContent,
                             mimeType: 'text/plain'
                        input id: "DeployGate",
                              message: "Deploy ${params.project_name}?",
                              submitter: "approver",
                              parameters: [choice(name: 'action', choices: ['Deploy'], description: 'Approve deployment')]
                    }
                }
            }
        }
        stage('Deploy to Container') {
            steps {
                sh 'docker run -d --name petshop -p 8082:8080 iscanprint/petshop:3.0'
            }
        }
        stage('Deploy to Tomcat') {
            steps {
                deploy adapters: [tomcat9(credentialsId: 'tomcat', path: '', url: 'http://192.168.4.17:8711/')], contextPath: 'petshop', war: '**/*.war'
                sh "sudo cp /root/appnode/workspace/petshop/target/petshop.war /opt/apache-tomcat-10.1.28/webapps/"
            }
        }
        stage('1.1 Clean Workspace') {
            steps {
                cleanWs()
            }
        }
    }
    post {
        always {
            emailext attachLog: true,
                subject: "'${currentBuild.result}'",
                body: """
                    <html>
                    <body>
                        <div style="background-color: #FFA07A; padding: 15px; margin-bottom: 15px;">
                            <p style="color: white; font-weight: bold;">Project: ${env.JOB_NAME}</p>
                        </div>
                        <div style="background-color: #90EE90; padding: 15px; margin-bottom: 15px;">
                            <p style="color: white; font-weight: bold;">Build Number: ${env.BUILD_NUMBER}</p>
                        </div>
                        <div style="background-color: #87CEEB; padding: 15px; margin-bottom: 15px;">
                            <p style="color: white; font-weight: bold;">URL: ${env.BUILD_URL}</p>
                        </div>
                    </body>
                    </html>
                """,
                to: 'deniferdavies@gmail.com,mokeleke@gmail.com',
                mimeType: 'text/html'
        }
    }
}

// Alternative Manual Approval Stage
stage('Manual Approval') {
    timeout(time: 10, unit: 'MINUTES') {
        mail to: 'postbox.deniferdavies@gmail.com',
             subject: "${currentBuild.result} CI: ${env.JOB_NAME}",
             body: "Project: ${env.JOB_NAME}\nBuild Number: ${env.BUILD_NUMBER}\nGo to ${env.BUILD_URL} and approve deployment"
        input message: "Deploy ${params.project_name}?", 
               id: "DeployGate", 
               submitter: "approver", 
               parameters: [choice(name: 'action', choices: ['Deploy'], description: 'Approve deployment')]
    }
}
