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
   - Frontend: http://localhost:3000
   - API: http://localhost:8080/exercise-logging
   - Swagger: http://localhost:8080/exercise-logging/swagger-ui/index.html
   - Backend Health: http://localhost:8080/exercise-logging/actuator/health
   - Frontend Health: http://localhost:3000/health

### Production Environment

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
   ```

4. **Start services** (database auto-initializes on first run)
   ```bash
   docker-compose up -d
   ```

   **Note:** On first startup, database schema is automatically created.

5. **Verify deployment**
   ```bash
   docker-compose ps
   docker-compose logs -f backend
   docker-compose logs -f frontend
   curl http://localhost:8080/exercise-logging/actuator/health
   curl http://localhost:3000/health
   ```

## Environment Configurations

### Development (`dev/`)

**Purpose:** Local development and testing

**Configuration:**
- PostgreSQL on port 5432
- Backend on port 8080
- Frontend on port 3000
- Profile: `dev`
- Database: `exercises_dev`
- Auto-initializes with sample data
- Schema auto-update enabled
- Debug logging enabled

**Docker Compose Services:**
- `postgres` - PostgreSQL 16 Alpine
- `backend` - Spring Boot API (from Docker Hub)
- `frontend` - React SPA with Nginx (from Docker Hub)

**Default Credentials:**
- DB User: `postgres`
- DB Password: `postgres`

### Production (`prod/`)

**Purpose:** Production deployment

**Configuration:**
- PostgreSQL on port 5432
- Backend on port 8080
- Frontend on port 3000
- Profile: `prod`
- Database: `exercises_prod`
- No auto-initialization
- Schema validation only
- Production logging
- Memory limits:
  - Backend: 1GB max, 512MB reserved
  - Frontend: 256MB max, 128MB reserved

**Docker Compose Services:**
- `postgres` - PostgreSQL 16 Alpine (always restart)
- `backend` - Spring Boot API (from Docker Hub)
- `frontend` - React SPA with Nginx (from Docker Hub)

**Security Requirements:**
- ⚠️ **MUST** set secure DB_PASSWORD
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

### Production

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_USERNAME` | - | Docker Hub username (required) |
| `IMAGE_VERSION` | `latest` | Backend image version (use specific tag) |
| `FRONTEND_VERSION` | `latest` | Frontend image version (use specific tag) |
| `DB_USERNAME` | `postgres` | Database username |
| `DB_PASSWORD` | - | Database password (required, no default) |

## Volumes

Both environments use named Docker volumes for data persistence:

- `postgres_data` - PostgreSQL data directory

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

## Ports Reference

### Development Environment

| Service | Container Port | Host Port | Purpose |
|---------|----------------|-----------|---------|
| frontend | 80 | 3000 | React SPA (Nginx) |
| backend | 8080 | 8080 | Spring Boot REST API |
| postgres | 5432 | 5432 | PostgreSQL database |

### Production Environment

| Service | Container Port | Host Port | Purpose |
|---------|----------------|-----------|---------|
| frontend | 80 | 3000 | React SPA (Nginx) |
| backend | 8080 | 8080 | Spring Boot REST API |
| postgres | 5432 | 5432 | PostgreSQL database |

## Security Best Practices

### Development

- ✅ Use default credentials (acceptable for local dev)
- ✅ Keep ports accessible on localhost only
- ✅ Can use `latest` tag for convenience

### Production

- ⚠️ **MUST** use strong passwords (20+ characters, mixed case, numbers, symbols)
- ⚠️ **MUST** use specific version tags (not `latest`)
- ⚠️ **NEVER** commit `.env` files to version control
- ✅ Consider using Docker secrets instead of environment variables
- ✅ Set up firewall rules to restrict database access
- ✅ Enable SSL/TLS for database connections
- ✅ Regular security updates for base images
- ✅ Monitor logs for suspicious activity
- ✅ Set up automated backups

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

- [ ] Copy `.env.example` to `.env`
- [ ] Set `DOCKER_USERNAME` to your Docker Hub username
- [ ] Set `IMAGE_VERSION` to specific version (e.g., `1.0.0`)
- [ ] Set `FRONTEND_VERSION` to specific version (e.g., `1.0.0`)
- [ ] Set strong `DB_PASSWORD` (20+ characters)
- [ ] Review security settings
- [ ] Test database connection
- [ ] Verify health checks pass
- [ ] Set up monitoring
- [ ] Configure automated backups
- [ ] Document rollback procedure
- [ ] Set up log aggregation
- [ ] Configure alerts

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
