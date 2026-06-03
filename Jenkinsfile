pipeline{
    agent any
        
        tools{
            nodejs 'nodejs'
            jdk 'jdk'
        }

        parameters{
            string(name: 'ECR_REPO_NAME', defaultValue: 'disney-hostart-ecr-repo', description: 'Enter ECR Repo Name')
            string(name: 'AWS_ACCOUNT_ID', defaultValue: '', description: 'Enter AWS Account ID')
        }

        environment{
            SONAR_HOME = tool 'sonar-scanner'
        }


        stages{
            stage("Clean Workspace"){
                steps{
                    cleanWs()
                }
            }

            stage("Git Checkout"){
                steps{
                    git branch: 'main', credentialsId: 'github-token', url: 'https://github.com/pranav0015/Disney-Hotstar-Deployment.git'
                }
            }

            stage("NPM Install"){
                steps{
                    sh "npm install"
                }
            }

         //   stage('OWASP FS SCAN') {
        //        steps {
        //            dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey FA7AD04A-005F-F111-836C-0EBF96DE670D', odcInstallation: 'DC' // DC is tools name for dependency check in Jenkins Tools. and created nvdApiKey from online.
         //           dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
         //        }
         //   }

            stage("Trivy Scanning"){
                steps{
                    sh "trivy fs --format table -o trivy-fs-report.html ."
                }
            }

            stage("SonarQube Scanning"){
                steps{
                    withSonarQubeEnv('sonar-server') {
                        sh '''
                        $SONAR_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=DisneyHotstar \
                        -Dsonar.projectKey=DisneyHotstar
                        '''   
                    }
                }
            }

            stage("SonarQube Quality Gate"){
                steps{
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }

            stage("Build Docker Image"){
                steps{
                    sh "docker build -t ${params.ECR_REPO_NAME} ."
                }
            }

            stage("Trivy Docker Image Scan"){
                steps{
                    sh "trivy image --format table -o trivy-docker-image-scan-report.html ${params.ECR_REPO_NAME}"
                }
            }

            stage("Create ECR Repo"){
                steps{
                    withCredentials([string(credentialsId: 'iam-access-key', variable: 'ACCESS_KEY'), string(credentialsId: 'iam-secret-key', variable: 'SECRET_KEY')]) {
                        sh """
                            aws configure set aws_access_key_id $ACCESS_KEY
                            aws configure set aws_secret_access_key $SECRET_KEY
                            aws ecr describe-repositories --repository-name ${params.ECR_REPO_NAME} --region ap-south-1 ||
                            aws ecr create-repository --repository-name ${params.ECR_REPO_NAME} --region ap-south-1
                        """
                    }
                    
                }
            }

            stage("Logging to ECR and tagging the image"){
                steps{
                    withCredentials([string(credentialsId: 'iam-access-key', variable: 'access-key'), string(credentialsId: 'iam-secret-key', variable: 'secret-key')]) {
                        sh """
                            aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com
                            docker tag ${params.ECR_REPO_NAME}:latest ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER
                            docker tag ${params.ECR_REPO_NAME}:latest ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:latest
                        """
                    }
                }
            }
            stage("Push Docker Image to ECR"){
                steps{
                    withCredentials([string(credentialsId: 'iam-access-key', variable: 'access-key'), string(credentialsId: 'iam-secret-key', variable: 'secret-key')]) {
                        sh """
                            docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER
                            docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:latest
                        """
                    }

                }
            }

            stage("Cleanup Docker Images from Jenkins Server"){
                steps{
                    sh """
                        docker rmi ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER
                        docker rmi ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:latest
                        docker images
                    """
                }
            }

        }
}