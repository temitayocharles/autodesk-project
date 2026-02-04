# Jenkins Setup Guide

## Prerequisites

- Jenkins installed (via Homebrew on macOS)
- Docker installed and running
- Kubernetes cluster accessible
- Git repository configured

## Installation

### 1. Install Jenkins

```bash
brew install jenkins-lts
```

### 2. Start Jenkins

```bash
brew services start jenkins-lts
```

### 3. Access Jenkins

Open http://localhost:8080 in your browser.

### 4. Initial Setup

Get the initial admin password:

```bash
cat ~/.jenkins/secrets/initialAdminPassword
```

Paste this password in the Jenkins setup wizard.

### 5. Install Plugins

Install these plugins:
- Docker Pipeline
- Kubernetes
- Git
- Pipeline
- Blue Ocean (recommended)
- Prometheus Metrics

**Installation Steps:**
1. Go to "Manage Jenkins" → "Manage Plugins"
2. Click "Available" tab
3. Search for each plugin
4. Check the box
5. Click "Install without restart"

## Configure Jenkins

### 1. Configure Docker

**Manage Jenkins → Manage Nodes and Clouds → Configure Clouds**

1. Add "Docker"
2. Docker Host URI: `unix:///var/run/docker.sock`
3. Test Connection
4. Save

### 2. Add Credentials

**Manage Jenkins → Manage Credentials → Global → Add Credentials**

#### AWS Credentials:
- Kind: AWS Credentials
- ID: `aws-credentials`
- Access Key ID: Your AWS key
- Secret Access Key: Your AWS secret

#### Docker Registry:
- Kind: Username with password
- ID: `docker-registry-credentials`
- Username: your-username
- Password: your-password

#### Kubeconfig:
- Kind: Secret file
- ID: `kubeconfig`
- File: Upload your ~/.kube/config

### 3. Create Pipeline Job

1. Click "New Item"
2. Enter name: "aec-data-platform"
3. Select "Pipeline"
4. Click OK

#### Configure Pipeline:

**General:**
- ✅ GitHub project
- Project URL: your-repo-url

**Build Triggers:**
- ✅ Poll SCM: `H/5 * * * *` (every 5 minutes)
- Or ✅ GitHub hook trigger for GITScm polling

**Pipeline:**
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: your-repo-url
- Branch: */main
- Script Path: ci-cd/jenkins/Jenkinsfile

Click "Save"

### 4. Test Pipeline

1. Click "Build Now"
2. Watch build in "Blue Ocean" view
3. Check console output

## Pipeline Stages

The Jenkinsfile includes these stages:

1. **Checkout** - Get code from Git
2. **Environment Info** - Display build info
3. **Test - Services** - Run unit tests (parallel)
4. **Security Scan** - Scan dependencies
5. **Build Docker Images** - Build all services (parallel)
6. **Container Security Scan** - Scan images with Trivy
7. **Push to Registry** - Push images (main branch only)
8. **Deploy to Kubernetes** - Deploy to cluster (main branch only)
9. **Smoke Tests** - Verify deployment

## Advanced Configuration

### Multi-Branch Pipeline

For better Git workflow:

1. Create "Multibranch Pipeline"
2. Configure Branch Sources → Git
3. Behaviors: Discover branches
4. Build Configuration: by Jenkinsfile

This automatically creates pipelines for each branch!

### Build Triggers

#### GitHub Webhooks:
1. In GitHub repo: Settings → Webhooks
2. Add webhook:
   - URL: `http://your-jenkins-url:8080/github-webhook/`
   - Content type: application/json
   - Events: Just the push event
3. Save

#### Scheduled Builds:
```groovy
triggers {
    cron('H H(0-7) * * *')  // Nightly build
}
```

### Environment-Specific Deployments

Add parameters:

```groovy
parameters {
    choice(
        name: 'ENVIRONMENT',
        choices: ['dev', 'staging', 'prod'],
        description: 'Deployment environment'
    )
}
```

### Notifications

#### Slack Integration:

```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: "Build ${env.BUILD_NUMBER} succeeded: ${env.BUILD_URL}"
        )
    }
    failure {
        slackSend(
            color: 'danger',
            message: "Build ${env.BUILD_NUMBER} failed: ${env.BUILD_URL}"
        )
    }
}
```

## Monitoring Jenkins

### Metrics

Install "Prometheus Metrics" plugin:

1. Manage Jenkins → Configure System
2. Prometheus section
3. Enable metrics collection
4. Save

Access metrics at: `http://localhost:8080/prometheus`

### Add to Prometheus Config

```yaml
scrape_configs:
  - job_name: 'jenkins'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: /prometheus
```

## Troubleshooting

### Build Fails at Docker Stage

**Error:** Cannot connect to Docker daemon

**Solution:**
```bash
# Give Jenkins access to Docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Kubernetes Deployment Fails

**Error:** Unable to connect to cluster

**Solution:**
1. Verify kubeconfig credentials
2. Test: `kubectl cluster-info`
3. Re-upload kubeconfig to Jenkins

### Out of Disk Space

**Solution:**
```bash
# Clean old builds
cd ~/.jenkins/jobs/*/builds
rm -rf [0-9]*

# Clean Docker
docker system prune -a -f
```

### Slow Builds

**Optimizations:**
1. Use Docker layer caching
2. Parallel stages
3. Incremental builds
4. Separate agents for heavy tasks

## Best Practices

### 1. Use Shared Libraries

Create reusable pipeline code:

```groovy
@Library('my-shared-library') _

dockerBuild {
    imageName = 'my-service'
}
```

### 2. Declarative > Scripted

Use declarative syntax (like our Jenkinsfile) for:
- Better readability
- Easier maintenance
- Built-in features

### 3. Security

- Store secrets in Jenkins Credentials
- Use least privilege for service accounts
- Scan containers before deployment
- Enable CSRF protection

### 4. Pipeline as Code

- Version control Jenkinsfile
- Review pipeline changes like code
- Test pipeline changes in branches

### 5. Monitoring

- Set up build alerts
- Monitor build times
- Track success rates
- Use Blue Ocean for visualization

## Local Development

### Test Jenkinsfile Locally

```bash
# Install Jenkins CLI
brew install jenkins

# Validate Jenkinsfile
jenkins-cli -s http://localhost:8080 declarative-linter < Jenkinsfile
```

### Use Docker for Jenkins

```bash
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

## Next Steps

1. **Set up staging environment** for testing before production
2. **Implement blue-green deployments** for zero-downtime
3. **Add integration tests** that run against deployed services
4. **Set up artifact repository** (Artifactory, Nexus)
5. **Implement GitOps** with ArgoCD or FluxCD

## Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Best Practices](https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/)
- [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)

---

**Your CI/CD pipeline is now ready! Every code push will automatically build, test, and deploy your services.**
