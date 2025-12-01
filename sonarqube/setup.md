# 🧠 SonarQube + Jenkins Integration Setup Guide

This guide walks you through connecting **SonarQube (Docker)** with **Jenkins** to enable automated code analysis inside your EdgeWave CI/CD pipeline.

---

## ⚙️ 1️⃣ Run SonarQube on Docker

**File:** `sonarqube/sonarqube.yml`

```yaml
version: '3.8'
services:
  sonarqube:
    image: sonarqube:latest
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: "true"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs

  db:
    image: postgres:13
    container_name: sonar-postgres
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    volumes:
      - sonar_pg_data:/var/lib/postgresql/data

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  sonar_pg_data:
```

Run SonarQube with:

```bash
docker compose -f sonarqube/sonarqube.yml up -d
```

Access: **[http://localhost:9000](http://localhost:9000)**
Default login: `admin / admin`

Then:

1. Change the default password.
2. Generate a **token** for Jenkins (e.g., `jenkins-token`).

---

## ⚙️ 2️⃣ Configure SonarQube in Jenkins

Go to **Manage Jenkins → Configure System → SonarQube Servers**

### Add a New SonarQube Server

| Field                           | Example                                      |
| ------------------------------- | -------------------------------------------- |
| **Name**                        | `local-sonarqube` ✅                         |
| **Server URL**                  | `http://localhost:9000`                      |
| **Server authentication token** | *(Paste the token you created in SonarQube)* |

Click ✅ **Save**.

---

## 🧰 3️⃣ Add SonarQube Scanner in Jenkins

Go to **Manage Jenkins → Global Tool Configuration → SonarQube Scanner**

Click **Add SonarQube Scanner**:

| Field                     | Example           |
| ------------------------- | ----------------- |
| **Name**                  | `sonar-scanner`   |
| **Install automatically** | ✔️ checked         |

Click ✅ **Save**.

---

## 🌐 4️⃣ Add Global Environment Variables

Go to **Manage Jenkins → Configure System → Global properties → Environment variables**
Add the following:

| Name             | Value                          |
| ---------------- | ------------------------------ |
| `SONARQUBE_ENV`  | `local-sonarqube`              |
| `SONAR_HOST_URL` | `http://localhost:9000`        |
| `SONAR_TOKEN`    | `<your-generated-sonar-token>` |

---

## 🔐 5️⃣ Verify Jenkins Credential

If you used Jenkins credentials store instead of plain env vars:

1. Go to **Manage Jenkins → Credentials → (Global)** → Add Credentials.
2. Choose **Secret Text**.
3. Add:

   * **ID:** `sonar-token`
   * **Secret:** *(your SonarQube token)*
4. Save.

Then your Jenkinsfile can use:

```groovy
environment {
  SONARQUBE_ENV = 'local-sonarqube'
  SONAR_HOST_URL = credentials('sonar-host-url')
  SONAR_TOKEN = credentials('sonar-token')
}
```

---

## 🧪 6️⃣ Test the Integration

Create a quick test pipeline in Jenkins:

```groovy
pipeline {
  agent any
  stages {
    stage('Test SonarQube Connection') {
      steps {
        withSonarQubeEnv('local-sonarqube') {
          sh 'echo "SonarQube environment configured successfully!"'
        }
      }
    }
  }
}
```

✅ If this runs without error, your Jenkins ↔ SonarQube integration is working!

---

## 🚀 7️⃣ SonarQube in EdgeWave Pipeline

In your main Jenkinsfile:

```groovy
stage('SonarQube Scan') {
  steps {
    sonarqube_scan(
      projectKey: 'edgewave',
      sources: 'backend,frontend',
      scannerTool: 'sonar-scanner',
      sonarEnv: env.SONARQUBE_ENV
    )
  }
}
```

This will:

* Use the Sonar Scanner tool installed on Jenkins
* Send scan results to your local SonarQube server
* Display metrics and quality gate status on the SonarQube dashboard

---

## ✅ Final Checklist

| Component              | Description                                     | Status  |
| ---------------------- | ----------------------------------------------- | ------- |
| 🐳 SonarQube container | Running on Docker                               | ✅      |
| 🧩 Jenkins plugin      | SonarQube + Sonar Scanner installed             | ✅      |
| 🔑 Token               | Added to Jenkins credentials                    | ✅      |
| ⚙️ SONARQUBE_ENV        | Matches Jenkins server name (`local-sonarqube`) | ✅      |
| 🧠 Quality Gate        | Configured in SonarQube                         | ✅      |

---
