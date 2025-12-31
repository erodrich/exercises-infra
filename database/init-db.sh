#!/bin/bash
# Database Initialization Script
# This script initializes the PostgreSQL database with schema and optional seed data

set -e

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-exercises_dev}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🗄️  Exercise Backend - Database Initialization"
echo "=============================================="
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ Error: psql command not found${NC}"
    echo "Please install PostgreSQL client or run this script inside the postgres container"
    exit 1
fi

# Test database connection
echo "📡 Testing database connection..."
export PGPASSWORD="$DB_PASSWORD"

if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c '\q' 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${RED}❌ Error: Cannot connect to database${NC}"
    echo "   Host: $DB_HOST:$DB_PORT"
    echo "   User: $DB_USER"
    exit 1
fi

# Check if database exists, create if not
echo ""
echo "📦 Checking database: $DB_NAME"
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    echo -e "${YELLOW}⚠️  Database '$DB_NAME' already exists${NC}"
    read -p "Do you want to drop and recreate it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Dropping database '$DB_NAME'..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "DROP DATABASE $DB_NAME;"
        echo "📦 Creating database '$DB_NAME'..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"
        echo -e "${GREEN}✅ Database recreated${NC}"
    else
        echo "ℹ️  Using existing database"
    fi
else
    echo "📦 Creating database '$DB_NAME'..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"
    echo -e "${GREEN}✅ Database created${NC}"
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Apply schema
echo ""
echo "📋 Applying schema (01-schema.sql)..."
if [ -f "$SCRIPT_DIR/01-schema.sql" ]; then
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_DIR/01-schema.sql"
    echo -e "${GREEN}✅ Schema applied successfully${NC}"
else
    echo -e "${RED}❌ Error: 01-schema.sql not found${NC}"
    exit 1
fi

# Apply seed data (optional)
echo ""
read -p "Load seed data with 34 exercises? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "🌱 Loading seed data (02-seed-data.sql)..."
    if [ -f "$SCRIPT_DIR/02-seed-data.sql" ]; then
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_DIR/02-seed-data.sql"
        echo -e "${GREEN}✅ Seed data loaded successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  02-seed-data.sql not found, skipping...${NC}"
    fi
else
    echo "ℹ️  Skipping seed data"
fi

# Apply workout plan migration (optional)
echo ""
read -p "Add workout plan tables? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "💪 Applying workout plan migration (03-add-workoutplan.sql)..."
    if [ -f "$SCRIPT_DIR/03-add-workoutplan.sql" ]; then
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_DIR/03-add-workoutplan.sql"
        echo -e "${GREEN}✅ Workout plan tables created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  03-add-workoutplan.sql not found, skipping...${NC}"
    fi
else
    echo "ℹ️  Skipping workout plan migration"
fi

# Verify tables
echo ""
echo "🔍 Verifying database setup..."
TABLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
echo "   Tables created: $TABLE_COUNT"

if [ "$TABLE_COUNT" -ge 5 ]; then
    echo -e "${GREEN}✅ Database initialized successfully!${NC}"
    echo ""
    echo "📊 Database Summary:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\dt"
    
    # Show exercise count if seed data was loaded
    EXERCISE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM exercises;" 2>/dev/null || echo "0")
    if [ "$EXERCISE_COUNT" -gt 0 ]; then
        echo ""
        echo "🏋️  Exercises loaded: $EXERCISE_COUNT"
    fi
    
    # Show workout plan table status
    WORKOUT_PLAN_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'workout_plans';" 2>/dev/null || echo "0")
    if [ "$WORKOUT_PLAN_EXISTS" -eq 1 ]; then
        echo "💪 Workout plan feature: enabled"
    else
        echo "ℹ️  Workout plan feature: not installed (run migration manually if needed)"
    fi
else
    echo -e "${RED}❌ Error: Expected at least 5 tables, found $TABLE_COUNT${NC}"
    exit 1
fi

unset PGPASSWORD

echo ""
echo "✨ Done! Database is ready for the application."
