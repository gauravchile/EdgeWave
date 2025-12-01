@Library('JenkinsSharedLibs') _

pipeline {
  agent any

  parameters {
    choice(name: 'DEPLOY_COLOR', choices: ['auto', 'blue', 'green'],
      description: 'Auto = detect inactive color; Blue/Green = manual override')
    string(name: 'IMAGE_TAG', defaultValue: '', description: 'Optional manual image tag (leave blank for auto-semver)')
  }

  environment {
    REGISTRY        = 'docker.io'
    USER            = 'gauravchile'
    IMAGE_NAME      = 'edgewave'
    IMAGE_REPO      = "${REGISTRY}/${USER}/${IMAGE_NAME}"
    EMAIL_RECIPIENT = 'gauravchile07@gmail.com'
    GIT_CRED        = 'github-ssh'
    DOCKER_CRED     = 'dockerhub-creds'
    SONAR_CRED      = 'sonar-token'
    SONAR_HOST      = 'http://localhost:9000'
    SONAR_PROJECT   = 'edgewave'
    NAMESPACE       = 'edgewave'
  }

  triggers {
    pollSCM('* * * * *')  // Check GitHub every minute
  }

  stages {

    /* -------------------------------------------------------------------------- */
    stage('Checkout') {
      steps {
        echo "🔁 Checking out EdgeWave repository..."
        checkout scm
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('SonarQube Analysis') {
      steps {
        withCredentials([string(credentialsId: env.SONAR_CRED, variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv('SonarQube') {
            sh """
              sonar-scanner \
                -Dsonar.projectKey=${SONAR_PROJECT} \
                -Dsonar.sources=. \
                -Dsonar.host.url=${SONAR_HOST} \
                -Dsonar.login=$SONAR_TOKEN
            """
          }
        }
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('Quality Gate') {
      steps {
        timeout(time: 3, unit: 'MINUTES') {
          echo "🧠 Waiting for SonarQube Quality Gate result..."
          waitForQualityGate abortPipeline: true
        }
      }
    }

    /* ✅ Collect SonarQube Report */
    stage('Collect SonarQube Report') {
      steps {
        script {
          collectSonarReport(
            sonarHost: env.SONAR_HOST,
            projectKey: env.SONAR_PROJECT,
            sonarCredId: env.SONAR_CRED
          )
        }
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('Version') {
      steps {
        script {
          env.IMAGE_TAG = params.IMAGE_TAG?.trim() ?: getUpdateTagVersion(yamlDir: 'manifests/base')
          currentBuild.displayName = "#${BUILD_NUMBER} • ${env.IMAGE_TAG}"
          echo "📦 Using version: ${env.IMAGE_TAG}"
        }
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('Detect Active Color') {
      steps {
        script {
          def auto = (params.DEPLOY_COLOR == 'auto')
          def result = auto
            ? getActiveColor(services: ['frontend', 'backend'], namespace: env.NAMESPACE, defaultColor: 'blue')
            : [activeColor: (params.DEPLOY_COLOR == 'blue' ? 'green' : 'blue'), nextColor: params.DEPLOY_COLOR]

          env.ACTIVE_COLOR = result.activeColor
          env.NEXT_COLOR   = result.nextColor ?: (result.activeColor == 'blue' ? 'green' : 'blue')

          echo "🎨 Mode: ${auto ? 'Auto' : 'Manual'} | Active: ${env.ACTIVE_COLOR} | Next: ${env.NEXT_COLOR}"
        }
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('Build Backend Image') {
      when {
        changeset "backend/**"
      }
      steps {
        script {
          echo "🚀 Backend changes detected — building and pushing backend image..."
          buildAndPush('backend')
        }
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('Build Frontend Image') {
      when {
        changeset "frontend/**"
      }
      steps {
        script {
          echo "🚀 Frontend changes detected — building and pushing frontend image..."
          buildAndPush('frontend')
        }
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('Update Kubernetes Manifests') {
      steps {
        echo "🧾 Updating manifests for GitOps..."
        sh """
          chmod +x scripts/update-image-tags.sh
          ./scripts/update-image-tags.sh manifests/base $IMAGE_REPO \
            backend-${env.NEXT_COLOR}-${env.IMAGE_TAG} \
            frontend-${env.NEXT_COLOR}-${env.IMAGE_TAG} \
            ${env.NEXT_COLOR}
        """
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('Switch Traffic (Blue/Green)') {
      steps {
        echo "🔄 Switching traffic to ${env.NEXT_COLOR}..."
        sh """
          chmod +x scripts/switch-traffic.sh
          ./scripts/switch-traffic.sh manifests/base ${env.NAMESPACE}
        """
      }
    }

    /* -------------------------------------------------------------------------- */
    stage('GitOps Commit & Push') {
      steps {
        echo "📡 Committing manifest updates to GitHub..."
        sshagent (credentials: [env.GIT_CRED]) {
          sh '''
            set -e
            git config user.name "EdgeWave CI"
            git config user.email "ci@edgewave.dev"
            git remote set-url origin git@github.com:gauravchile/EdgeWave.git
            git fetch origin main
            git checkout main
            git add manifests/**/*.yaml

            if ! git diff --cached --quiet; then
              git commit -m "ci: deploy ${NEXT_COLOR} - version ${IMAGE_TAG}"
              git push origin main
              echo "✅ Manifest updates pushed to GitHub."
            else
              echo "ℹ️ No manifest changes detected."
            fi
          '''
        }
      }
    }
  }

  /* -------------------------------------------------------------------------- */
  post {
    success {
      script {
        def sonarSummary = fileExists('sonar-summary.txt') ? readFile('sonar-summary.txt') : 'No SonarQube summary found.'

        notify_email(
          env.EMAIL_RECIPIENT,
          "✅ EdgeWave Success • ${env.IMAGE_TAG}",
          """
            <b>✅ EdgeWave CI/CD Success</b><br>
            Version: <b>${env.IMAGE_TAG}</b><br>
            Deployed Color: <b>${env.NEXT_COLOR}</b><br>
            Repository: ${env.IMAGE_REPO}<br>
            Namespace: ${env.NAMESPACE}<br>
            <a href='${env.BUILD_URL}'>View Build Logs</a><br><br>

            <b>SonarQube Summary:</b><br>
            <pre>${sonarSummary}</pre>
            <a href='${env.SONAR_HOST}/dashboard?id=${env.SONAR_PROJECT}'>View Full SonarQube Dashboard</a>
          """
        )
      }
    }

    failure {
      script {
        notify_email(
          env.EMAIL_RECIPIENT,
          "❌ EdgeWave Failed • ${env.BUILD_NUMBER}",
          """
            <b>❌ EdgeWave Build Failed</b><br>
            Build: <a href='${env.BUILD_URL}'>#${env.BUILD_NUMBER}</a><br>
            Namespace: ${env.NAMESPACE}
          """
        )
      }
    }

    always {
      cleanWs()
    }
  }
}

/* -------------------------------------------------------------------------- */
/* Helper Function: Build & Push Docker Images */
/* -------------------------------------------------------------------------- */
def buildAndPush(service) {
  dir(service) {
    retry(2) {
      echo "⚙️ Building ${service} image for ${env.NEXT_COLOR}..."
      docker_build([
        imageName: "${env.IMAGE_REPO}",
        imageTag : "${service}-${env.NEXT_COLOR}-${env.IMAGE_TAG}",
        buildArgs: "--build-arg BUILD_COLOR=${env.NEXT_COLOR}"
      ])

      docker_push([
        imageName  : "${env.IMAGE_REPO}",
        imageTag   : "${service}-${env.NEXT_COLOR}-${env.IMAGE_TAG}",
        credentials: env.DOCKER_CRED,
        pushLatest : true
      ])
    }
  }
}
