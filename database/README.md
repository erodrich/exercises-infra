# Database Scripts

## Files

- **`01-schema.sql`** - Creates all tables, indexes, constraints for core functionality
- **`02-seed-data.sql`** - Pre-populates 6 muscle groups and 34 exercises
- **`03-add-workoutplan.sql`** - Creates workout plan feature tables (migration)
- **`init-db.sh`** - Manual database initialization script

## Schema Overview

### Core Tables (01-schema.sql)
- `users` - User accounts with role-based access control
- `muscle_groups` - Exercise classification by muscle groups
- `exercises` - Available exercises with muscle group associations
- `exercise_logs` - Workout session logs
- `exercise_sets` - Individual sets with weight/reps
- `exercise_log_sets` - Join table for logs and sets

### Workout Plan Tables (03-add-workoutplan.sql)
- `workout_plans` - User-created workout plans with duration and active status
- `workout_days` - Individual days within a workout plan (e.g., "Push Day", "Leg Day")
- `exercise_target` - Exercise targets for each day with sets/reps configuration

## Auto-Initialization

These scripts run automatically when using docker-compose on **first startup** only.

Scripts execute in numerical order:
1. **01-schema.sql** - Base schema
2. **02-seed-data.sql** - Sample data
3. **03-add-workoutplan.sql** - Workout plan feature

**Note:** Scripts only run when the database is empty. Existing databases are not modified.

## Manual Initialization

Use the provided script for manual setup:

```bash
cd exercises-infra/database
./init-db.sh
```

The script will:
1. Test database connection
2. Create database if needed (or prompt to recreate)
3. Apply schema (01-schema.sql)
4. Optionally load seed data (02-seed-data.sql)
5. Optionally apply workout plan migration (03-add-workoutplan.sql)
6. Verify setup

### Environment Variables

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=exercises_dev
export DB_USER=postgres
export DB_PASSWORD=postgres

./init-db.sh
```

## Database Migrations

### Adding Workout Plans to Existing Database

If you already have a database without workout plans:

```bash
export PGPASSWORD=postgres
psql -h localhost -U postgres -d exercises_dev -f 03-add-workoutplan.sql
```

This migration:
- Creates 3 new tables
- Adds foreign key relationships to existing `users` and `exercises` tables
- Uses `CASCADE` deletion for data integrity
- Includes validation constraints (duration, reps, sets)

## Table Details

### workout_plans

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT | PK | Primary key |
| name | VARCHAR(255) | NOT NULL | Plan name |
| duration | INTEGER | NOT NULL, > 0 | Duration value |
| duration_unit | VARCHAR(20) | NOT NULL, ENUM | 'WEEKS' or 'MONTHS' |
| is_active | BOOLEAN | NOT NULL, DEFAULT false | Active plan indicator |
| user_id | BIGINT | FK, NOT NULL | Owner reference |

**Indexes:** user_id, is_active, name

### workout_days

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT | PK | Primary key |
| description | VARCHAR(500) | NOT NULL | Day description |
| workout_plan_id | BIGINT | FK, NOT NULL | Parent plan reference |

**Indexes:** workout_plan_id

### exercise_target

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT | PK | Primary key |
| exercise_id | BIGINT | FK, NOT NULL | Exercise reference |
| sets | INTEGER | NOT NULL, > 0 | Target sets |
| min_reps | INTEGER | NOT NULL, > 0 | Minimum reps |
| max_reps | INTEGER | NOT NULL, >= min_reps | Maximum reps |
| workout_day_id | BIGINT | FK, NOT NULL | Parent day reference |

**Indexes:** workout_day_id, exercise_id

## Relationships

```
users (1) -----> (N) workout_plans
workout_plans (1) -----> (N) workout_days
workout_days (1) -----> (N) exercise_target
exercises (1) -----> (N) exercise_target
```

**Cascade Rules:**
- Deleting a user deletes all their workout plans
- Deleting a workout plan deletes all its days
- Deleting a workout day deletes all its exercise targets
- Deleting an exercise deletes all targets using it

See [../README.md](../README.md) for complete setup instructions.
