# Database Initialization Scripts

SQL scripts for initializing the Exercise Backend PostgreSQL database.

## Files

### `01-schema.sql`
Creates all database tables, sequences, indexes, and constraints.

**Tables created:**
- `users` - User accounts with role-based access (USER, ADMIN)
- `muscle_groups` - Muscle group categories
- `exercises` - Available exercises (references muscle_groups)
- `exercise_logs` - Workout sessions
- `exercise_sets` - Individual sets
- `exercise_log_sets` - Join table for logs and sets

**Sequences:**
- `users_seq`
- `muscle_groups_seq`
- `exercises_seq`
- `exercise_logs_seq`

### `02-seed-data.sql`
Pre-populates the database with 6 muscle groups and 34 common exercises.

**Muscle Groups:**
1. Chest - Pectoral muscles
2. Back - Latissimus dorsi, trapezius, rhomboids
3. Shoulders - Deltoid muscles
4. Legs - Quadriceps, hamstrings, glutes, calves
5. Biceps - Biceps brachii
6. Triceps - Triceps brachii

**Exercises per Muscle Group:**
- Chest (6 exercises)
- Back (6 exercises)
- Shoulders (6 exercises)
- Legs (6 exercises)
- Biceps (5 exercises)
- Triceps (5 exercises)

### `init-db.sh`
Interactive script to initialize a PostgreSQL database.

## Usage

### Option 1: Docker Compose (Automatic)

When using docker-compose, the database is automatically initialized on first startup:

```bash
cd ../dev  # or ../prod
docker-compose up -d
```

The SQL scripts are mounted as volumes and executed by PostgreSQL's `docker-entrypoint-initdb.d` mechanism.

**Note:** Scripts only run when the database is created for the first time. If the volume already exists with data, scripts are skipped.

### Option 2: Manual Initialization Script

Use the `init-db.sh` script for manual database setup:

```bash
# Local database
./init-db.sh

# Remote database
DB_HOST=your-server.com \
DB_PORT=5432 \
DB_NAME=exercises_prod \
DB_USER=postgres \
DB_PASSWORD=your_password \
./init-db.sh
```

**The script will:**
1. Test database connection
2. Create database if it doesn't exist
3. Apply schema (01-schema.sql)
4. Optionally load seed data (02-seed-data.sql)
5. Verify setup

### Option 3: Manual SQL Execution

Execute SQL files directly with psql:

```bash
# Set password
export PGPASSWORD=your_password

# Create database
psql -h localhost -U postgres -c "CREATE DATABASE exercises_dev;"

# Apply schema
psql -h localhost -U postgres -d exercises_dev -f 01-schema.sql

# Load seed data (optional)
psql -h localhost -U postgres -d exercises_dev -f 02-seed-data.sql
```

### Option 4: Docker Container Exec

Initialize database from inside a running postgres container:

```bash
# Copy scripts to container
docker cp 01-schema.sql exercises-postgres-dev:/tmp/
docker cp 02-seed-data.sql exercises-postgres-dev:/tmp/

# Execute scripts
docker exec -it exercises-postgres-dev psql -U postgres -d exercises_dev -f /tmp/01-schema.sql
docker exec -it exercises-postgres-dev psql -U postgres -d exercises_dev -f /tmp/02-seed-data.sql
```

## Important Notes

### First-Time Setup

When starting with docker-compose for the first time:
1. SQL scripts are automatically executed
2. Schema is created
3. Seed data is loaded
4. Application can start successfully with `ddl-auto=validate` (production)

### Existing Database

If the database volume already exists:
1. Scripts in `/docker-entrypoint-initdb.d/` are **NOT** executed
2. To reinitialize, you must:
   - Stop containers: `docker-compose down`
   - Remove volume: `docker volume rm dev_postgres_data`
   - Start again: `docker-compose up -d`
   - ⚠️ **This deletes all data!**

### Production Considerations

**Schema Management:**
- For production, consider using migration tools:
  - **Flyway**: Version-controlled migrations
  - **Liquibase**: Database-independent migrations
- Current setup is suitable for:
  - Initial deployments
  - Development environments
  - Small-scale production (with backup strategy)

**Seed Data in Production:**
- The `02-seed-data.sql` is mounted in production docker-compose
- Only executes on fresh database
- Consider whether pre-loading exercises is appropriate
- Alternative: Let users create their own exercises

## Schema Version

**Current Version:** 1.0.0

**Schema Details:**
- PostgreSQL 16+
- Uses sequences for ID generation
- Includes indexes for common queries
- Foreign key constraints enforced
- Check constraints on enum values (muscle_group, role)
- Role-based access control (USER, ADMIN)
- Password stored as encrypted hash (BCrypt)

## Migration Strategy

### For Future Schema Changes

1. **Create new migration file:**
   ```
   database/
   ├── 01-schema.sql
   ├── 02-seed-data.sql
   ├── 03-add-user-profile.sql  ← New migration
   ```

2. **Apply manually or with tool:**
   ```bash
   psql -h localhost -U postgres -d exercises_prod -f 03-add-user-profile.sql
   ```

3. **Or use Flyway/Liquibase:**
   - Version control all changes
   - Automatic migration on startup
   - Rollback support

## Database Schema Diagram

```
┌──────────────────┐
│  muscle_groups   │
│──────────────────│
│ id (PK)          │───┐
│ name (UNIQUE)    │   │
│ description      │   │
└──────────────────┘   │
                       │
                       │ (FK)
                       │
┌──────────────┐   ┌───▼──────────┐
│    users     │   │  exercises   │
│──────────────│   │──────────────│
│ id (PK)      │───┤ id (PK)      │
│ username     │   │ name         │
│ email        │   │ muscle_grp_id│
│ password     │   └───┬──────────┘
│ role         │       │
│ created_at   │       │
└──────────────┘       │
       │               │
       │ (FK)          │ (FK)
       │               │
   ┌───▼───────────────▼───┐
   │   exercise_logs       │
   │───────────────────────│
   │ exercise_log_id (PK)  │───┐
   │ user_id (FK)          │   │
   │ exercise_id (FK)      │   │
   │ date                  │   │
   │ has_failed            │   │
   └───────────────────────┘   │
                               │
                               │ (FK - M2M)
                               │
                   ┌───────────▼───────────┐
                   │ exercise_log_sets     │
                   │───────────────────────│
                   │ exercise_log_id (FK)  │
                   │ exercise_set_id (FK)  │
                   └───┬───────────────────┘
                       │
                       │ (FK)
                       │
               ┌───────▼──────────┐
               │  exercise_sets   │
               │──────────────────│
               │ exercise_set_id  │
               │ weight           │
               │ reps             │
               └──────────────────┘
```

## Troubleshooting

### Scripts Don't Run

**Problem:** SQL scripts are not executed on startup

**Solutions:**
1. Check if volume already exists: `docker volume ls`
2. Remove and recreate:
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

### Permission Denied

**Problem:** Cannot execute init-db.sh

**Solution:**
```bash
chmod +x init-db.sh
```

### Connection Refused

**Problem:** Cannot connect to database

**Solutions:**
1. Check container is running: `docker-compose ps`
2. Wait for health check: Scripts need database ready
3. Verify password: Check .env file matches

### Table Already Exists

**Problem:** Error: relation "users" already exists

**Solutions:**
1. Drop and recreate database manually
2. Or use different database name
3. Or modify script to use IF NOT EXISTS (less safe)

## Verification

After initialization, verify the setup:

```bash
# Connect to database
docker exec -it exercises-postgres-dev psql -U postgres -d exercises_dev

# List tables
\dt

# Check record counts
SELECT 'users' as table_name, COUNT(*) FROM users
UNION ALL
SELECT 'exercises', COUNT(*) FROM exercise_entity
UNION ALL
SELECT 'logs', COUNT(*) FROM exercise_log_entity;

# Exit
\q
```

Expected output:
- 6 tables created
- 6 muscle groups (if seed data loaded)
- 34 exercises (if seed data loaded)
- 0 users, 0 logs (initial state)

## Backup and Restore

### Backup

```bash
# Schema only
docker exec exercises-postgres-dev pg_dump -U postgres -d exercises_dev --schema-only > schema-backup.sql

# Schema + data
docker exec exercises-postgres-dev pg_dump -U postgres -d exercises_dev > full-backup.sql

# Data only
docker exec exercises-postgres-dev pg_dump -U postgres -d exercises_dev --data-only > data-backup.sql
```

### Restore

```bash
# Restore full backup
docker exec -i exercises-postgres-dev psql -U postgres -d exercises_dev < full-backup.sql
```

## Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Docker Postgres Image: https://hub.docker.com/_/postgres
- Spring Boot JPA: https://spring.io/guides/gs/accessing-data-jpa/
