# Database Initialization Complete ✅

## Summary

The Exercise Backend infrastructure now includes **automatic database initialization** with SQL scripts that run on first container startup.

## What Was Created

### SQL Scripts (`database/`)

✅ **01-schema.sql** (Creates database structure)
- All tables (users, exercise_entity, exercise_log_entity, exercise_set_entity, exercise_log_sets)
- Sequences for ID generation
- Indexes for query performance
- Foreign key constraints
- Check constraints for data integrity
- Table comments for documentation

✅ **02-seed-data.sql** (Pre-loads exercises)
- 34 common exercises
- 6 muscle groups (Chest, Back, Shoulders, Legs, Biceps, Triceps)
- Updates sequence to continue from ID 50

✅ **init-db.sh** (Manual initialization script)
- Interactive database setup
- Connection testing
- Optional seed data loading
- Verification and reporting

✅ **README.md** (Comprehensive documentation)
- Usage instructions
- Multiple initialization methods
- Troubleshooting guide
- Schema diagram

### Docker Compose Updates

✅ **dev/docker-compose.yml**
- Mounts `01-schema.sql` to `/docker-entrypoint-initdb.d/`
- Mounts `02-seed-data.sql` to `/docker-entrypoint-initdb.d/`
- Auto-executes on first database creation

✅ **prod/docker-compose.yml**
- Same initialization scripts mounted
- Includes comments about seed data considerations

✅ **Updated README.md**
- Database initialization section
- Links to database documentation
- Notes about automatic initialization

## How It Works

### Automatic Initialization (Docker)

```
docker-compose up -d
    │
    ▼
PostgreSQL Container Starts
    │
    ▼
Checks if database is NEW
    │
    ├─ YES (new volume)
    │  │
    │  ▼
    │  Executes scripts in /docker-entrypoint-initdb.d/
    │  │
    │  ├─ 01-schema.sql (creates tables)
    │  └─ 02-seed-data.sql (loads exercises)
    │
    └─ NO (existing volume)
       │
       ▼
       Skips initialization (data exists)
    │
    ▼
Application Starts
    │
    ▼
Validates schema (ddl-auto=validate in prod)
```

### Postgres docker-entrypoint-initdb.d

PostgreSQL's official Docker image includes initialization support:
- Scripts in `/docker-entrypoint-initdb.d/` run on first start
- Files executed in alphabetical order (01-, 02-, etc.)
- Only runs when database directory is empty
- Supports .sql, .sql.gz, and .sh files

## Production Readiness

### Schema Management

**Current Approach:**
✅ Automatic initialization on fresh database
✅ Suitable for initial deployments
✅ Works for small-scale production

**For Production at Scale:**
Consider migration tools:
- **Flyway** - Version-controlled migrations
- **Liquibase** - Database-independent changes
- **Manual versioned scripts** - Simple but requires discipline

### Why This Works

**Development:**
- `ddl-auto=update` - Hibernate updates schema automatically
- Seed data loaded every time (fresh database)
- Fast iteration

**Production:**
- `ddl-auto=validate` - Hibernate only validates, doesn't modify
- Schema must exist before app starts
- SQL scripts provide that schema
- Seed data optional (only runs once)

## Usage Examples

### First-Time Deployment

```bash
cd exercises-infra/dev
docker-compose up -d
```

**What happens:**
1. PostgreSQL container created
2. Volume `dev_postgres_data` created (empty)
3. Database initialization scripts execute:
   - Schema created
   - 34 exercises loaded
4. Application starts successfully
5. Schema validation passes ✅

### Restarting Services

```bash
docker-compose down
docker-compose up -d
```

**What happens:**
1. Containers stopped
2. Volume persists (data preserved)
3. Containers restarted
4. **Scripts DON'T run** (database exists)
5. Application uses existing data ✅

### Fresh Database (Delete Everything)

```bash
docker-compose down -v
docker-compose up -d
```

**What happens:**
1. Containers stopped
2. **Volume deleted** (all data lost)
3. New volume created (empty)
4. **Scripts run again**
5. Fresh database with seed data ✅

### Manual Initialization

```bash
# From exercises-infra/database/
./init-db.sh
```

**Interactive prompts:**
1. Connection test
2. Database creation (or drop & recreate)
3. Schema application
4. Seed data option (Y/n)
5. Verification summary

## Database Schema

### Tables Created

| Table | Purpose | Records (Initial) |
|-------|---------|-------------------|
| `users` | User accounts | 0 |
| `exercise_entity` | Available exercises | 34 (with seed data) |
| `exercise_log_entity` | Workout sessions | 0 |
| `exercise_set_entity` | Individual sets | 0 |
| `exercise_log_sets` | Log-Set relationships | 0 |

### Sequences Created

- `users_seq` - User ID generation (starts at 1, increment 50)
- `exercise_entity_seq` - Exercise ID generation (starts at 1, increment 50)
- `exercise_log_entity_seq` - Log ID generation (starts at 1, increment 50)

### Indexes Created

**Performance optimizations:**
- `idx_users_username` - Fast username lookups
- `idx_users_email` - Fast email lookups
- `idx_exercise_name_group` - Fast exercise searches
- `idx_exercise_log_user` - User's workout history
- `idx_exercise_log_exercise` - Exercise usage tracking
- `idx_exercise_log_date` - Date-based queries
- `idx_log_sets_log` - Log-to-sets join
- `idx_log_sets_set` - Set-to-logs join

## Verification

### Check Database After Startup

```bash
# Connect to database
docker-compose exec postgres psql -U postgres -d exercises_dev

# List tables
\dt

# Count records
SELECT 'users' as table, COUNT(*) FROM users
UNION ALL
SELECT 'exercises', COUNT(*) FROM exercise_entity;

# Exit
\q
```

**Expected output:**
```
 table     | count
-----------+-------
 users     |     0
 exercises |    34
```

### View Initialization Logs

```bash
# During startup
docker-compose logs postgres

# Look for:
# /usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/01-schema.sql
# /usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/02-seed-data.sql
```

## Troubleshooting

### Scripts Not Running

**Problem:** Database starts but tables don't exist

**Cause:** Volume already exists with data

**Solution:**
```bash
docker-compose down -v  # Delete volume
docker-compose up -d    # Recreate everything
```

### Application Can't Start - Schema Validation Failed

**Problem:** App fails with "Table 'users' doesn't exist"

**Cause:** Database not initialized

**Solutions:**
1. Check if volume is empty
2. Verify SQL scripts are mounted correctly
3. Check postgres logs for errors
4. Try manual initialization with `init-db.sh`

### Seed Data Not Loaded

**Problem:** Tables exist but no exercises

**Cause:** `02-seed-data.sql` didn't execute

**Solutions:**
1. Check file is mounted in docker-compose.yml
2. Verify file exists: `ls database/02-seed-data.sql`
3. Load manually:
   ```bash
   docker-compose exec -T postgres psql -U postgres -d exercises_dev < database/02-seed-data.sql
   ```

### Permission Denied on init-db.sh

**Problem:** Cannot execute script

**Solution:**
```bash
chmod +x database/init-db.sh
```

## Migration Strategy for Existing Deployments

### If You Have an Existing Database

**Option 1: Export and Reimport**
```bash
# Export data
docker-compose exec postgres pg_dump -U postgres exercises_dev --data-only > data-backup.sql

# Stop and remove
docker-compose down -v

# Start fresh (auto-initializes)
docker-compose up -d

# Wait for startup, then import data
docker-compose exec -T postgres psql -U postgres -d exercises_dev < data-backup.sql
```

**Option 2: Manual Schema Update**
```bash
# Apply only schema changes
docker-compose exec -T postgres psql -U postgres -d exercises_dev < database/01-schema.sql
```

**Option 3: Keep Existing Database**
- Don't delete volume
- Database continues to work
- Schema managed by Hibernate in dev (`ddl-auto=update`)

## Benefits

✅ **Zero manual setup** - Database ready on first start
✅ **Consistent schema** - Same structure across all environments
✅ **Version controlled** - SQL scripts in Git
✅ **Production ready** - `ddl-auto=validate` works immediately
✅ **Pre-loaded data** - 34 exercises available out-of-the-box
✅ **Documented** - Comprehensive guides for all scenarios

## File Structure

```
exercises-infra/
├── database/
│   ├── 01-schema.sql           ← Creates all tables
│   ├── 02-seed-data.sql        ← Loads 34 exercises
│   ├── init-db.sh              ← Manual init script
│   ├── README.md               ← Database docs
│   └── DATABASE_INIT_COMPLETE.md  ← This file
├── dev/
│   └── docker-compose.yml      ← Mounts SQL scripts
├── prod/
│   └── docker-compose.yml      ← Mounts SQL scripts
└── README.md                   ← Updated with DB info
```

## Testing

### Test Automatic Initialization

```bash
cd exercises-infra/dev

# Clean slate
docker-compose down -v

# Start and watch logs
docker-compose up

# Look for:
# postgres_1  | ... running /docker-entrypoint-initdb.d/01-schema.sql
# postgres_1  | ... running /docker-entrypoint-initdb.d/02-seed-data.sql
# app_1       | ... Started ExercisesBackendApplication
```

### Test Manual Initialization

```bash
cd exercises-infra/database

# Run init script
./init-db.sh

# Follow prompts
# Should complete successfully
```

### Test Application

```bash
# Access API
curl http://localhost:8080/exercise-logging/api/v1/admin/exercises

# Should return 34 exercises
```

## Next Steps

### For Development
- ✅ Database auto-initializes
- ✅ Seed data pre-loaded
- ✅ Ready to develop and test

### For Production
1. Review `02-seed-data.sql` - decide if pre-loading exercises
2. Consider migration tool (Flyway/Liquibase) for future changes
3. Set up backup strategy
4. Document rollback procedures
5. Test disaster recovery

### For Schema Changes
1. Create new migration file: `03-add-feature.sql`
2. Test in development first
3. Version in Git
4. Apply to production with care
5. Document changes

## Summary

✅ **Database initialization scripts created**
✅ **Automatic initialization configured**
✅ **Manual initialization option available**
✅ **Docker Compose updated**
✅ **Documentation comprehensive**
✅ **Production ready**

The infrastructure now supports **production-grade database initialization** with zero manual intervention! 🚀
