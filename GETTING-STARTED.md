# 🎯 Getting Started - Your First Steps

Welcome! This guide will walk you through your first steps with the AEC Data Infrastructure platform.

## Step 1: Verify Your Environment (10 minutes)

Open your terminal and navigate to the project directory:

```bash
cd /path/to/autodesk-project
# Or, if this repo has a .git directory:
# cd "$(git rev-parse --show-toplevel)"
```

Make the scripts executable:

```bash
chmod +x scripts/*.sh
```

Run the prerequisite checker:

```bash
./scripts/verify-prerequisites.sh
```

**What's happening?**
This script checks if you have all necessary tools installed:
- Docker & Docker Compose
- Python, Go, Node.js
- Kubernetes (kubectl)
- Terraform, Ansible
- AWS CLI
- And more...

**If you see errors:** Follow the installation instructions in [README.md](README.md)

## Step 2: Configure AWS (5 minutes)

You need AWS credentials to use S3 for file storage.

### 2.1: Configure AWS CLI

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key  
- Default region (e.g., `us-west-2`)
- Output format (use `json`)

### 2.2: Verify S3 Access

```bash
# List your buckets
aws s3 ls

# If you don't have a bucket, create one
aws s3 mb s3://aec-data-$(whoami)-$(date +%s)

# Note the bucket name - you'll need it!
```

### 2.3: Create Environment File

```bash
cd infrastructure/docker-compose
cp .env.example .env
```

Edit `.env` file (use `nano` or your favorite editor):

```bash
nano .env
```

Update these values:
```
AWS_ACCESS_KEY_ID=your_actual_key
AWS_SECRET_ACCESS_KEY=your_actual_secret
AWS_REGION=us-west-2
S3_BUCKET_NAME=your-bucket-name
```

Save and exit (Ctrl+X, then Y, then Enter in nano)

## Step 3: Start Docker Desktop (2 minutes)

1. Open Docker Desktop application
2. Wait for it to show "Docker Desktop is running"
3. **Important:** Enable Kubernetes:
   - Open Docker Desktop Settings
   - Go to "Kubernetes" tab
   - Check "Enable Kubernetes"
   - Click "Apply & Restart"
   - Wait for it to show "Kubernetes is running"

Verify Docker is running:

```bash
docker ps
```

You should see an empty table (no errors).

## Step 4: Pull and Start Services (5 minutes)

Now the exciting part! Let's pull the pre-built images and start everything.

```bash
cd /path/to/autodesk-project

# This script pulls images from GitHub Container Registry and starts services
./scripts/start-dev-environment.sh
```

**What's happening?**
- Pulling Data Ingestion Service from ghcr.io (Python/FastAPI)
- Pulling Data Processing Service from ghcr.io (Go)
- Pulling Data API Service from ghcr.io (Python/Flask)
- Starting all infrastructure services

**Note:** Images are pre-built by GitHub Actions and hosted at `ghcr.io/temitayocharles/autodesk-project/*`

**Want to build locally instead?** Use the local compose override:

```bash
USE_LOCAL_IMAGES=1 ./scripts/start-dev-environment.sh
```

This uses `infrastructure/docker-compose/docker-compose.local.yml` to build from source.

**What's happening?**
- Pulling/Starting PostgreSQL database
- Pulling/Starting Redis cache
- Pulling/Starting RabbitMQ message queue
- Pulling/Starting your 3 microservices from GitHub Container Registry
- Pulling/Starting Nginx as API gateway
- Pulling/Starting Prometheus for metrics
- Pulling/Starting Grafana for dashboards

## Step 5: Verify Everything is Running (5 minutes)

Check that all containers are running:

```bash
cd infrastructure/docker-compose
docker-compose ps
```

You should see all services as "Up" or "running".

### Test the services:

```bash
cd /path/to/autodesk-project
./scripts/test-services.sh
```

This script tests all your endpoints!

## Step 6: Explore Your Platform (10 minutes)

Open these URLs in your browser:

### 1. **Grafana Dashboard** - http://localhost:3000
- Login: `admin` / `admin`
- This is where you visualize metrics
- Click "Explore" to start querying

### 2. **Prometheus** - http://localhost:9090
- Metrics database
- Try query: `file_uploads_total`
- You'll see a graph!

### 3. **RabbitMQ Management** - http://localhost:15672
- Login: `guest` / `guest`
- Shows message queues
- See messages being processed

### 4. **Your APIs**:

Test the Data Ingestion API:
```bash
curl http://localhost:8000/health
```

Test the Data API:
```bash
curl http://localhost:8002/api/v1/files | jq
```

You should see sample data!

## Step 7: Upload Your First File (5 minutes)

Let's upload a test file to see the whole system in action!

Create a test file:
```bash
echo "This is my first AEC data file!" > ~/Desktop/test-building.txt
```

Upload it:
```bash
curl -X POST http://localhost:8000/api/v1/files/upload \
  -F "file=@$HOME/Desktop/test-building.txt" \
  -F "project_id=my-first-project" \
  -F "description=Test upload from tutorial" \
  | jq
```

**You should see:**
```json
{
  "id": 4,
  "filename": "test-building.txt",
  "s3_key": "uploads/my-first-project/20260204_123456_test-building.txt",
  "s3_bucket": "your-bucket-name",
  "file_size": 35,
  "upload_timestamp": "2026-02-04T12:34:56.789",
  "message": "File uploaded successfully"
}
```

🎉 **Congratulations!** Your file is now:
1. Uploaded to AWS S3
2. Metadata stored in PostgreSQL
3. Ready to be processed

Check it in S3:
```bash
aws s3 ls s3://your-bucket-name/uploads/my-first-project/
```

## Step 8: View Metrics (5 minutes)

Go to **Prometheus** (http://localhost:9090):

1. In the query box, enter: `file_uploads_total`
2. Click "Execute"
3. Switch to "Graph" tab
4. You'll see your upload counted!

Go to **Grafana** (http://localhost:3000):

1. Click "Explore" in left sidebar
2. Make sure "Prometheus" is selected as data source
3. Enter query: `rate(file_uploads_total[5m])`
4. Run query
5. You see upload rate!

## Step 9: View Logs (5 minutes)

See what's happening inside your services:

```bash
cd /path/to/autodesk-project/infrastructure/docker-compose

# All logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# Logs for specific service
docker-compose logs -f data-ingestion-service

# Last 50 lines
docker-compose logs --tail=50 data-api-service
```

**Press Ctrl+C to stop following logs**

## Step 10: Understand What You Built (10 minutes)

You now have a production-grade microservices platform!

**Architecture:**
```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
┌──────▼──────┐
│    Nginx    │ ← API Gateway (Load Balancer)
└──────┬──────┘
       │
       ├──────────────────┬────────────────────┐
       │                  │                    │
┌──────▼──────┐   ┌───────▼──────┐   ┌────────▼─────┐
│  Ingestion  │   │  Processing  │   │   Data API   │
│   Service   │   │   Service    │   │   Service    │
│  (FastAPI)  │   │     (Go)     │   │   (Flask)    │
└──────┬──────┘   └───────┬──────┘   └────────┬─────┘
       │                  │                    │
       ├─────────┬────────┼────────┬───────────┤
       │         │        │        │           │
┌──────▼──┐ ┌───▼────┐ ┌─▼──────┐ ┌──────▼──┐ ┌─▼────────┐
│PostgreSQL│ │  Redis │ │RabbitMQ│ │   S3    │ │Prometheus│
└──────────┘ └────────┘ └────────┘ └─────────┘ └──────────┘
```

**What each service does:**

1. **Data Ingestion Service** (Python/FastAPI)
   - Accepts file uploads (like CAD/BIM files)
   - Validates files
   - Stores in S3
   - Saves metadata to PostgreSQL

2. **Data Processing Service** (Go)
   - Listens to message queue
   - Processes files asynchronously
   - High performance with goroutines

3. **Data API Service** (Python/Flask)
   - REST API for retrieving data
   - Uses Redis for caching
   - Rate limiting
   - Efficient queries

4. **Supporting Infrastructure:**
   - **PostgreSQL**: Stores metadata
   - **Redis**: Caches API responses
   - **RabbitMQ**: Message queue for async processing
   - **Nginx**: Load balancer / API gateway
   - **Prometheus**: Collects metrics
   - **Grafana**: Visualizes everything

## Common Commands

### View service status:
```bash
cd infrastructure/docker-compose
docker-compose ps
```

### Restart a service:
```bash
docker-compose restart data-ingestion-service
```

### Stop everything:
```bash
docker-compose down
```

### Start everything:
```bash
docker-compose up -d
```

### View resource usage:
```bash
docker stats
```

### Access database directly:
```bash
docker-compose exec postgres psql -U postgres -d aec_data
```

Then try:
```sql
SELECT * FROM file_metadata;
```

Type `\q` to exit.

## Troubleshooting

### Port already in use?
```bash
# Find what's using port 8000
lsof -i :8000

# Kill it
kill -9 <PID>
```

### Service won't start?
```bash
# Check logs
docker-compose logs <service-name>

# Rebuild
docker-compose up -d --build <service-name>
```

### AWS connection issues?
```bash
# Verify credentials
aws sts get-caller-identity

# Re-configure
aws configure
```

### Can't connect to database?
```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Restart it
docker-compose restart postgres
```

## Next Steps

Now that everything is running, continue with the full tutorial:

1. **Read [TUTORIAL.md](TUTORIAL.md)** - Comprehensive guide through each phase
2. **Explore the code** - Look at service implementations
3. **Make changes** - Edit code and see it in action
4. **Deploy to Kubernetes** - Next level orchestration
5. **Set up CI/CD** - Automate everything with Jenkins

## 🎓 Learning Resources

As you go through the project:

- **Docker:** https://docs.docker.com/
- **Kubernetes:** https://kubernetes.io/docs/tutorials/
- **Prometheus:** https://prometheus.io/docs/introduction/overview/
- **FastAPI:** https://fastapi.tiangolo.com/
- **Go:** https://go.dev/tour/

## 🤔 Questions?

As you learn, document your questions. This is great practice for:
1. Understanding what you're building
2. Preparing for interviews
3. Building your knowledge base

## 🚀 You're Ready!

You now have:
- ✅ A running microservices platform
- ✅ Hands-on experience with Docker
- ✅ Working knowledge of multiple services
- ✅ Metrics and monitoring setup
- ✅ Real DevOps infrastructure

**Continue to Phase 2 in TUTORIAL.md to dive deeper into each component!**
