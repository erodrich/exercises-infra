# Security & Infrastructure Update

This document describes the security enhancements made to the exercises-infra project to support JWT authentication and role-based access control.

## Summary of Changes

### 1. Database Schema Updates (`database/01-schema.sql`)

**Added Role-Based Access Control:**
- Added `role` column to `users` table (VARCHAR(20), NOT NULL, DEFAULT 'USER')
- Added check constraint to enforce valid roles: `CHECK (role IN ('USER', 'ADMIN'))`
- Added documentation comment for the role column

**Before:**
```sql
CREATE TABLE users (
    id BIGINT NOT NULL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP(6) NOT NULL,
    ...
);
```

**After:**
```sql
CREATE TABLE users (
    id BIGINT NOT NULL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMP(6) NOT NULL,
    ...
    CONSTRAINT chk_role CHECK (role IN ('USER', 'ADMIN'))
);
```

### 2. Development Environment (`dev/docker-compose.yml`)

**Added JWT Configuration:**
```yaml
environment:
  # ... existing DB config ...
  # JWT Configuration (for development - use secrets in production)
  JWT_SECRET: ${JWT_SECRET:-exercises-dev-secret-key-change-in-production-must-be-256-bits}
  JWT_EXPIRATION: ${JWT_EXPIRATION:-86400000}
```

**Features:**
- JWT_SECRET has a development default (can be overridden in .env)
- JWT_EXPIRATION defaults to 24 hours (86400000 ms)
- Uses environment variable substitution with defaults

### 3. Production Environment (`prod/docker-compose.yml`)

**Added JWT Configuration:**
```yaml
environment:
  # ... existing DB config ...
  # JWT Configuration (REQUIRED - use strong secret in production)
  JWT_SECRET: ${JWT_SECRET}  # REQUIRED: Strong secret key (256+ bits)
  JWT_EXPIRATION: ${JWT_EXPIRATION:-86400000}  # 24 hours in milliseconds
```

**Features:**
- JWT_SECRET is REQUIRED (no default for production)
- JWT_EXPIRATION has a sensible default but can be customized
- Clear documentation in comments

### 4. Documentation Updates (`README.md`)

**Added Security Features Section:**
- JWT Authentication
- Role-Based Access Control
- Password Encryption (BCrypt)
- Secure Configuration

**Updated Quick Start Guides:**
- Added JWT configuration examples for both dev and prod
- Added command to generate secure JWT secrets using OpenSSL
- Added JWT variables to environment variable tables

**Enhanced Security Best Practices:**
- Must generate secure JWT secret for production
- Never use default JWT secret in production
- Rotate JWT secrets periodically

**Improved Production Checklist:**
- Generate secure JWT_SECRET
- Test user authentication
- Verify JWT tokens
- Test role-based access
- Document JWT secret rotation procedure

### 5. Database Documentation (`database/README.md`)

**Updated Schema Documentation:**
- Documented role column in users table
- Added role-based access control to schema details
- Updated database diagram to include role field
- Clarified password storage (BCrypt hashing)

## Security Features

### JWT Authentication

**Token-Based Security:**
- Stateless authentication using JSON Web Tokens
- Tokens contain user ID and role information
- Configurable expiration time (default: 24 hours)

**Configuration:**
- `JWT_SECRET`: Secret key for signing tokens (must be 256+ bits)
- `JWT_EXPIRATION`: Token lifetime in milliseconds

### Role-Based Access Control (RBAC)

**Two Roles:**
1. **USER** (default)
   - Can register and login
   - Can log their own exercises
   - Can view their own workout history
   - Cannot manage master data

2. **ADMIN**
   - All USER permissions
   - Can manage exercises (CRUD operations)
   - Can manage muscle groups
   - Can access admin endpoints

### Password Security

- Passwords encrypted using BCrypt algorithm
- Salted and hashed before storage
- Never stored or transmitted in plain text
- Spring Security handles encryption automatically

## Environment Variables

### Development (.env)

```bash
# Required
DOCKER_USERNAME=your-dockerhub-username

# Optional (have sensible defaults)
IMAGE_VERSION=latest
FRONTEND_VERSION=latest
DB_PASSWORD=postgres
JWT_SECRET=exercises-dev-secret-key-change-in-production-must-be-256-bits
JWT_EXPIRATION=86400000  # 24 hours
```

### Production (.env)

```bash
# Required
DOCKER_USERNAME=your-dockerhub-username
DB_PASSWORD=YourSecurePassword123!
JWT_SECRET=your-strong-256-bit-secret-key-here

# Recommended
IMAGE_VERSION=1.0.0  # Use specific version
FRONTEND_VERSION=1.0.0  # Use specific version

# Optional
DB_USERNAME=postgres
JWT_EXPIRATION=86400000  # 24 hours
```

## Generating Secure JWT Secrets

### Using OpenSSL (Recommended)

```bash
openssl rand -base64 64
```

This generates a 512-bit (64 bytes) base64-encoded random string.

### Using /dev/urandom

```bash
head -c 64 /dev/urandom | base64
```

### Example Output

```
xK7j9mP2vQ8nR5wL4tY6hU3iO1aS0dF7gH9jK2lM4nB6vC8xZ5qW3eR7tY9uI0oP
```

## Migration Guide

### For Existing Deployments

If you already have a running deployment without JWT support:

1. **Stop the services:**
   ```bash
   docker-compose down
   ```

2. **Update the database schema:**
   ```bash
   # Backup first!
   docker exec exercises-postgres-prod pg_dump -U postgres exercises_prod > backup.sql
   
   # Add role column
   docker exec -it exercises-postgres-prod psql -U postgres -d exercises_prod -c \
     "ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'USER';"
   
   docker exec -it exercises-postgres-prod psql -U postgres -d exercises_prod -c \
     "ALTER TABLE users ADD CONSTRAINT chk_role CHECK (role IN ('USER', 'ADMIN'));"
   ```

3. **Generate JWT secret:**
   ```bash
   openssl rand -base64 64
   ```

4. **Update .env file:**
   ```bash
   echo "JWT_SECRET=<generated-secret-here>" >> .env
   ```

5. **Pull latest images:**
   ```bash
   docker-compose pull
   ```

6. **Start services:**
   ```bash
   docker-compose up -d
   ```

7. **Verify:**
   ```bash
   # Check backend logs
   docker-compose logs backend
   
   # Test health endpoint
   curl http://localhost:8080/exercise-logging/actuator/health
   ```

### For Fresh Deployments

For new deployments, simply follow the updated Quick Start guide in README.md. The database schema will be created automatically with the role column included.

## Testing

### Test User Registration

```bash
curl -X POST http://localhost:8080/exercise-logging/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Test User Login

```bash
curl -X POST http://localhost:8080/exercise-logging/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

Expected response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "username": "testuser",
  "email": "test@example.com",
  "role": "USER"
}
```

### Test Protected Endpoint

```bash
# Get the token from login response
TOKEN="your-jwt-token-here"

curl -X GET http://localhost:8080/exercise-logging/api/v1/users/testuser \
  -H "Authorization: Bearer $TOKEN"
```

### Test Admin Endpoint (Should fail for USER role)

```bash
curl -X GET http://localhost:8080/exercise-logging/api/v1/admin/exercises \
  -H "Authorization: Bearer $TOKEN"
```

Expected: 403 Forbidden (if user is not ADMIN)

## Security Best Practices

### JWT Secret Management

1. **Never use default secrets in production**
   - Always generate a unique secret for each environment
   - Use at least 256 bits (32 bytes) of randomness

2. **Store secrets securely**
   - Use environment variables (not hardcoded)
   - Consider Docker secrets for production
   - Never commit secrets to version control

3. **Rotate secrets periodically**
   - Plan for secret rotation (e.g., every 90 days)
   - Have a procedure to update without downtime
   - Document the rotation process

### JWT Token Expiration

1. **Choose appropriate expiration**
   - 24 hours (default) is reasonable for most apps
   - Shorter for high-security applications
   - Longer for convenience (with refresh tokens)

2. **Implement token refresh**
   - Consider implementing refresh tokens
   - Allow users to stay logged in longer
   - More secure than long-lived access tokens

### Role-Based Access

1. **Principle of least privilege**
   - Users get USER role by default
   - Manually promote to ADMIN when needed
   - Audit admin access regularly

2. **Protect admin endpoints**
   - Always check role in controller methods
   - Use Spring Security annotations
   - Log admin actions for audit trail

## Troubleshooting

### JWT Validation Errors

**Problem:** "Invalid JWT signature" errors in logs

**Solution:**
- Verify JWT_SECRET matches between deployments
- Check if secret was changed after tokens were issued
- Users need to login again after secret rotation

### Role Access Denied

**Problem:** User gets 403 when accessing admin endpoints

**Solution:**
```sql
-- Check user role in database
SELECT id, username, role FROM users WHERE username = 'username';

-- Update user to admin if needed
UPDATE users SET role = 'ADMIN' WHERE username = 'username';
```

### Missing Role Column

**Problem:** Database error about missing 'role' column

**Solution:**
```bash
# Add the column to existing database
docker exec -it exercises-postgres-prod psql -U postgres -d exercises_prod -c \
  "ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'USER';"
```

## Additional Resources

- [JWT.io](https://jwt.io/) - JWT debugger and documentation
- [Spring Security Documentation](https://docs.spring.io/spring-security/reference/index.html)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- Backend README: `exercises-backend/README.md`
- Database README: `database/README.md`

## Version History

- **v1.1** (2024-12-19) - Added JWT authentication and role-based access control
- **v1.0** (Initial) - Basic user authentication without JWT
