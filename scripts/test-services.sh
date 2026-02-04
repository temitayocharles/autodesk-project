#!/bin/bash
# Test all services

set -e

echo "🧪 Testing AEC Data Infrastructure Services..."
echo ""

BASE_URL="http://localhost:8080"
INGESTION_URL="http://localhost:8000"
API_URL="http://localhost:8002"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=$3
    
    echo -e "${BLUE}Testing: $name${NC}"
    
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status" -eq "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS: $name (HTTP $status)${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL: $name (Expected HTTP $expected_status, got $status)${NC}"
        return 1
    fi
}

# Test health endpoints
echo "--- Health Checks ---"
test_endpoint "Data Ingestion Health" "$INGESTION_URL/health" 200
test_endpoint "Data Ingestion Readiness" "$INGESTION_URL/ready" 200
test_endpoint "Data API Health" "$API_URL/health" 200
test_endpoint "Data API Readiness" "$API_URL/ready" 200
test_endpoint "Nginx Gateway" "$BASE_URL/health" 200

echo ""
echo "--- API Tests ---"

# Test file list endpoint
test_endpoint "List Files" "$API_URL/api/v1/files?page=1&per_page=10" 200

# Test file upload
echo -e "${BLUE}Testing: File Upload${NC}"
echo "Test file content" > /tmp/test-file.txt

response=$(curl -s -w "\n%{http_code}" -X POST \
    -F "file=@/tmp/test-file.txt" \
    -F "project_id=test-project" \
    -F "description=Test file upload" \
    "$INGESTION_URL/api/v1/files/upload")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✅ PASS: File Upload (HTTP $http_code)${NC}"
    file_id=$(echo "$body" | jq -r '.id')
    echo "   File ID: $file_id"
    
    # Test retrieving the file
    sleep 1
    test_endpoint "Get File Metadata" "$API_URL/api/v1/files/$file_id" 200
else
    echo -e "${RED}❌ FAIL: File Upload (HTTP $http_code)${NC}"
    echo "Response: $body"
fi

rm /tmp/test-file.txt

echo ""
echo "--- Metrics Endpoints ---"
test_endpoint "Ingestion Metrics" "$INGESTION_URL/metrics" 200
test_endpoint "API Metrics" "$API_URL/metrics" 200

echo ""
echo "=================================================="
echo "✅ All tests completed!"
echo ""
echo "View logs for more details:"
echo "  docker-compose logs -f"
