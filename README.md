# Exercise Application Infrastructure

Docker Compose configurations for deploying the full-stack Exercise application (frontend + backend + database) across different environments.

## Structure

```
exercises-infra/
├── dev/
│   ├── docker-compose.yml    # Development environment (3 services)
│   └── .env.example           # Development config template
├── prod/
│   ├── docker-compose.yml    # Production environment (3 services)
│   └── .env.example           # Production config template
├── database/
│   ├── 01-schema.sql          # Database schema
│   ├── 02-seed-data.sql       # Initial data (34 exercises)
│   ├── init-db.sh             # Manual init script
│   └── README.md              # Database documentation
└── README.md                  # This file
```

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Access to Docker Hub (where the images are hosted)

## Features

### Security
- **HTTPS/SSL** - Automatic Let's Encrypt certificates in production (nginx-le)
- **JWT Authentication** - Token-based authentication for API access
- **Role-Based Access Control** - USER and ADMIN roles
- **Password Encryption** - BCrypt hashing for secure password storage
- **Secure Configuration** - Environment-based secrets management

### Application
- **User Management** - Registration, login with JWT tokens
- **Exercise Administration** - Admin-only CRUD operations for exercises
- **Workout Logging** - Users can log exercises with sets (weight/reps)
- **Pre-populated Data** - 34 common exercises across 6 muscle groups
- **Health Monitoring** - Built-in health checks for all services

## Database Initialization

### Automatic (Recommended)

When starting with docker-compose, the database is **automatically initialized** on first startup:

1. PostgreSQL container starts
2. SQL scripts from `database/` folder are executed:
   - `01-schema.sql` - Creates all tables, indexes, sequences
   - `02-seed-data.sql` - Loads 34 pre-defined exercises
3. Application starts with schema validation (`ddl-auto=validate` in prod)

**Important:** Scripts only run when creating a **new database**. If the volume already exists with data, scripts are skipped.

### Manual Initialization

For manual database setup, use the initialization script:

```bash
cd database
./init-db.sh
```

Or execute SQL files directly:

```bash
export PGPASSWORD=postgres
psql -h localhost -U postgres -d exercises_dev -f database/01-schema.sql
psql -h localhost -U postgres -d exercises_dev -f database/02-seed-data.sql
```

📖 **For detailed database documentation, see [database/README.md](database/README.md)**

## Quick Start

### Development Environment

1. **Navigate to dev folder**
   ```bash
   cd dev
   ```

2. **Copy environment template**
   ```bash
   cp .env.example .env
   ```

3. **Edit .env file**
   ```bash
   nano .env
   ```
   
   Set your Docker Hub username:
   ```env
   DOCKER_USERNAME=your-dockerhub-username
   IMAGE_VERSION=latest
   FRONTEND_VERSION=latest
   DB_PASSWORD=postgres
   # JWT secret (optional for dev, uses default if not set)
   JWT_SECRET=exercises-dev-secret-key-change-in-production-must-be-256-bits
   JWT_EXPIRATION=86400000  # 24 hours
   ```

4. **Start services** (database auto-initializes on first run)
   ```bash
   docker-compose up -d
   ```

   **Note:** On first startup, wait ~10 seconds for database initialization to complete.

5. **Check status**
   ```bash
   docker-compose ps
   docker-compose logs -f backend
   docker-compose logs -f frontend
   ```

6. **Access application**
   - Frontend: http://localhost (HTTP-only for development)
   - API: http://localhost:8080/exercise-logging
   - Swagger: http://localhost:8080/exercise-logging/swagger-ui/index.html
   - Backend Health: http://localhost:8080/exercise-logging/actuator/health
   - Proxy Health: http://localhost/proxy-health

### Production Environment

**Note:** Production uses HTTPS with automatic Let's Encrypt SSL certificates!

1. **Navigate to prod folder**
   ```bash
   cd prod
   ```

2. **Copy environment template**
   ```bash
   cp .env.example .env
   ```

3. **Edit .env file with SECURE values**
   ```bash
   nano .env
   ```
   
   Set production values:
   ```env
   DOCKER_USERNAME=your-dockerhub-username
   IMAGE_VERSION=1.0.0  # Use specific version tag
   FRONTEND_VERSION=1.0.0  # Use specific version tag
   DB_USERNAME=postgres
   DB_PASSWORD=YourSecurePassword123!  # CHANGE THIS!
   
   # JWT Configuration (REQUIRED for production)
   JWT_SECRET=your-strong-256-bit-secret-key-here  # CHANGE THIS!
   JWT_EXPIRATION=86400000  # 24 hours in milliseconds
   
   # HTTPS/SSL Configuration (REQUIRED for production)
   LETSENCRYPT=true
   LE_EMAIL=your-email@example.com     # REQUIRED for Let's Encrypt
   LE_FQDN=erodrich.duckdns.org        # Your domain (DuckDNS works!)
   TZ=UTC
   ```

   **Generate a secure JWT secret:**
   ```bash
   # Using OpenSSL (recommended)
   openssl rand -base64 64
   
   # Or using /dev/urandom
   head -c 64 /dev/urandom | base64
   ```

   **DNS Configuration (REQUIRED for HTTPS):**
   - Ensure your `LE_FQDN` domain points to your server's public IP
   - For DuckDNS: Configure at https://www.duckdns.org
   - Ports 80 and 443 **MUST** be open on your firewall
   - Let's Encrypt will automatically verify domain ownership

4. **Start services** (SSL certificate generated on first run)
   ```bash
   docker-compose up -d
   ```

   **Note:** On first startup, database schema is automatically created.

5. **Verify deployment**
   ```bash
   docker-compose ps
   
   # Watch SSL certificate generation (important on first run!)
   docker-compose logs -f nginx-le
   
   # Check other services
   docker-compose logs -f backend
   docker-compose logs -f frontend
   
   # Test HTTPS access (after certificate is generated)
   curl https://erodrich.duckdns.org/health
   curl https://erodrich.duckdns.org/exercise-logging/actuator/health
   ```
   
   **Note:** First startup takes 30-60 seconds for Let's Encrypt certificate generation.
   Look for "Certificate successfully obtained" in nginx-le logs.

## Environment Configurations

### Development (`dev/`)

**Purpose:** Local development and testing

**Configuration:**
- PostgreSQL on port 5432
- Backend on port 8080
- HTTP Proxy on port 80 (no SSL for development)
- Profile: `dev`
- Database: `exercises_dev`
- Auto-initializes with sample data
- Schema auto-update enabled
- Debug logging enabled

**Docker Compose Services:**
- `postgres` - PostgreSQL 16 Alpine
- `backend` - Spring Boot API (from Docker Hub)
- `frontend` - React SPA with Nginx (internal only)
- `proxy` - Nginx HTTP reverse proxy (no SSL)

**Default Credentials:**
- DB User: `postgres`
- DB Password: `postgres`

### Production (`prod/`)

**Purpose:** Production deployment

**Configuration:**
- PostgreSQL on port 5432
- Backend on port 8080 (internal)
- nginx-le on ports 80 (HTTP → HTTPS redirect) and 443 (HTTPS)
- Profile: `prod`
- Database: `exercises_prod`
- Automatic Let's Encrypt SSL certificates
- Certificate auto-renewal every 60 days
- Schema validation only
- Production logging
- Memory limits:
  - Backend: 1GB max, 512MB reserved
  - Frontend: 256MB max, 128MB reserved
  - nginx-le: 128MB max, 64MB reserved

**Docker Compose Services:**
- `postgres` - PostgreSQL 16 Alpine (always restart)
- `backend` - Spring Boot API (internal only)
- `frontend` - React SPA with Nginx (internal only)
- `nginx-le` - HTTPS reverse proxy with Let's Encrypt

**Security Requirements:**
- ⚠️ **MUST** set secure DB_PASSWORD
- ⚠️ **MUST** set valid LE_EMAIL for Let's Encrypt notifications
- ⚠️ **MUST** set LE_FQDN pointing to server IP
- ⚠️ **MUST** open ports 80 and 443 on firewall
- ⚠️ **MUST** generate secure JWT_SECRET
- Should use specific image version tags (not `latest`)
- Environment variables for all secrets

## Common Commands

### Starting Services

```bash
# Start in detached mode
docker-compose up -d

# Start with logs
docker-compose up

# Rebuild and start (if image updated)
docker-compose up -d --pull always
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Managing Services

```bash
# Check status
docker-compose ps

# Restart service
docker-compose restart backend
docker-compose restart frontend

# Stop services
docker-compose stop

# Stop and remove containers (data preserved)
docker-compose down

# Stop and remove everything including volumes (⚠️ DELETES DATA)
docker-compose down -v
```

### Executing Commands

```bash
# Shell into backend container
docker-compose exec backend sh

# Shell into frontend container
docker-compose exec frontend sh

# Database shell
docker-compose exec postgres psql -U postgres -d exercises_dev

# Check Java version
docker-compose exec backend java -version

# Check Nginx version
docker-compose exec frontend nginx -v
```

### Updating Application

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d

# Update specific service
docker-compose pull backend
docker-compose up -d backend

# Or in one command
docker-compose up -d --pull always
```

## Health Checks

### Backend Health

```bash
curl http://localhost:8080/exercise-logging/actuator/health
```

Expected response:
```json
{
  "status": "UP"
}
```

### Frontend Health

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "exercises-frontend"
}
```

### Container Health

```bash
docker-compose ps
```

Healthy containers show `healthy` status.

### Database Health

```bash
docker-compose exec postgres pg_isready -U postgres
```

## Environment Variables

### Development

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_USERNAME` | - | Docker Hub username (required) |
| `IMAGE_VERSION` | `latest` | Backend image version |
| `FRONTEND_VERSION` | `latest` | Frontend image version |
| `DB_PASSWORD` | `postgres` | Database password |
| `JWT_SECRET` | (default key) | JWT secret key for token signing |
| `JWT_EXPIRATION` | `86400000` | JWT token expiration in milliseconds (24h) |

### Production

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_USERNAME` | - | Docker Hub username (required) |
| `IMAGE_VERSION` | `latest` | Backend image version (use specific tag) |
| `FRONTEND_VERSION` | `latest` | Frontend image version (use specific tag) |
| `DB_USERNAME` | `postgres` | Database username |
| `DB_PASSWORD` | - | Database password (required, no default) |
| `JWT_SECRET` | - | JWT secret key (required, 256+ bits) |
| `JWT_EXPIRATION` | `86400000` | JWT token expiration in milliseconds (24h) |
| `LETSENCRYPT` | `true` | Enable Let's Encrypt SSL certificates |
| `LE_EMAIL` | - | Email for Let's Encrypt notifications (required) |
| `LE_FQDN` | - | Domain name for SSL certificate (required) |
| `TZ` | `UTC` | Timezone for containers |

## Volumes

Both environments use named Docker volumes for data persistence:

**Development:**
- `postgres_data` - PostgreSQL data directory

**Production:**
- `postgres_data` - PostgreSQL data directory
- `nginx_ssl` - Let's Encrypt SSL certificates and keys

**List volumes:**
```bash
docker volume ls | grep exercises
```

**Inspect volume:**
```bash
docker volume inspect dev_postgres_data
```

**Backup database:**
```bash
docker-compose exec postgres pg_dump -U postgres exercises_dev > backup.sql
```

**Restore database:**
```bash
docker-compose exec -T postgres psql -U postgres exercises_dev < backup.sql
```

## Networking

Both environments create a bridge network named `exercises-network`.

**Services communicate via service names:**
- Backend connects to database using hostname: `postgres`
- Frontend connects to backend using hostname: `backend` (internal) or `localhost:8080` (external)
- JDBC URL: `jdbc:postgresql://postgres:5432/exercises_dev`

**List networks:**
```bash
docker network ls | grep exercises
```

**Inspect network:**
```bash
docker network inspect dev_exercises-network
```

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker-compose logs backend
docker-compose logs frontend
```

**Common issues:**
- Image not found: Set `DOCKER_USERNAME` in `.env`
- Database not ready: Wait for health check to pass
- Port conflict: Another service using port 3000, 8080, or 5432
- CORS errors: Check backend CORS configuration

### Database Connection Error

**Check database is running:**
```bash
docker-compose ps postgres
```

**Check network connectivity:**
```bash
docker-compose exec backend ping postgres
docker-compose exec frontend ping backend
```

**Verify credentials:**
```bash
# Check .env file has correct values
cat .env
```

### Image Pull Failed

**Login to Docker Hub:**
```bash
docker login
```

**Manually pull images:**
```bash
docker pull ${DOCKER_USERNAME}/exercises-backend:latest
docker pull ${DOCKER_USERNAME}/exercises-frontend:latest
```

### Application Unhealthy

**Check backend health endpoint:**
```bash
docker-compose exec backend wget -qO- http://localhost:8080/exercise-logging/actuator/health
```

**Check frontend health endpoint:**
```bash
docker-compose exec frontend wget -qO- http://localhost/health
```

**Check application logs:**
```bash
docker-compose logs --tail=100 backend
docker-compose logs --tail=100 frontend
```

### CORS Errors (Fixed!)

**Good news:** The application now uses Nginx reverse proxy, so CORS is no longer an issue!

**How it works:**
- Browser requests: `http://YOUR_SERVER_IP:3000/exercise-logging/api/...`
- Nginx proxies to backend via internal Docker network
- No CORS issues because everything appears to be same-origin

**If you're using an older version:**
```bash
# Pull latest frontend image (has Nginx proxy configured)
docker-compose pull frontend
docker-compose up -d frontend
```

📖 **See [NGINX_PROXY_SOLUTION.md](NGINX_PROXY_SOLUTION.md) for technical details**

### Reset Everything

**Stop and remove all containers and volumes:**
```bash
docker-compose down -v
```

**Remove images:**
```bash
docker-compose down --rmi all -v
```

**Start fresh:**
```bash
docker-compose up -d
```

## HTTPS/SSL Setup (Production)

### Overview

Production uses **nginx-le** for automatic HTTPS with Let's Encrypt:

**Flow:**
```
Internet → Port 443 (HTTPS) → nginx-le → frontend:80 → backend:8080
          Port 80 (HTTP redirect)
```

### Prerequisites

1. **Domain Name**: DuckDNS subdomain works perfectly (`erodrich.duckdns.org`)
2. **DNS Configuration**: Domain must point to server's public IP
3. **Firewall**: Ports 80 and 443 must be open
4. **Email**: Valid email for Let's Encrypt notifications

### Required Environment Variables

```env
LETSENCRYPT=true
LE_EMAIL=your-email@example.com
LE_FQDN=erodrich.duckdns.org
TZ=UTC
```

### First Startup Process

1. nginx-le container starts
2. Requests SSL certificate from Let's Encrypt
3. Let's Encrypt verifies domain ownership (port 80)
4. Certificate issued and installed (~30-60 seconds)
5. HTTPS available on port 443
6. HTTP automatically redirects to HTTPS

**Watch the process:**
```bash
docker-compose logs -f nginx-le
```

Look for: `"Certificate successfully obtained"`

### Certificate Renewal

- **Automatic**: Certificates renew every 60 days
- **No intervention needed**: nginx-le handles it automatically
- **Monitoring**: Check logs periodically

### Access Your Application

- **HTTPS**: https://erodrich.duckdns.org
- **HTTP**: http://erodrich.duckdns.org (redirects to HTTPS)
- **API**: https://erodrich.duckdns.org/exercise-logging/api/v1/...

### SSL Configuration

The nginx-le configuration (`nginx-le.conf`) includes:
- ✅ A+ SSL rating configuration
- ✅ HTTP/2 support
- ✅ HSTS headers
- ✅ Security headers (X-Frame-Options, etc.)
- ✅ Automatic HTTP → HTTPS redirect

### Troubleshooting HTTPS

**Certificate not generating:**
```bash
# Check nginx-le logs
docker-compose logs nginx-le

# Common issues:
# - Domain doesn't point to server IP
# - Ports 80/443 not open on firewall
# - Invalid email address
# - Rate limit hit (5 failures per hour per domain)
```

**Verify SSL:**
```bash
# Test certificate
openssl s_client -connect erodrich.duckdns.org:443 -servername erodrich.duckdns.org

# Check certificate expiry
echo | openssl s_client -connect erodrich.duckdns.org:443 2>/dev/null | openssl x509 -noout -dates
```

**Rate Limits:**
- Let's Encrypt: 5 failed attempts per hour
- If hit, wait 1 hour before retrying
- Use staging for testing: `LE_ADDITIONAL_OPTIONS=--staging`

## Ports Reference

### Development Environment

| Service | Container Port | Host Port | Purpose |
|---------|----------------|-----------|---------|  
| proxy | 80 | 80 | HTTP reverse proxy (no SSL) |
| frontend | 80 | - | React SPA (internal only) |
| backend | 8080 | 8080 | Spring Boot REST API |
| postgres | 5432 | 5432 | PostgreSQL database |

### Production Environment

| Service | Container Port | Host Port | Purpose |
|---------|----------------|-----------|---------|  
| nginx-le | 80, 443 | 80, 443 | HTTPS proxy + Let's Encrypt |
| frontend | 80 | - | React SPA (internal only) |
| backend | 8080 | 8080 | Spring Boot REST API |
| postgres | 5432 | 5432 | PostgreSQL database |

## Security Best Practices

### Development

- ✅ Use default credentials (acceptable for local dev)
- ✅ Keep ports accessible on localhost only
- ✅ Can use `latest` tag for convenience

### Production

- ⚠️ **MUST** use strong passwords (20+ characters, mixed case, numbers, symbols)
- ⚠️ **MUST** generate secure JWT secret (256+ bits using OpenSSL)
- ⚠️ **MUST** use specific version tags (not `latest`)
- ⚠️ **NEVER** commit `.env` files to version control
- ⚠️ **NEVER** use default JWT secret in production
- ✅ Consider using Docker secrets instead of environment variables
- ✅ Set up firewall rules to restrict database access
- ✅ Enable SSL/TLS for database connections
- ✅ Regular security updates for base images
- ✅ Monitor logs for suspicious activity
- ✅ Set up automated backups
- ✅ Rotate JWT secrets periodically

## Monitoring

### View Resource Usage

```bash
# Real-time stats
docker stats

# Specific containers
docker stats exercises-frontend-dev exercises-backend-dev exercises-postgres-dev
```

### Check Disk Usage

```bash
# Docker disk usage
docker system df

# Volume sizes
docker system df -v
```

## Production Deployment Checklist

### Pre-Deployment
- [ ] Copy `.env.example` to `.env`
- [ ] Set `DOCKER_USERNAME` to your Docker Hub username
- [ ] Set `IMAGE_VERSION` to specific version (e.g., `1.0.0`)
- [ ] Set `FRONTEND_VERSION` to specific version (e.g., `1.0.0`)
- [ ] Set strong `DB_PASSWORD` (20+ characters)
- [ ] Generate secure `JWT_SECRET` using `openssl rand -base64 64`
- [ ] Set `JWT_EXPIRATION` (default 24h is reasonable)
- [ ] Set `LETSENCRYPT=true`
- [ ] Set valid `LE_EMAIL` for SSL notifications
- [ ] Set `LE_FQDN` to your domain (e.g., `erodrich.duckdns.org`)
- [ ] Verify domain points to server's public IP
- [ ] Open ports 80 and 443 on firewall
- [ ] Review all security settings
- [ ] Verify `.env` is in `.gitignore`

### Deployment
- [ ] Start services: `docker-compose up -d`
- [ ] Watch SSL certificate generation: `docker-compose logs -f nginx-le`
- [ ] Wait for "Certificate successfully obtained" message
- [ ] Test HTTPS access: `curl https://your-domain.com/health`
- [ ] Verify HTTP redirects to HTTPS
- [ ] Test database connection
- [ ] Verify all health checks pass
- [ ] Test user registration and login via HTTPS
- [ ] Verify JWT tokens are being issued
- [ ] Test admin role access
- [ ] Verify backend API accessible via HTTPS

### Post-Deployment
- [ ] Test SSL certificate with ssllabs.com
- [ ] Set up monitoring for certificate expiry
- [ ] Configure automated database backups
- [ ] Document rollback procedure
- [ ] Set up log aggregation
- [ ] Configure alerts for service health
- [ ] Document JWT secret rotation procedure
- [ ] Schedule certificate renewal monitoring

## Maintenance

### Updating the Application

1. Pull new image versions:
   ```bash
   docker-compose pull
   ```

2. Restart applications:
   ```bash
   docker-compose up -d
   ```

3. Verify deployment:
   ```bash
   docker-compose logs -f backend
   docker-compose logs -f frontend
   curl http://localhost:8080/exercise-logging/actuator/health
   curl http://localhost:3000/health
   ```

### Database Maintenance

**Backup:**
```bash
docker-compose exec postgres pg_dump -U postgres exercises_prod > backup-$(date +%Y%m%d).sql
```

**Optimize:**
```bash
docker-compose exec postgres psql -U postgres -d exercises_prod -c "VACUUM ANALYZE;"
```

**Check connections:**
```bash
docker-compose exec postgres psql -U postgres -d exercises_prod -c "SELECT count(*) FROM pg_stat_activity;"
```

## Getting Help

- Check backend logs: `docker-compose logs backend`
- Check frontend logs: `docker-compose logs frontend`
- Check database logs: `docker-compose logs postgres`
- Verify configuration: `docker-compose config`
- List all containers: `docker ps -a`
- Backend docs: Check exercises-backend/README.md
- Frontend docs: Check exercises-frontend/README.md

## Additional Resources

- Docker Compose Documentation: https://docs.docker.com/compose/
- PostgreSQL Docker Image: https://hub.docker.com/_/postgres
- Spring Boot Actuator: https://docs.spring.io/spring-boot/actuator/
- Nginx Docker Image: https://hub.docker.com/_/nginx
