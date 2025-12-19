# Quick Security Setup Guide

Fast reference for setting up JWT authentication and role-based access control.

## 🚀 Quick Start (Development)

### 1. Generate JWT Secret (Optional for dev)

```bash
# Optional - uses default if not set
openssl rand -base64 64
```

### 2. Update .env

```bash
cd dev
cp .env.example .env
nano .env
```

Add (optional - has defaults):
```env
JWT_SECRET=exercises-dev-secret-key-change-in-production-must-be-256-bits
JWT_EXPIRATION=86400000
```

### 3. Start Services

```bash
docker-compose up -d
```

### 4. Register a User

```bash
curl -X POST http://localhost:8080/exercise-logging/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{"username":"user1","email":"user1@test.com","password":"pass123"}'
```

### 5. Login and Get Token

```bash
curl -X POST http://localhost:8080/exercise-logging/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user1","password":"pass123"}'
```

Copy the `token` from response.

### 6. Use Token in Requests

```bash
TOKEN="your-token-here"

curl -X GET http://localhost:8080/exercise-logging/api/v1/users/user1 \
  -H "Authorization: Bearer $TOKEN"
```

## 🔒 Production Setup

### 1. Generate Strong JWT Secret

```bash
# This is REQUIRED for production
openssl rand -base64 64
```

Copy the output (something like):
```
xK7j9mP2vQ8nR5wL4tY6hU3iO1aS0dF7gH9jK2lM4nB6vC8xZ5qW3eR7tY9uI0oP
```

### 2. Update Production .env

```bash
cd prod
cp .env.example .env
nano .env
```

**REQUIRED Configuration:**
```env
DOCKER_USERNAME=your-dockerhub-username
IMAGE_VERSION=1.0.0
FRONTEND_VERSION=1.0.0
DB_PASSWORD=YourStrongDatabasePassword123!
JWT_SECRET=xK7j9mP2vQ8nR5wL4tY6hU3iO1aS0dF7gH9jK2lM4nB6vC8xZ5qW3eR7tY9uI0oP
```

### 3. Deploy

```bash
docker-compose up -d
```

### 4. Verify Security

```bash
# Check services are running
docker-compose ps

# Test registration
curl -X POST http://localhost:8080/exercise-logging/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","email":"admin@company.com","password":"SecurePass123!"}'

# Test login
curl -X POST http://localhost:8080/exercise-logging/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"SecurePass123!"}'
```

## 👤 Managing User Roles

### Check User Role

```bash
docker exec -it exercises-postgres-prod psql -U postgres -d exercises_prod -c \
  "SELECT username, role FROM users;"
```

### Promote User to Admin

```bash
docker exec -it exercises-postgres-prod psql -U postgres -d exercises_prod -c \
  "UPDATE users SET role = 'ADMIN' WHERE username = 'admin';"
```

### Demote Admin to User

```bash
docker exec -it exercises-postgres-prod psql -U postgres -d exercises_prod -c \
  "UPDATE users SET role = 'USER' WHERE username = 'username';"
```

## 🧪 Testing Role-Based Access

### As Regular User (should work)

```bash
TOKEN="user-token-here"

# Log exercise
curl -X POST http://localhost:8080/exercise-logging/api/v1/users/1/logs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "exerciseId": 1,
    "date": "2024-12-19T10:00:00",
    "sets": [{"weight": 100, "reps": 10}]
  }'
```

### As Regular User (should FAIL with 403)

```bash
# Try to create exercise (admin only)
curl -X POST http://localhost:8080/exercise-logging/api/v1/admin/exercises \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Exercise",
    "muscleGroup": "CHEST"
  }'
```

Expected: `403 Forbidden`

### As Admin (should work)

```bash
ADMIN_TOKEN="admin-token-here"

# Create exercise
curl -X POST http://localhost:8080/exercise-logging/api/v1/admin/exercises \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Cable Crossover",
    "muscleGroup": "CHEST"
  }'
```

## 🔄 Rotating JWT Secret

### 1. Generate New Secret

```bash
openssl rand -base64 64
```

### 2. Update .env

```bash
nano .env
# Update JWT_SECRET with new value
```

### 3. Restart Backend

```bash
docker-compose restart backend
```

### 4. All Users Must Login Again

Existing tokens will be invalid. Users need to:
1. Login again
2. Get new token
3. Use new token in requests

## 📋 Environment Variables Cheat Sheet

### Development

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `DOCKER_USERNAME` | ✅ Yes | - | Your Docker Hub username |
| `JWT_SECRET` | ❌ No | (default) | Uses safe default for dev |
| `JWT_EXPIRATION` | ❌ No | 86400000 | 24 hours in ms |
| `DB_PASSWORD` | ❌ No | postgres | Simple for dev |

### Production

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `DOCKER_USERNAME` | ✅ Yes | - | Your Docker Hub username |
| `JWT_SECRET` | ✅ Yes | - | MUST be strong (256+ bits) |
| `JWT_EXPIRATION` | ❌ No | 86400000 | 24 hours in ms |
| `DB_PASSWORD` | ✅ Yes | - | MUST be strong |
| `IMAGE_VERSION` | ⚠️ Recommended | latest | Use specific version |

## 🛡️ Security Checklist

### Before Production Deployment

- [ ] Generated strong JWT secret using OpenSSL
- [ ] JWT secret is at least 256 bits (32 bytes)
- [ ] Set unique JWT secret (not default)
- [ ] JWT secret is in .env file
- [ ] .env file is NOT committed to git
- [ ] Strong database password set
- [ ] Using specific image versions (not latest)
- [ ] All required environment variables set

### After Production Deployment

- [ ] User registration works
- [ ] User login returns JWT token
- [ ] Token works for authenticated endpoints
- [ ] Admin endpoints protected (403 for non-admins)
- [ ] Admin endpoints accessible for admins
- [ ] Password encryption verified
- [ ] Logs show no authentication errors

### Regular Maintenance

- [ ] Rotate JWT secret every 90 days
- [ ] Audit admin user list monthly
- [ ] Monitor failed authentication attempts
- [ ] Review access logs regularly
- [ ] Update base images for security patches
- [ ] Test backup and restore procedures

## 🚨 Common Issues & Solutions

### "Invalid JWT signature"

**Cause:** JWT_SECRET mismatch or was changed

**Solution:**
1. Verify JWT_SECRET in .env matches application
2. Restart backend: `docker-compose restart backend`
3. Users must login again

### "Access Denied" (403)

**Cause:** User doesn't have required role

**Solution:**
```sql
-- Check and update user role
UPDATE users SET role = 'ADMIN' WHERE username = 'username';
```

### "JWT Token Expired"

**Cause:** Token older than JWT_EXPIRATION

**Solution:**
- Login again to get new token
- Or increase JWT_EXPIRATION (not recommended for security)

### Can't Access Admin Endpoints

**Cause:** User has USER role, not ADMIN

**Solution:**
1. Check role: `SELECT username, role FROM users;`
2. Promote: `UPDATE users SET role = 'ADMIN' WHERE username = 'user';`
3. Login again to get new token with ADMIN role

## 📚 API Endpoints Quick Reference

### Public Endpoints (No Auth Required)

```bash
POST /api/v1/users/register    # Register new user
POST /api/v1/users/login        # Login and get JWT token
GET  /actuator/health           # Health check
```

### User Endpoints (Auth Required)

```bash
GET  /api/v1/users/{username}           # Get user profile
POST /api/v1/users/{userId}/logs        # Log exercise
GET  /api/v1/users/{userId}/logs        # Get user's logs
```

### Admin Endpoints (Admin Role Required)

```bash
GET    /api/v1/admin/exercises          # List all exercises
POST   /api/v1/admin/exercises          # Create exercise
GET    /api/v1/admin/exercises/{id}     # Get exercise
PUT    /api/v1/admin/exercises/{id}     # Update exercise
DELETE /api/v1/admin/exercises/{id}     # Delete exercise
```

## 💡 Pro Tips

1. **Store tokens securely in frontend**
   - Use httpOnly cookies (best)
   - Or localStorage with XSS protection
   - Never in plain text

2. **Set appropriate token expiration**
   - 15 min for high security
   - 1 hour for balance
   - 24 hours for convenience (default)

3. **Implement refresh tokens**
   - Keep access tokens short-lived
   - Use refresh tokens for longer sessions
   - Store refresh tokens securely

4. **Monitor authentication**
   - Log all login attempts
   - Alert on repeated failures
   - Track admin actions

5. **Regular security audits**
   - Review user roles quarterly
   - Check for unused admin accounts
   - Verify JWT secret rotation schedule

## 🔗 Additional Resources

- Main README: `exercises-infra/README.md`
- Security Update Details: `exercises-infra/SECURITY_UPDATE.md`
- Database Documentation: `exercises-infra/database/README.md`
- Backend API Docs: http://localhost:8080/exercise-logging/swagger-ui/index.html
- JWT Debugger: https://jwt.io/

---

**Need Help?** Check the full documentation in `README.md` or `SECURITY_UPDATE.md`
