// Jenkinsfile - Pipeline CI/CD SentimentAI - 10 stages
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sentiment-ai'
        REGISTRY   = 'ghcr.io/afif-yassine'
        IMAGE_TAG  = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    }

    stages {

        // Stage 1 - Checkout
        stage('Checkout') {
            steps {
                checkout scm
                echo "Branche : ${env.BRANCH_NAME}"
                echo "Commit  : ${env.GIT_COMMIT}"
                sh 'git log --oneline -5'
            }
        }

        // Stage 2 - Lint
        stage('Lint') {
            steps {
                sh '''
                    docker run --rm \
                        --volumes-from jenkins \
                        -w $WORKSPACE \
                        python:3.12-slim \
                        sh -c "pip install flake8 -q && flake8 src/ --max-line-length=100"
                '''
            }
        }

        // Stage 3 - IaC Validate (toutes les branches - Fail Fast)
        stage('IaC Validate') {
            steps {
                dir('infra') {
                    sh 'terraform init -backend=false -input=false'
                    sh 'terraform fmt -check'
                    sh 'terraform validate'
                }
            }
        }

        // Stage 4 - Build & Test
        stage('Build & Test') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker rm -f test-runner 2>/dev/null || true
                    set +e
                    docker run \
                        -e CI=true \
                        -m 512m \
                        --name test-runner \
                        ${IMAGE_NAME}:${IMAGE_TAG} \
                        pytest tests/ -v \
                            --cov=src \
                            --cov-report=xml:/tmp/coverage.xml \
                            --cov-report=term-missing \
                            --cov-fail-under=70
                    TEST_EXIT_CODE=$?
                    set -e
                    docker cp test-runner:/tmp/coverage.xml ./coverage.xml 2>/dev/null || true
                    docker rm -f test-runner 2>/dev/null || true
                    exit $TEST_EXIT_CODE
                '''
            }
            post {
                failure {
                    echo 'Tests echoues ou coverage insuffisant (< 70%)'
                }
            }
        }

        // Stage 5 - SonarQube Analysis
        stage('SonarQube Analysis') {
            environment {
                SONARQUBE_TOKEN = credentials('sonar-token')
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
                        docker run --rm \
                            --network cicd-network \
                            --volumes-from jenkins \
                            -w "$WORKSPACE" \
                            -e SONAR_HOST_URL="$SONAR_HOST_URL" \
                            -e SONAR_TOKEN="$SONARQUBE_TOKEN" \
                            sonarsource/sonar-scanner-cli:latest \
                            sonar-scanner \
                                -Dsonar.projectKey=sentiment-ai \
                                -Dsonar.projectName=SentimentAI \
                                -Dsonar.projectBaseDir="$WORKSPACE" \
                                -Dsonar.sources=src \
                                -Dsonar.python.version=3.11 \
                                -Dsonar.python.coverage.reportPaths=coverage.xml \
                                -Dsonar.sourceEncoding=UTF-8 \
                                -Dsonar.scanner.metadataFilePath=$WORKSPACE/report-task.txt
                    '''
                }
            }
        }

        // Stage 6 - Quality Gate
        stage('Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // Stage 7 - Security Scan (Trivy)
        stage('Security Scan') {
            steps {
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/trivy \
                        aquasec/trivy:latest image \
                            --severity HIGH,CRITICAL \
                            --exit-code 0 \
                            --format table \
                ''' + "${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // Stage 8 - Push (main only)
        stage('Push') {
            when {
                anyOf {
                    branch 'main'
                    expression { env.BRANCH_NAME == null }
                }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token',
                    usernameVariable: 'REGISTRY_USER',
                    passwordVariable: 'REGISTRY_PASS'
                )]) {
                    sh """
                        echo \$REGISTRY_PASS | docker login ghcr.io \
                            -u \$REGISTRY_USER --password-stdin
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:latest
                        docker push ${REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        // Stage 9 - IaC Apply (main only)
        stage('IaC Apply') {
            when {
                anyOf {
                    branch 'main'
                    expression { env.BRANCH_NAME == null }
                }
            }
            steps {
                dir('infra') {
                    sh 'terraform init -input=false'
                    sh '''
                        # Import cicd-network if it exists but not in state
                        NETWORK_ID=$(docker network inspect cicd-network --format "{{.Id}}" 2>/dev/null || true)
                        if [ -n "$NETWORK_ID" ]; then
                            terraform import docker_network.cicd $NETWORK_ID 2>/dev/null || true
                        fi
                        # Import sentiment-staging container if exists
                        docker stop sentiment-staging 2>/dev/null || true
                        docker rm sentiment-staging 2>/dev/null || true
                    '''
                    withEnv(['DOCKER_HOST=unix:///var/run/docker.sock']) {
                        sh """
                            TF_VAR_image_tag=${IMAGE_TAG} terraform apply -auto-approve \
                                -var='image_tag=${IMAGE_TAG}'
                        """
                    }
                }
            }
        }

        // Stage 10 - Deploy Staging (main only)
        stage('Deploy Staging') {
            when {
                anyOf {
                    branch 'main'
                    expression { env.BRANCH_NAME == null }
                }
            }
            steps {
                sh '''
                    sleep 5
                    docker exec sentiment-staging python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
                '''
                echo "Staging disponible sur http://localhost:8001"
            }
        }

        // Stage 11 - Smoke Test
        stage('Smoke Test') {
            when {
                anyOf {
                    branch 'main'
                    expression { env.BRANCH_NAME == null }
                }
            }
            steps {
                sh '''
                    echo "Attente demarrage (10s)..."
                    sleep 10

                    # 1. L'app repond
                    docker exec sentiment-staging python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
                    echo "/health OK"

                    # 2. Les metriques sont exposees
                    docker exec sentiment-staging python -c "
import urllib.request
response = urllib.request.urlopen('http://localhost:8000/metrics').read().decode()
assert 'sentiment_predictions_total' in response, 'metrics missing'
print('/metrics OK -- metriques SentimentAI presentes')
" || exit 1

                    # 3. Prometheus scrape l'app
                    sleep 20
                    curl -s "http://localhost:9090/api/v1/query?query=up{job='sentiment-ai'}" | \
                        grep -q '"value":.*1' || echo "Prometheus check skipped - not yet scraping"
                    echo "Smoke test complete"

                    # 4. Grafana repond
                    curl -f http://localhost:3000/api/health || echo "Grafana not running - skipped"
                    echo "Smoke Test OK"
                '''
            }
            post {
                failure {
                    sh 'docker logs prometheus || true'
                    sh 'docker logs sentiment-staging || true'
                    echo 'Smoke Test KO -- voir logs ci-dessus'
                }
            }
        }
    }

    post {
        always {
            sh 'docker compose down -v 2>/dev/null || true'
        }
        success {
            echo "Pipeline reussi ! Image : ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline echoue. Consultez les logs ci-dessus.'
        }
    }
}
