# ChainFinity Backend Deployment Guide

This guide provides comprehensive instructions for deploying the ChainFinity backend in various environments, from development to production.

## 📋 Prerequisites

### System Requirements

- **Operating System**: Ubuntu 20.04+ / CentOS 8+ / macOS 10.15+
- **Python**: 3.11 or higher
- **Memory**: Minimum 4GB RAM (8GB+ recommended for production)
- **Storage**: Minimum 20GB available space
- **Network**: Stable internet connection for blockchain RPC access

### Required Services

- **PostgreSQL**: 15.0 or higher
- **Redis**: 7.0 or higher
- **Docker**: 20.10+ (for containerized deployment)
- **Docker Compose**: 2.0+ (for multi-service deployment)

## 🚀 Quick Start (Development)

### 1. Environment Setup

```bash
# Clone the repository
git clone <repository-url>
cd chainfinity_backend_production

# Create and activate virtual environment
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Database Setup

```bash
# Start PostgreSQL (using Docker)
docker run -d \
  --name chainfinity_postgres \
  -e POSTGRES_DB=chainfinity \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:15-alpine

# Start Redis (using Docker)
docker run -d \
  --name chainfinity_redis \
  -p 6379:6379 \
  redis:7-alpine
```

### 3. Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit configuration (use your preferred editor)
nano .env
```

**Key configuration items for development:**

```bash
# Application
ENVIRONMENT=development
DEBUG=true
HOST=0.0.0.0
PORT=8000

# Database
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/chainfinity
REDIS_URL=redis://localhost:6379/0

# Security (generate new keys for production)
SECRET_KEY=your-development-secret-key
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Blockchain (use testnet for development)
ETH_RPC_URL=https://goerli.infura.io/v3/YOUR_PROJECT_ID
ETH_CHAIN_ID=5
```

### 4. Database Migration

```bash
# Initialize Alembic (if not already done)
alembic init migrations

# Create initial migration
alembic revision --autogenerate -m "Initial migration"

# Apply migrations
alembic upgrade head
```

### 5. Run Application

```bash
# Development mode with auto-reload
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Access the application
# API: http://localhost:8000
# Documentation: http://localhost:8000/docs
# Health Check: http://localhost:8000/health
```

## 🐳 Docker Deployment

### Single Container Deployment

```bash
# Build the image
docker build -t chainfinity-backend .

# Run with environment variables
docker run -d \
  --name chainfinity-api \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db \
  -e REDIS_URL=redis://host:6379/0 \
  -e SECRET_KEY=your-secret-key \
  chainfinity-backend
```

### Multi-Service Deployment with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Scale API instances
docker-compose up -d --scale api=3

# Stop all services
docker-compose down
```

**Services included in Docker Compose:**
- **API**: ChainFinity backend application
- **PostgreSQL**: Primary database with persistent storage
- **Redis**: Cache and session store
- **Nginx**: Reverse proxy and load balancer
- **Prometheus**: Metrics collection
- **Grafana**: Monitoring dashboard

## 🏭 Production Deployment

### 1. Server Preparation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3.11 python3.11-venv python3-pip \
  postgresql-client redis-tools nginx certbot \
  python3-certbot-nginx

# Create application user
sudo useradd -m -s /bin/bash chainfinity
sudo usermod -aG sudo chainfinity
```

### 2. Application Setup

```bash
# Switch to application user
sudo su - chainfinity

# Clone repository
git clone <repository-url> /opt/chainfinity
cd /opt/chainfinity

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install gunicorn
```

### 3. Database Setup (Production)

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE chainfinity;
CREATE USER chainfinity_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE chainfinity TO chainfinity_user;
ALTER USER chainfinity_user CREATEDB;
\q
EOF

# Configure PostgreSQL for production
sudo nano /etc/postgresql/15/main/postgresql.conf
```

**Key PostgreSQL settings for production:**

```ini
# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Connection settings
max_connections = 100
listen_addresses = 'localhost'

# Logging
log_statement = 'mod'
log_min_duration_statement = 1000
```

### 4. Redis Setup (Production)

```bash
# Install Redis
sudo apt install -y redis-server

# Configure Redis
sudo nano /etc/redis/redis.conf
```

**Key Redis settings:**

```ini
# Security
requirepass your_redis_password
bind 127.0.0.1

# Memory management
maxmemory 512mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
```

### 5. Environment Configuration

```bash
# Create production environment file
sudo nano /opt/chainfinity/.env
```

**Production environment variables:**

```bash
# Application
APP_NAME=ChainFinity API
ENVIRONMENT=production
DEBUG=false
HOST=0.0.0.0
PORT=8000
WORKERS=4

# Database
DATABASE_URL=postgresql+asyncpg://chainfinity_user:secure_password@localhost:5432/chainfinity
REDIS_URL=redis://:your_redis_password@localhost:6379/0

# Security (generate strong keys)
SECRET_KEY=your-super-secure-secret-key-64-characters-long
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS (restrict to your domain)
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# Blockchain (mainnet)
ETH_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
ETH_CHAIN_ID=1

# External APIs
ETHERSCAN_API_KEY=your_etherscan_api_key
KYC_API_KEY=your_kyc_provider_api_key
AML_API_KEY=your_aml_provider_api_key

# Monitoring
SENTRY_DSN=your_sentry_dsn
LOG_LEVEL=INFO
```

### 6. Systemd Service Setup

```bash
# Create systemd service file
sudo nano /etc/systemd/system/chainfinity.service
```

```ini
[Unit]
Description=ChainFinity Backend API
After=network.target postgresql.service redis.service
Requires=postgresql.service redis.service

[Service]
Type=exec
User=chainfinity
Group=chainfinity
WorkingDirectory=/opt/chainfinity
Environment=PATH=/opt/chainfinity/venv/bin
EnvironmentFile=/opt/chainfinity/.env
ExecStart=/opt/chainfinity/venv/bin/gunicorn app.main:app \
  --bind 0.0.0.0:8000 \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --access-logfile /var/log/chainfinity/access.log \
  --error-logfile /var/log/chainfinity/error.log \
  --log-level info
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Create log directory
sudo mkdir -p /var/log/chainfinity
sudo chown chainfinity:chainfinity /var/log/chainfinity

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable chainfinity
sudo systemctl start chainfinity

# Check status
sudo systemctl status chainfinity
```

### 7. Nginx Configuration

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/chainfinity
```

```nginx
upstream chainfinity_backend {
    server 127.0.0.1:8000;
    # Add more servers for load balancing
    # server 127.0.0.1:8001;
    # server 127.0.0.1:8002;
}

server {
    listen 80;
    server_name api.yourdomain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;

    # Proxy Configuration
    location / {
        proxy_pass http://chainfinity_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }

    # Health check endpoint (no rate limiting)
    location /health {
        proxy_pass http://chainfinity_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        access_log off;
    }

    # Static files (if any)
    location /static/ {
        alias /opt/chainfinity/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# Enable site and restart Nginx
sudo ln -s /etc/nginx/sites-available/chainfinity /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 8. SSL Certificate Setup

```bash
# Install SSL certificate using Let's Encrypt
sudo certbot --nginx -d api.yourdomain.com

# Set up automatic renewal
sudo crontab -e
# Add this line:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### 9. Database Migration and Initial Setup

```bash
# Switch to application user
sudo su - chainfinity
cd /opt/chainfinity
source venv/bin/activate

# Run database migrations
alembic upgrade head

# Create initial admin user (optional)
python scripts/create_admin_user.py
```

### 10. Monitoring Setup

```bash
# Install monitoring tools
pip install prometheus-client

# Create monitoring configuration
mkdir -p /opt/chainfinity/monitoring
```

**Prometheus configuration** (`/opt/chainfinity/monitoring/prometheus.yml`):

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'chainfinity-api'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

## 🔧 Configuration Management

### Environment-Specific Configurations

#### Development
```bash
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=DEBUG
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/chainfinity_dev
```

#### Staging
```bash
ENVIRONMENT=staging
DEBUG=false
LOG_LEVEL=INFO
DATABASE_URL=postgresql+asyncpg://user:pass@staging-db:5432/chainfinity_staging
```

#### Production
```bash
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=WARNING
DATABASE_URL=postgresql+asyncpg://user:pass@prod-db:5432/chainfinity_prod
```

### Security Configuration

#### JWT Settings
```bash
# Use strong, unique secret keys
SECRET_KEY=your-256-bit-secret-key
ACCESS_TOKEN_EXPIRE_MINUTES=15  # Short-lived for security
REFRESH_TOKEN_EXPIRE_DAYS=7     # Reasonable refresh period
```

#### Database Security
```bash
# Use connection pooling
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=30
DB_POOL_TIMEOUT=30

# Enable SSL for production
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db?sslmode=require
```

#### Rate Limiting
```bash
RATE_LIMIT_PER_MINUTE=60    # Requests per minute per IP
RATE_LIMIT_BURST=100        # Burst allowance
```

## 📊 Monitoring and Observability

### Health Checks

The application provides comprehensive health checks:

```bash
# Basic health check
curl http://localhost:8000/health

# Detailed health check with service status
curl http://localhost:8000/health?detailed=true
```

### Metrics Collection

Prometheus metrics are available at `/metrics`:

- Request/response metrics
- Database connection pool metrics
- Cache hit/miss rates
- Business metrics (user registrations, transactions)
- Error rates and response times

### Logging

Structured JSON logging is configured for production:

```json
{
  "timestamp": "2025-01-08T12:00:00Z",
  "level": "INFO",
  "logger": "chainfinity.api",
  "message": "User authentication successful",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "ip_address": "192.168.1.1",
  "request_id": "req_123456"
}
```

### Alerting

Set up alerts for critical metrics:

- High error rates (>5%)
- Slow response times (>2s)
- Database connection issues
- High memory usage (>80%)
- Failed authentication attempts

## 🔄 Deployment Strategies

### Blue-Green Deployment

1. **Prepare Green Environment**
   ```bash
   # Deploy to green environment
   docker-compose -f docker-compose.green.yml up -d
   ```

2. **Health Check**
   ```bash
   # Verify green environment health
   curl http://green.internal:8000/health
   ```

3. **Switch Traffic**
   ```bash
   # Update load balancer configuration
   # Switch from blue to green
   ```

4. **Cleanup**
   ```bash
   # Stop blue environment after verification
   docker-compose -f docker-compose.blue.yml down
   ```

### Rolling Deployment

```bash
# Update one instance at a time
for i in {1..3}; do
  docker-compose stop api_$i
  docker-compose up -d api_$i
  sleep 30  # Wait for health check
done
```

### Canary Deployment

```bash
# Deploy to 10% of traffic first
# Update load balancer to route 10% to new version
# Monitor metrics and gradually increase traffic
```

## 🛠️ Troubleshooting

### Common Issues

#### Database Connection Issues
```bash
# Check database connectivity
pg_isready -h localhost -p 5432 -U chainfinity_user

# Check connection pool status
curl http://localhost:8000/health | jq '.services.database'
```

#### Redis Connection Issues
```bash
# Check Redis connectivity
redis-cli ping

# Check Redis memory usage
redis-cli info memory
```

#### High Memory Usage
```bash
# Check application memory usage
ps aux | grep gunicorn

# Check database connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
```

#### SSL Certificate Issues
```bash
# Check certificate expiry
openssl x509 -in /etc/letsencrypt/live/api.yourdomain.com/cert.pem -text -noout | grep "Not After"

# Renew certificate
sudo certbot renew --dry-run
```

### Log Analysis

```bash
# Application logs
sudo journalctl -u chainfinity -f

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Database logs
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

### Performance Tuning

#### Database Optimization
```sql
-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'user@example.com';

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes;
```

#### Application Optimization
```bash
# Profile application performance
pip install py-spy
py-spy top --pid $(pgrep -f gunicorn)

# Monitor memory usage
pip install memory-profiler
mprof run python app/main.py
```

## 🔐 Security Hardening

### Server Security

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Configure firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443

# Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### Application Security

```bash
# Set proper file permissions
sudo chown -R chainfinity:chainfinity /opt/chainfinity
sudo chmod 600 /opt/chainfinity/.env
sudo chmod 755 /opt/chainfinity

# Regular security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

### Database Security

```sql
-- Create read-only user for reporting
CREATE USER chainfinity_readonly WITH PASSWORD 'readonly_password';
GRANT CONNECT ON DATABASE chainfinity TO chainfinity_readonly;
GRANT USAGE ON SCHEMA public TO chainfinity_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO chainfinity_readonly;
```

## 📈 Scaling Considerations

### Horizontal Scaling

1. **Load Balancer Configuration**
   - Use Nginx or HAProxy for load balancing
   - Implement health checks
   - Configure session affinity if needed

2. **Database Scaling**
   - Set up read replicas for read-heavy workloads
   - Implement connection pooling
   - Consider database sharding for large datasets

3. **Cache Scaling**
   - Use Redis Cluster for high availability
   - Implement cache warming strategies
   - Monitor cache hit rates

### Vertical Scaling

1. **CPU Optimization**
   - Increase worker processes
   - Use CPU profiling to identify bottlenecks
   - Optimize database queries

2. **Memory Optimization**
   - Increase available RAM
   - Tune database buffer settings
   - Optimize application memory usage

## 🚨 Disaster Recovery

### Backup Strategy

```bash
# Database backup script
#!/bin/bash
BACKUP_DIR="/opt/backups/chainfinity"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
pg_dump -h localhost -U chainfinity_user chainfinity | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# Application backup
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz /opt/chainfinity

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
```

### Recovery Procedures

```bash
# Database recovery
gunzip -c /opt/backups/chainfinity/db_backup_YYYYMMDD_HHMMSS.sql.gz | psql -h localhost -U chainfinity_user chainfinity

# Application recovery
tar -xzf /opt/backups/chainfinity/app_backup_YYYYMMDD_HHMMSS.tar.gz -C /
sudo systemctl restart chainfinity
```

## 📞 Support and Maintenance

### Regular Maintenance Tasks

1. **Daily**
   - Monitor application logs
   - Check system resources
   - Verify backup completion

2. **Weekly**
   - Review security logs
   - Update dependencies
   - Performance analysis

3. **Monthly**
   - Security patches
   - Database maintenance
   - Capacity planning review

### Getting Help

- **Documentation**: Check the README.md and API documentation
- **Logs**: Review application and system logs
- **Monitoring**: Check Grafana dashboards
- **Community**: Join the project Discord/Slack channel

---

This deployment guide provides a comprehensive foundation for deploying ChainFinity backend in production environments. Always test deployments in staging environments before applying to production, and maintain regular backups and monitoring.
