# 🎯 Your 7-Day Action Plan - Interview Ready

## Today: Get It Running (2-3 hours)

### ✅ Checkpoint 1: Prerequisites (30 min)
```bash
cd /Users/charlie/Desktop/autodesk-project
./scripts/verify-prerequisites.sh
```

**If anything fails:**
- Docker not running? → Open Docker Desktop
- AWS CLI missing? → `brew install awscli`
- Go/Python missing? → Install from README.md

### ✅ Checkpoint 2: AWS Setup (15 min)
```bash
# Configure AWS
aws configure
# Enter: Access Key, Secret Key, Region (us-west-2), Format (json)

# Verify
aws s3 ls

# Create bucket if needed (note the name!)
aws s3 mb s3://aec-data-$(whoami)-$(date +%s)
```

### ✅ Checkpoint 3: Environment Config (10 min)
```bash
cd infrastructure/docker-compose
cp .env.example .env
nano .env
```

**Update these lines:**
```
AWS_ACCESS_KEY_ID=YOUR_ACTUAL_KEY
AWS_SECRET_ACCESS_KEY=YOUR_ACTUAL_SECRET
S3_BUCKET_NAME=your-bucket-name-from-above
```

### ✅ Checkpoint 4: Build Everything (20 min)
```bash
cd /Users/charlie/Desktop/autodesk-project
./scripts/build-all.sh
```

**Expected:** See "✅" for each service built

### ✅ Checkpoint 5: Start Platform (15 min)
```bash
./scripts/start-dev-environment.sh
```

**Expected:** All services show "healthy"

### ✅ Checkpoint 6: Test It Works (10 min)
```bash
./scripts/test-services.sh
```

**Expected:** All tests pass ✅

### ✅ Checkpoint 7: Explore (30 min)
Open these in your browser:
- http://localhost:3000 (Grafana - login: admin/admin)
- http://localhost:9090 (Prometheus - try query: `file_uploads_total`)
- http://localhost:15672 (RabbitMQ - login: guest/guest)

Upload a test file:
```bash
echo "My first AEC file" > ~/Desktop/test.txt
curl -X POST http://localhost:8000/api/v1/files/upload \
  -F "file=@$HOME/Desktop/test.txt" \
  -F "project_id=demo" | jq
```

**✅ TODAY'S SUCCESS:** Everything is running!

---

## Day 2: Understand Data Ingestion Service (2-3 hours)

### Morning: Read the Code (1 hour)

#### 1. Open the service:
```bash
cd services/data-ingestion-service
code . # or your editor
```

#### 2. Trace a request (follow this path):
```
app/main.py → upload_file() function
    ↓
1. Receives file from client
2. Validates file type
3. Uploads to S3 (boto3)
4. Stores metadata in PostgreSQL
5. Returns response
```

#### 3. Key concepts to understand:
- **FastAPI** - Why async? (handles I/O efficiently)
- **Pydantic** - What's schema validation? (type safety)
- **SQLAlchemy** - How does it connect to DB? (ORM pattern)
- **Health checks** - Why /health and /ready? (K8s probes)

### Afternoon: Experiment (1 hour)

#### Experiment 1: Break it, fix it
```bash
# Stop the database
docker-compose stop postgres

# Try uploading - it should fail
curl http://localhost:8000/api/v1/files/upload ...

# Check logs - see the error
docker-compose logs data-ingestion-service

# Fix it
docker-compose start postgres
```

#### Experiment 2: Add a feature
Add to `app/main.py`:
```python
@app.get("/api/v1/stats")
async def get_stats(db: Session = Depends(get_db)):
    total = db.query(models.FileMetadata).count()
    return {"total_files": total}
```

Rebuild and test:
```bash
docker-compose up -d --build data-ingestion-service
curl http://localhost:8000/api/v1/stats
```

### Practice Explanation (30 min)

**Record yourself explaining:**
1. "This service handles file uploads for AEC data..."
2. "We use FastAPI because..."
3. "The flow is: client → validation → S3 → database..."
4. "For production, we'd add: retry logic, file chunking, virus scanning..."

**✅ DAY 2 SUCCESS:** You understand the ingestion service deeply

---

## Day 3: Understand Processing Service (Go) (2-3 hours)

### Morning: Read the Code (1 hour)

```bash
cd services/data-processing-service
code main.go
```

#### Trace the flow:
```
main() 
  ↓
connectRabbitMQ() → Get messages from queue
  ↓
worker() goroutines (5 concurrent workers)
  ↓
processMessage() → Do the work
  ↓
Ack/Nack message
```

#### Key Go concepts:
- **Goroutines** - Like lightweight threads (line 90+)
- **Channels** - How goroutines communicate (msgs channel)
- **Error handling** - Explicit returns, no exceptions
- **Defer** - Cleanup resources (defer conn.Close())

### Afternoon: Experiment (1 hour)

#### Experiment 1: See workers in action
```bash
# Watch the logs
docker-compose logs -f data-processing-service

# Send test message (from Python or curl)
# Watch workers process it
```

#### Experiment 2: Add processing logic
In `processMessage()`, add:
```go
log.WithFields(log.Fields{
    "file_size": msg.FileSize,
    "duration": time.Since(startTime),
}).Info("Processing completed")
```

### Practice Explanation (30 min)

**Record yourself:**
1. "This service uses Go for high-performance processing..."
2. "Goroutines let us process 5 files concurrently..."
3. "RabbitMQ decouples services - ingestion doesn't wait..."
4. "We use channels for safe communication between goroutines..."

**✅ DAY 3 SUCCESS:** You understand async processing

---

## Day 4: Understand API Service + Infrastructure (2-3 hours)

### Morning: API Service (1 hour)

```bash
cd services/data-api-service
code app.py
```

#### Key features:
- **Redis caching** - `@cache_result` decorator (line 90+)
- **Rate limiting** - `@limiter.limit` decorator
- **Pagination** - Query parameters
- **Metrics** - Prometheus counters/histograms

#### Trace a cached query:
```
Client request → API
  ↓
Check Redis cache
  ↓
HIT? → Return cached result
  ↓
MISS? → Query DB → Cache result → Return
```

### Afternoon: Infrastructure (1 hour)

#### Understand Docker Compose:
```bash
cd infrastructure/docker-compose
cat docker-compose.yml
```

**Key sections:**
- **Services** - Each container definition
- **Networks** - How services communicate
- **Volumes** - Data persistence
- **Health checks** - When is a service ready?
- **Depends_on** - Startup order

#### Understand Kubernetes:
```bash
cd kubernetes/manifests
ls -la
```

**Key concepts:**
- **Deployment** - Manages pods
- **Service** - Stable network endpoint
- **ConfigMap** - Configuration
- **Secrets** - Sensitive data
- **Ingress** - External access

### Practice Explanation (30 min)

**Explain:**
1. "The API uses Redis to avoid database queries..."
2. "Rate limiting prevents abuse..."
3. "Docker Compose orchestrates local development..."
4. "Kubernetes orchestrates production with scaling and self-healing..."

**✅ DAY 4 SUCCESS:** You understand the full stack

---

## Day 5: Monitoring & Troubleshooting (2-3 hours)

### Morning: Metrics (1 hour)

#### Explore Prometheus:
1. Open http://localhost:9090
2. Try these queries:
```
# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# File uploads
file_uploads_total

# By status
file_uploads_total{status="success"}
```

#### Create Grafana Dashboard:
1. Open http://localhost:3000
2. Create → Dashboard → Add Panel
3. Query: `rate(file_uploads_total[5m])`
4. Save dashboard

### Afternoon: Troubleshooting Practice (1 hour)

#### Exercise 1: Service Down
```bash
# Kill a service
docker-compose stop data-ingestion-service

# How do you know? 
# → Check http://localhost:8000/health (fails)
# → Check Prometheus: up{job="data-ingestion"} = 0
# → Check Grafana dashboard

# Fix it
docker-compose start data-ingestion-service
```

#### Exercise 2: Database Connection Issue
```bash
# Simulate DB issue
docker-compose stop postgres

# What happens?
# → API queries fail
# → Check logs: docker-compose logs data-api-service
# → See connection errors

# Fix and verify
docker-compose start postgres
```

#### Exercise 3: High Load
```bash
# Send many requests
for i in {1..100}; do
  curl http://localhost:8002/api/v1/files &
done

# Watch metrics
# → Request rate increases
# → Response time may increase
# → Cache hit ratio (if implemented)
```

### Practice Explanation (30 min)

**Troubleshooting scenario:**
"Service is slow. Here's my process:
1. Check Grafana - see high latency
2. Check Prometheus - high request rate? DB slow?
3. Check logs - any errors?
4. Check resources - kubectl top pods
5. Solution: Scale up or optimize queries"

**✅ DAY 5 SUCCESS:** You can monitor and troubleshoot

---

## Day 6: Kubernetes & CI/CD Mastery (3-4 hours)

### Morning: Kubernetes Deep Dive (90 min)

#### Deploy to K8s:
```bash
# Ensure Kubernetes is running
kubectl cluster-info

# Deploy
./scripts/deploy-local.sh

# Watch pods start
kubectl get pods -n aec-data -w
```

#### Explore:
```bash
# View all resources
kubectl get all -n aec-data

# Describe a pod
kubectl describe pod data-ingestion-service-xxx -n aec-data

# View logs
kubectl logs -f data-ingestion-service-xxx -n aec-data

# Execute into pod
kubectl exec -it data-ingestion-service-xxx -n aec-data -- /bin/sh

# Check environment
env | grep DATABASE
```

#### Understand key concepts:
- **Replicas** - Multiple pods for HA
- **Rolling update** - Zero-downtime deployment
- **Self-healing** - Pods restart automatically
- **Service discovery** - Pods find each other by name

### Afternoon: Master All Three CI/CD Tools (2-3 hours)

**You now have THREE CI/CD approaches:**
- 🏢 **Jenkins** - Enterprise standard
- ☁️ **GitHub Actions** - Modern cloud-native
- 🚀 **ArgoCD** - GitOps cutting-edge

#### 1. Compare CI/CD Approaches (30 min)

**Read and understand:**
```bash
cd ci-cd
cat README.md  # Complete comparison of all three tools
```

**Key differences:**
- **Jenkins**: Self-hosted, push-based, traditional enterprise
- **GitHub Actions**: Cloud-hosted, zero setup, modern
- **ArgoCD**: Kubernetes-native, pull-based, GitOps

**Interview gold:** "I've implemented Jenkins for enterprise, GitHub Actions for modern workflows, and ArgoCD for GitOps."

#### 2. Read the Jenkinsfile (20 min)
```bash
cd ci-cd/jenkins
cat Jenkinsfile
```

**Understand stages:**
1. Checkout → Get code
2. Test → Run tests
3. Build → Docker images
4. Scan → Security check
5. Push → Registry
6. Deploy → Kubernetes
7. Verify → Smoke tests

#### 3. Review GitHub Actions Workflow (20 min)

**Open and analyze:**
```bash
cat .github/workflows/ci.yml
```

**Key features:**
- Matrix builds (parallel testing)
- GitHub Container Registry
- Security scanning with Trivy
- Auto-triggers on push/PR
- Zero infrastructure setup

**Try it (optional - requires GitHub repo):**
```bash
# Push to GitHub to see it run
git init
git add .
git commit -m "Add GitHub Actions"
git remote add origin https://github.com/YOUR-USERNAME/autodesk-project.git
git push -u origin main
# Watch Actions tab in GitHub!
```

#### 4. Setup ArgoCD (GitOps) (30 min)

**Read the guide:**
```bash
cat ci-cd/argocd/ARGOCD-GUIDE.md
```

**Install ArgoCD:**
```bash
# Install to K8s
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ready
kubectl wait --for=condition=available --timeout=300s deployment --all -n argocd

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

**Open:** https://localhost:8080 (Login: admin / password-from-above)

**Deploy your app (optional):**
```bash
# Update repo URL first
sed -i '' 's|YOUR-USERNAME|youractual-username|g' ci-cd/argocd/application.yaml

# Deploy
kubectl apply -f ci-cd/argocd/application.yaml

# Watch it sync!
open https://localhost:8080
```

**What you'll see:**
- Beautiful visual of all your K8s resources
- Auto-sync when you push Git changes
- Self-healing if you manually edit K8s
- One-click rollback

#### 5. Practice Explaining CI/CD (30 min)

**Practice explaining each approach:**

**Jenkins:**
"When code is pushed, Jenkins webhook triggers. Tests run in parallel—Python services with pytest, Go with race detector. If tests pass, we build multi-stage Docker images, scan for vulnerabilities with Trivy, push to registry, then deploy to Kubernetes with zero downtime using rolling updates. Health checks ensure new pods are ready before old ones terminate."

**GitHub Actions:**
"I've implemented GitHub Actions for modern cloud-native CI/CD. Matrix builds test multiple services in parallel, security scanning is built in, and it integrates directly with GitHub Container Registry. Zero infrastructure overhead—it just works."

**ArgoCD (GitOps):**
"For continuous delivery, I use ArgoCD which implements GitOps. Git is the single source of truth. ArgoCD watches the Git repo and automatically syncs the Kubernetes cluster to match. If someone manually changes the cluster, it self-heals back to the Git state. Rollback is just a Git revert—instant and auditable."

**Combined approach:**
"In production, I'd use GitHub Actions for CI—build, test, scan—then push image tags to Git. ArgoCD watches Git and handles CD—deploying to Kubernetes. This separates concerns: CI handles artifacts, CD handles deployments. Jenkins is great too for complex enterprise needs."

**✅ DAY 6 SUCCESS:** You understand K8s and three CI/CD approaches deeply!

---

## Day 7: Interview Preparation (3-4 hours)

### Morning: Technical Practice (2 hours)

#### 1. Architecture Whiteboard (30 min)
Draw the architecture from memory:
- Services
- Databases
- Message queue
- Flow of data

**Practice explaining to camera/friend**

#### 2. Key Questions (60 min)

**Q: Walk me through the architecture**
**A:** "We have three microservices. The ingestion service handles uploads to S3 and stores metadata. The processing service handles async work via RabbitMQ. The API service provides cached queries. Everything runs in Kubernetes with Prometheus monitoring."

**Q: Why microservices?**
**A:** "Independent scaling, technology optimization - Go for processing, Python for APIs. Also fault isolation and team autonomy."

**Q: How do you handle failures?**
**A:** "Multiple layers: health checks restart pods, message requeue on failure, database transactions for consistency, monitoring alerts on issues."

**Q: How would you scale this?**
**A:** "Horizontal pod autoscaling based on CPU/memory or custom metrics like queue depth. Database read replicas. Redis cluster. CDN for static content."

**Q: Security approach?**
**A:** "Defense in depth: network policies, RBAC, secrets in Vault, non-root containers, image scanning, TLS everywhere, rate limiting."

**Q: Why three different CI/CD tools?**
**A:** "To demonstrate breadth and adaptability. Jenkins for enterprise standards, GitHub Actions for modern cloud workflows, ArgoCD for GitOps best practices. Each has its place depending on context."

**Q: What's GitOps and why use it?**
**A:** "GitOps uses Git as single source of truth. ArgoCD watches Git and syncs Kubernetes to match. Benefits: audit trail via Git history, instant rollback via Git revert, self-healing, and no cluster credentials in CI pipeline."

#### 3. Demo Practice (30 min)
Record yourself giving a 5-minute demo:
- Show services running
- Upload a file
- Show in Grafana
- Explain what's happening

### Afternoon: Behavioral + Polish (2 hours)

#### 1. Behavioral Questions (60 min)

**Q: Tell me about a complex problem you solved**
**A:** "In this project, I needed to handle large file uploads efficiently. I implemented direct S3 uploads with multipart, async processing via message queue, and retry logic. This handles GBs without blocking."

**Q: How do you handle production incidents?**
**A:** "Follow the monitoring → logs → metrics → fix workflow. In this project, if upload service fails, Grafana alerts, I check Prometheus for which service, logs for errors, then fix and verify."

**Q: How do you prioritize?**
**A:** "Impact vs effort. Security and data integrity are non-negotiable. Performance optimizations come after correctness. I'd prioritize user-facing issues over internal tooling."

#### 2. Questions for Them (30 min)

Prepare thoughtful questions:
1. "What are the biggest DevOps challenges the AEC Data team faces?"
2. "How do you balance deployment velocity with reliability?"
3. "What's the team's approach to on-call and incident management?"
4. "What technologies is the team evaluating or migrating to?"
5. "How do you measure success in this role?"

#### 3. Polish Your Presentation (30 min)

Create a simple slide deck:
- Slide 1: Architecture diagram
- Slide 2: Tech stack
- Slide 3: Key features (scalability, monitoring, security)
- Slide 4: What I learned
- Slide 5: How this applies to Autodesk

**✅ DAY 7 SUCCESS:** You're interview ready!

---

## Daily Checklist Template

```
[ ] Reviewed today's material
[ ] Ran the code/commands
[ ] Made a small change
[ ] Explained it out loud
[ ] Documented any questions
[ ] 30-min practice session
```

---

## Quick Reference Commands

### Daily Operations:
```bash
# Start everything
cd /Users/charlie/Desktop/autodesk-project
./scripts/start-dev-environment.sh

# Check status
docker-compose ps
kubectl get pods -n aec-data

# View logs
docker-compose logs -f [service-name]
kubectl logs -f [pod-name] -n aec-data

# Restart a service
docker-compose restart [service-name]
kubectl rollout restart deployment/[service] -n aec-data

# Stop everything
docker-compose down
```

### Testing:
```bash
# Run tests
./scripts/test-services.sh

# Manual API test
curl http://localhost:8000/health
curl http://localhost:8002/api/v1/files | jq

# Upload file
curl -X POST http://localhost:8000/api/v1/files/upload \
  -F "file=@/path/to/file.txt" \
  -F "project_id=test" | jq
```

### Monitoring:
```bash
# Prometheus queries
open http://localhost:9090
# Query: rate(http_requests_total[5m])

# Grafana dashboards
open http://localhost:3000
# Login: admin/admin

# RabbitMQ
open http://localhost:15672
# Login: guest/guest
```

---

## Success Metrics

### Week 1 Complete When:
✅ All services running locally  
✅ Can upload files successfully  
✅ Understand each service's purpose  
✅ Can read and modify code  
✅ Can troubleshoot basic issues  

### Interview Ready When:
✅ Can explain architecture in 2 minutes  
✅ Can demo working platform  
✅ Can answer "why X?" for each tech choice  
✅ Can troubleshoot live issues  
✅ Can discuss scaling/security  
✅ Have 5+ questions for interviewers  

---

## Emergency Troubleshooting

### Nothing works:
```bash
# Nuclear option - clean restart
docker-compose down -v
docker system prune -a
./scripts/build-all.sh
./scripts/start-dev-environment.sh
```

### Port conflicts:
```bash
# Find what's using port
lsof -i :8000
# Kill it
kill -9 [PID]
```

### AWS issues:
```bash
# Verify credentials
aws sts get-caller-identity
# Re-configure
aws configure
```

---

## Final Tips

1. **Don't rush** - Deep understanding > completion
2. **Break things** - Best way to learn
3. **Document questions** - Great interview material
4. **Practice explaining** - Technical communication matters
5. **Stay curious** - "Why?" is the most important question

---

**You've got 7 days. Follow this plan. You'll be ready.**

**Start now: Get it running today!** 🚀
