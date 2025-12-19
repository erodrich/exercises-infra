# Changelog - exercises-infra

All notable changes to the exercises-infra project.

## [1.1.0] - 2024-12-19

### Added

#### Security Features
- JWT authentication support with configurable secrets
- Role-based access control (USER/ADMIN)
- Password encryption support (BCrypt via Spring Security)
- Secure environment-based configuration

#### Documentation
- `SECURITY_UPDATE.md` - Comprehensive security implementation guide
- `QUICK_SECURITY_GUIDE.md` - Quick reference for security setup
- `CHANGES.md` - This changelog file

#### Database
- `role` column in users table (VARCHAR(20), NOT NULL, DEFAULT 'USER')
- Check constraint for valid roles: `CHECK (role IN ('USER', 'ADMIN'))`
- Comments documenting the role column
- Updated schema version to 1.1.0

#### Environment Variables
- `JWT_SECRET` - JWT signing key configuration
- `JWT_EXPIRATION` - Token expiration time configuration

### Changed

#### Docker Compose Files
- **dev/docker-compose.yml**
  - Added JWT_SECRET with development-friendly default
  - Added JWT_EXPIRATION with 24-hour default
  - Added inline documentation

- **prod/docker-compose.yml**
  - Added JWT_SECRET as required variable (no default)
  - Added JWT_EXPIRATION with default
  - Added security warnings in comments

#### Documentation
- **README.md**
  - Added "Features" section highlighting security
  - Updated Quick Start guides with JWT configuration
  - Added OpenSSL command for generating secure secrets
  - Updated environment variable tables
  - Enhanced security best practices section
  - Expanded production deployment checklist
  - Added JWT secret rotation guidance

- **database/README.md**
  - Updated table descriptions for role-based access
  - Added role field to database schema diagram
  - Documented role check constraint
  - Added BCrypt password encryption note
  - Enhanced schema details section

#### Database Schema
- Updated version from 1.0.0 to 1.1.0
- Added role support to users table
- Added documentation for RBAC features

### Migration Guide

#### For Existing Deployments

If you have an existing deployment, follow these steps:

1. **Backup your database**
   ```bash
   docker exec exercises-postgres-prod pg_dump -U postgres exercises_prod > backup.sql
   ```

2. **Add role column to users table**
   ```bash
   docker exec -it exercises-postgres-prod psql -U postgres -d exercises_prod -c \
     "ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'USER';"
   
   docker exec -it exercises-postgres-prod psql -U postgres -d exercises_prod -c \
     "ALTER TABLE users ADD CONSTRAINT chk_role CHECK (role IN ('USER', 'ADMIN'));"
   ```

3. **Generate JWT secret**
   ```bash
   openssl rand -base64 64
   ```

4. **Update .env file**
   ```bash
   echo "JWT_SECRET=<your-generated-secret>" >> .env
   ```

5. **Update docker-compose files**
   ```bash
   git pull origin main
   ```

6. **Restart services**
   ```bash
   docker-compose down
   docker-compose pull
   docker-compose up -d
   ```

#### For Fresh Deployments

No migration needed! Just follow the updated Quick Start guide in README.md.

### Security Considerations

#### Critical Changes
- JWT_SECRET is now REQUIRED for production deployments
- Role column must be present in users table
- Default role is USER (ADMIN must be assigned manually)

#### Best Practices
- Always generate strong JWT secrets (256+ bits)
- Never commit .env files to version control
- Rotate JWT secrets periodically (every 90 days recommended)
- Use specific image versions in production (not `latest`)
- Monitor authentication logs for suspicious activity

### Breaking Changes

#### Production Deployments
- **BREAKING**: Production deployments now require `JWT_SECRET` environment variable
  - No default is provided for security reasons
  - Deployment will fail if not set
  - Generate using: `openssl rand -base64 64`

#### Database Schema
- **NON-BREAKING**: Users table includes role column
  - Existing users get DEFAULT 'USER' role
  - No data loss
  - Backward compatible (application handles missing column gracefully)

### Compatibility

#### Backend Version
- **Required**: exercises-backend v1.1.0 or higher
- **Features**: JWT authentication, RBAC support
- **Database**: Compatible with schema v1.1.0

#### Docker
- **Docker**: 20.10+ (no change)
- **Compose**: 2.0+ (no change)
- **PostgreSQL**: 16-alpine (no change)

### Testing

All changes have been validated:
- ✅ Fresh database initialization includes role column
- ✅ JWT_SECRET configuration works in dev environment
- ✅ JWT_SECRET requirement enforced in prod environment
- ✅ Docker compose files validate successfully
- ✅ Documentation is complete and accurate

### Documentation Structure

```
exercises-infra/
├── CHANGES.md                     # This file (NEW)
├── README.md                      # Main docs (UPDATED)
├── SECURITY_UPDATE.md             # Security guide (NEW)
├── QUICK_SECURITY_GUIDE.md        # Quick ref (NEW)
├── dev/
│   └── docker-compose.yml         # (UPDATED)
├── prod/
│   └── docker-compose.yml         # (UPDATED)
└── database/
    ├── 01-schema.sql              # (UPDATED)
    └── README.md                  # (UPDATED)
```

### Upgrade Path

#### From v1.0.0 to v1.1.0

**Development:**
1. Pull latest changes: `git pull`
2. Optional: Set custom JWT_SECRET in .env
3. Restart: `docker-compose down && docker-compose up -d`

**Production:**
1. **REQUIRED**: Generate JWT_SECRET
2. Backup database
3. Update schema (add role column)
4. Update .env with JWT_SECRET
5. Pull latest changes: `git pull`
6. Pull latest images: `docker-compose pull`
7. Restart: `docker-compose down && docker-compose up -d`
8. Verify: Test authentication endpoints

### Rollback Procedure

If you need to rollback to v1.0.0:

1. **Backup current state**
   ```bash
   docker exec exercises-postgres-prod pg_dump -U postgres exercises_prod > backup-v1.1.0.sql
   ```

2. **Checkout previous version**
   ```bash
   git checkout v1.0.0
   ```

3. **Note**: Database schema changes are backward compatible
   - Role column can remain (will be ignored by v1.0.0)
   - Or remove if desired: `ALTER TABLE users DROP COLUMN role;`

4. **Restart services**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Known Issues

None at this time.

### Deprecations

None at this time.

### Contributors

- Infrastructure updated to match backend security features
- Comprehensive documentation added
- Production-ready security configurations

### References

- Backend Changelog: `exercises-backend/docs/CHANGELOG.md`
- JWT Documentation: https://jwt.io/
- Spring Security: https://docs.spring.io/spring-security/
- OWASP Authentication: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html

---

## [1.0.0] - 2024-12-01

### Initial Release

#### Features
- Docker Compose configurations for dev and prod
- PostgreSQL 16 database setup
- Automatic database initialization
- 34 pre-populated exercises
- Health checks for all services
- Comprehensive documentation

#### Services
- PostgreSQL 16 Alpine
- exercises-backend (Spring Boot)
- exercises-frontend (React + Nginx)

#### Documentation
- Main README with Quick Start
- Database initialization guide
- Environment-specific configurations
- Troubleshooting guide

---

**Version Format**: [MAJOR.MINOR.PATCH]
- MAJOR: Incompatible API/schema changes
- MINOR: Backward-compatible functionality
- PATCH: Backward-compatible bug fixes
