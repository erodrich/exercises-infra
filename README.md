# Exercise Backend Infrastructure

Docker Compose configurations for deploying the Exercise Backend application across different environments.

## Structure

```
exercises-infra/
├── dev/
│   ├── docker-compose.yml    # Development environment
│   └── .env.example           # Development config template
├── prod/
│   ├── docker-compose.yml    # Production environment
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
- Access to Docker Hub (where the backend image is hosted)

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
   docker-compose logs -f app
   ```

6. **Access application**
   - API: http://localhost:8080/exercise-logging
   - Swagger: http://localhost:8080/exercise-logging/swagger-ui/index.html
   - Health: http://localhost:8080/exercise-logging/actuator/health

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
   docker-compose logs -f app
   curl http://localhost:8080/exercise-logging/actuator/health
   ```

## Environment Configurations

### Development (`dev/`)

**Purpose:** Local development and testing

**Configuration:**
- PostgreSQL on port 5432
- Application on port 8080
- Profile: `dev`
- Database: `exercises_dev`
- Auto-initializes with sample data
- Schema auto-update enabled
- Debug logging enabled

**Docker Compose Services:**
- `postgres` - PostgreSQL 16 Alpine
- `app` - Exercise Backend (from Docker Hub)

**Default Credentials:**
- DB User: `postgres`
- DB Password: `postgres`

### Production (`prod/`)

**Purpose:** Production deployment

**Configuration:**
- PostgreSQL on port 5432
- Application on port 8080
- Profile: `prod`
- Database: `exercises_prod`
- No auto-initialization
- Schema validation only
- Production logging
- Memory limits: 1GB max, 512MB reserved

**Docker Compose Services:**
- `postgres` - PostgreSQL 16 Alpine (always restart)
- `app` - Exercise Backend (from Docker Hub)

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
docker-compose logs -f app
docker-compose logs -f postgres

# Last 100 lines
docker-compose logs --tail=100 app
```

### Managing Services

```bash
# Check status
docker-compose ps

# Restart service
docker-compose restart app

# Stop services
docker-compose stop

# Stop and remove containers (data preserved)
docker-compose down

# Stop and remove everything including volumes (⚠️ DELETES DATA)
docker-compose down -v
```

### Executing Commands

```bash
# Shell into application container
docker-compose exec app sh

# Database shell
docker-compose exec postgres psql -U postgres -d exercises_dev

# Check Java version
docker-compose exec app java -version
```

### Updating Application

```bash
# Pull latest image
docker-compose pull app

# Restart with new image
docker-compose up -d app

# Or in one command
docker-compose up -d --pull always app
```

## Health Checks

### Application Health

```bash
curl http://localhost:8080/exercise-logging/actuator/health
```

Expected response:
```json
{
  "status": "UP"
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
| `DB_PASSWORD` | `postgres` | Database password |

### Production

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_USERNAME` | - | Docker Hub username (required) |
| `IMAGE_VERSION` | `latest` | Backend image version (use specific tag) |
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
- Application connects to database using hostname: `postgres`
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
docker-compose logs app
```

**Common issues:**
- Image not found: Set `DOCKER_USERNAME` in `.env`
- Database not ready: Wait for health check to pass
- Port conflict: Another service using port 8080 or 5432

### Database Connection Error

**Check database is running:**
```bash
docker-compose ps postgres
```

**Check network connectivity:**
```bash
docker-compose exec app ping postgres
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

**Manually pull image:**
```bash
docker pull ${DOCKER_USERNAME}/exercises-backend:latest
```

### Application Unhealthy

**Check health endpoint:**
```bash
docker-compose exec app wget -qO- http://localhost:8080/exercise-logging/actuator/health
```

**Check application logs:**
```bash
docker-compose logs --tail=100 app
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

| Service | Port | Purpose |
|---------|------|---------|
| postgres | 5432 | PostgreSQL database |
| app | 8080 | Spring Boot application |

### Production Environment

| Service | Port | Purpose |
|---------|------|---------|
| postgres | 5432 | PostgreSQL database |
| app | 8080 | Spring Boot application |

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
docker stats exercises-backend-dev exercises-postgres-dev
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

1. Pull new image version:
   ```bash
   docker-compose pull app
   ```

2. Restart application:
   ```bash
   docker-compose up -d app
   ```

3. Verify deployment:
   ```bash
   docker-compose logs -f app
   curl http://localhost:8080/exercise-logging/actuator/health
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

- Check application logs: `docker-compose logs app`
- Check database logs: `docker-compose logs postgres`
- Verify configuration: `docker-compose config`
- List all containers: `docker ps -a`
- Backend repository: Check main README.md in exercises-backend

## Additional Resources

- Docker Compose Documentation: https://docs.docker.com/compose/
- PostgreSQL Docker Image: https://hub.docker.com/_/postgres
- Spring Boot Actuator: https://docs.spring.io/spring-boot/actuator/
