pipeline {
    agent any

    tools {
        nodejs 'node'
        dockerTool 'docker'
    }

    environment {
        BACKEND_IMAGE = 'kubeglance-backend'
        FRONTEND_IMAGE = 'kubeglance-frontend'
        BACKEND_IMAGE_FULL_NAME = "${DOCKERHUB_USERNAME}/${BACKEND_IMAGE}"
        FRONTEND_IMAGE_FULL_NAME = "${DOCKERHUB_USERNAME}/${FRONTEND_IMAGE}"
        EMAIL_RECIPIENTS = 'xxx@gmail.com, yyy@gmail.com' 
        FROM_EMAIL = 'zzz@gmail.com'
        DOCKERHUB_USERNAME = credentials("dockerhub-username")
        DOCKERHUB_PASSWORD = credentials("dockerhub-password")
        SLACK_ALERTS_CHANNEL = "#alerts"
        SONAR_SCANNER_HOME = tool 'sonarqube-7.1.0'

    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'github-credentials', url: 'https://github.com/Terraformix/kubeglance']])
            }
        }

        stage('Secret Scanning - Gitleaks') {
            steps {
                script {
                    def exitCode = sh(script: 'bash gitleaks-scan.sh', returnStatus: true)
                    if (exitCode != 0) {
                        error "❌ Secret scanning failed! Check gitleaks-report.json"
                    }
                    echo "✅ No secrets detected!"
                }
            }
        }

        
        stage('Static Analysis - SonarQube') {

            when {
                branch 'FAKE_BRANCH'
            }

            steps {
                script {
                        // Aborts the build process if the step did not complete within the specific time
                        timeout(time: 60, unit: 'SECONDS') {
                            withSonarQubeEnv('sonar') {

                                sh '''  
                                    ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                                        -Dsonar.projectKey=Kubeglance \
                                        # Not needed since we configure the host and credentials in the Sonarqube server settings
                                        #-Dsonar.host.url=xxx \
                                        #-Dsonar.login=xxx \
                                        -Dsonar.sources=kubeglance-backend/,kubeglance-frontend/src \
                                        -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/tests/** \
                                        -Dsonar.javascript.lcov.reportPaths=kubeglance-backend/coverage/lcov.info,kubeglance-frontend/coverage/lcov.info
                                '''
                            }

                            // Waits for the Quality Gate status to be sent back to Jenkins using the SonarQube webhook
                            waitForQualityGate abortPipeline: true
                        }
                }
            }
        }

        stage('Security Scan - Base Docker Images (Trivy)') {
            steps {
                script {
                    def exitCode = sh(script: 'bash base-image-trivy-scan.sh', returnStatus: true)
                    if (exitCode != 0) {
                        error "❌ Trivy scan failed! Base image vulnerabilities exceeded threshold."
                    }
                    echo "✅ Base image security scan passed!"
                }
            }
        }

        stage('Static Dockerfile & Manifest file Analysis') {
            parallel {
                stage('Security Scan - Dockerfile') {
                    steps {
                        script {
                            def exitCode = sh(script: 'bash docker-opa-conftest.sh', returnStatus: true)
                            if (exitCode != 0) {
                                error "❌ Dockerfile security scan failed!"
                            }
                            echo "✅ Dockerfile security scan passed!"
                        }
                    
                    }
                }

                stage('Security Scan - Kubernetes Manifests') {
                    steps {
                        script {
                            def exitCode = sh(script: 'bash k8s-opa-conftest.sh', returnStatus: true)
                            if (exitCode != 0) {
                                error "❌ Kubernetes manifest security scan failed!"
                            }
                            echo "✅ Kubernetes manifest security scan passed!"
                        }
                    }
                }

                stage('Security Scan - Kubesec') {
                    steps {
                        script {
                            def exitCode = sh(script: 'bash kubesec-manifest-scan.sh', returnStatus: true)
                            if (exitCode != 0) {
                                error "❌ Kubesec scan failed! Check logs for details."
                            }
                            echo "✅ Kubesec scan passed!"
                        }
                    }
                }
            }
        }


        stage('Docker Login') {
            steps {
                script {
                    sh "docker login -u ${DOCKERHUB_USERNAME} -p ${DOCKERHUB_PASSWORD}"
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build - Backend') {
                    steps {
                        dir('kubeglance-backend') {
                            sh "docker build -t ${BACKEND_IMAGE_FULL_NAME}:${BUILD_NUMBER} . --no-cache"
                        }
                    }
                }

                stage('Build - Frontend') {
                    steps {
                        dir('kubeglance-frontend') {
                            sh "docker build -t ${FRONTEND_IMAGE_FULL_NAME}:${BUILD_NUMBER} . --no-cache"
                        }
                    }
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    dir('kubeglance-backend') {
                        def exitCode = sh(script: 'npm test', returnStatus: true)
                        if (exitCode != 0) {
                            error "❌ Unit tests failed!"
                        }
                        echo "✅ All unit tests passed!"
                    }
                }
            }
        }

        stage('Test Coverage') {
            steps {
                script {
                    dir('kubeglance-backend') {
                        // Set stage as 'UNSTABLE' to prevent the pipeline from failing and not running further stages
                        catchError(buildResult: 'SUCCESS', message: 'You have leaked secrets', stageResult: 'UNSTABLE') {
                            sh 'npm run coverage'                
                        }
                    }
                }
            }
        }

        stage('Push Docker Images') {
            parallel {
                stage('Push - Backend') {
                    steps {
                        script {
                            sh "docker push ${BACKEND_IMAGE_FULL_NAME}:${BUILD_NUMBER}"
                        }
                    }
                }

                stage('Push - Frontend') {
                    steps {
                        script {
                            sh "docker push ${FRONTEND_IMAGE_FULL_NAME}:${BUILD_NUMBER}"
                        }
                    }
                }
            }
        }

        stage('Security Scan - Application Docker Images (Trivy)') {
            steps {
                script {
                    def exitCode = sh(script: 'bash app-image-trivy-scan.sh ${BACKEND_IMAGE_FULL_NAME}:${BUILD_NUMBER} ${FRONTEND_IMAGE_FULL_NAME}:${BUILD_NUMBER}', returnStatus: true)
                    if (exitCode != 0) {
                        error "❌ Trivy scan failed! Application image vulnerabilities exceeded threshold."
                    }
                    echo "✅ Application image security scan passed!"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                dir('helm/kubeglance') {
                    script {
                        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) { 
                            sh '''
                                helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
                                helm repo update

                                helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
                                    --namespace kube-system \
                                    --create-namespace

                                helm upgrade --install kubeglance . \
                                    --namespace kubeglance \
                                    --create-namespace \
                                    --set frontend.image.tag=${BUILD_NUMBER} \
                                    --set backend.image.tag=${BUILD_NUMBER}
                            '''
                        }
                    }
                }
            }
        }
        
    }

    post {

        failure {
            script {
                def slackMessage = """
                *Jenkins Build Failed* 🚨
                *Project:* ${JOB_NAME}
                *Build Number:* ${BUILD_NUMBER}
                *Stage:* Unit Testing
                *Status:* ❌ FAILED
                *URL:* ${BUILD_URL}
                """

                slackSend (
                    channel: SLACK_ALERTS_CHANNEL,
                    color: 'danger',
                    message: slackMessage
                )
            }
                
        }

        success {
            script {
                def slackMessage = """
                *Jenkins Build Success* 🚨
                *Project:* ${JOB_NAME}
                *Build Number:* ${BUILD_NUMBER}
                *Stage:* Unit Testing
                *Status:* ✅ SUCCESS
                *URL:* ${BUILD_URL}
                """

                slackSend (
                    channel: SLACK_ALERTS_CHANNEL,
                    color: 'success',
                    message: slackMessage
                )
            }
        }

        always {

            script {
                def buildStatusColor = (currentBuild.currentResult == 'SUCCESS') ? '#28a745' : (currentBuild.currentResult == 'FAILURE') ? '#dc3545' : '#6c757d'

                emailext(
                    subject: "Jenkins Build Notification: ${currentBuild.fullDisplayName} - ${currentBuild.currentResult}",
                    body: """
                        <html>
                            <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px;">
                                <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; padding: 20px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);">
                                    <h2 style="text-align: center; color: ${buildStatusColor};">Build Status: ${currentBuild.currentResult}</h2>

                                    <p style="font-size: 16px; color: #333;">Dear Team,</p>
                                    <p style="font-size: 16px; color: #333;">The build for <strong>${JOB_NAME}</strong> (<strong>#${BUILD_NUMBER}</strong>) has completed with the status: <strong>${currentBuild.currentResult}</strong>.</p>

                                    <hr style="border: 1px solid #e0e0e0; margin: 20px 0;">

                                    <h3 style="color: #333;">Build Details</h3>
                                    <ul style="list-style-type: none; padding: 0;">
                                        <li><b>Build Number:</b> ${BUILD_NUMBER}</li>
                                        <li><b>Build URL:</b> <a href="${BUILD_URL}" style="color: #007bff; text-decoration: none;">${BUILD_URL}</a></li>
                                        <li><b>Branch:</b> ${GIT_BRANCH}</li>
                                        <li><b>Commit:</b> ${GIT_COMMIT}</li>
                                        <li><b>Duration:</b> ${currentBuild.durationString}</li>
                                    </ul>

                                    <hr style="border: 1px solid #e0e0e0; margin: 20px 0;">

                                    <p style="font-size: 16px; color: #333;">For further details, please visit the <a href="${BUILD_URL}" style="color: #007bff; text-decoration: none;">Jenkins Build Page</a>.</p>

                                    <footer style="text-align: center; font-size: 14px; color: #777; margin-top: 20px;">
                                        <p>Best regards,<br/>Your Jenkins CI/CD System</p>
                                    </footer>
                                </div>
                            </body>
                        </html>
                    """,
                    to: "${EMAIL_RECIPIENTS}",
                    from: "${FROM_EMAIL}",
                    mimeType: 'text/html',
                    replyTo: 'noreply@example.com'
                )

        }


        }
    }
}
