# Server Deployment Guide

**Guide for deploying the exercise application on a Linux server**

## Problem: CORS and localhost Issues

When deploying on a server, `localhost` doesn't work because:
- **Frontend**: The browser tries to connect from the user's computer
- **Backend**: `localhost` refers to the server itself, not accessible from outside
- **CORS**: Backend needs to allow requests from the actual frontend URL

## Quick Fix

### Step 1: Find Your Server's IP Address

```bash
# Get your server's IP address
hostname -I
# Or
ip addr show | grep "inet " | grep -v 127.0.0.1
```

**Example output**: `192.168.1.100` (use your actual IP)

### Step 2: Update .env File

```bash
cd exercises-infra/prod
nano .env
```

Add/update these variables:

```bash
# Your Docker Hub username
DOCKER_USERNAME=your-dockerhub-username

# Image versions
IMAGE_VERSION=latest
FRONTEND_VERSION=latest

# Database configuration
DB_USERNAME=postgres
DB_PASSWORD=YourStrongPassword123!

# JWT Configuration
JWT_SECRET=your-generated-jwt-secret-here
JWT_EXPIRATION=86400000

# IMPORTANT: Use your server's IP address or domain
# Replace with your actual server IP!
API_URL=http://YOUR_SERVER_IP:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://YOUR_SERVER_IP:3000
```

**Example for IP `192.168.1.100`:**
```bash
API_URL=http://192.168.1.100:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://192.168.1.100:3000
```

**Example for domain `example.com`:**
```bash
API_URL=http://example.com:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://example.com:3000
```

### Step 3: Restart Services

```bash
cd exercises-infra/prod

# Stop services
docker-compose down

# Start with new configuration
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Step 4: Access Application

**From your browser (on any computer):**
```
http://YOUR_SERVER_IP:3000
```

**Example:**
```
http://192.168.1.100:3000
```

## Complete .env Example

```bash
# ============================================
# PRODUCTION CONFIGURATION
# ============================================

# Docker Configuration
DOCKER_USERNAME=yourusername
IMAGE_VERSION=latest
FRONTEND_VERSION=latest

# Database Configuration
DB_USERNAME=postgres
DB_PASSWORD=MySecurePassword123!

# JWT Configuration (REQUIRED)
JWT_SECRET=xK7j9mP2vQ8nR5wL4tY6hU3iO1aS0dF7gH9jK2lM4nB6vC8xZ5qW3eR7tY9uI0oP
JWT_EXPIRATION=86400000

# Network Configuration (IMPORTANT!)
# Replace 192.168.1.100 with your actual server IP or domain
API_URL=http://192.168.1.100:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://192.168.1.100:3000
```

## Troubleshooting

### Issue: Still getting CORS errors

**Check 1: Verify environment variables are set**
```bash
docker-compose exec backend env | grep CORS
docker-compose exec frontend env | grep API
```

**Check 2: Verify CORS origins in backend logs**
```bash
docker-compose logs backend | grep -i cors
```

**Check 3: Test from server itself**
```bash
# This should work from the server
curl http://localhost:8080/exercise-logging/actuator/health

# This should work from any computer
curl http://YOUR_SERVER_IP:8080/exercise-logging/actuator/health
```

### Issue: Cannot connect to frontend

**Check if port 3000 is accessible:**
```bash
# On server
netstat -tlnp | grep 3000

# From another computer
telnet YOUR_SERVER_IP 3000
```

**If port is blocked, check firewall:**
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 3000
sudo ufw allow 8080

# CentOS/RHEL
sudo firewall-cmd --list-all
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

### Issue: Services won't start

**Check logs:**
```bash
docker-compose logs backend
docker-compose logs frontend
docker-compose logs postgres
```

**Common problems:**
1. **JWT_SECRET not set**: Add to .env file
2. **DB_PASSWORD not set**: Add to .env file
3. **Port already in use**: Stop conflicting services
4. **Docker not running**: `sudo systemctl start docker`

### Issue: Frontend connects but registration fails

**This is the CORS issue - ensure:**

1. ✅ `API_URL` uses your server's IP (not localhost)
2. ✅ `CORS_ALLOWED_ORIGINS` includes your server's IP:3000
3. ✅ Services restarted after changing .env
4. ✅ Browser is accessing via server's IP (not localhost)

## Network Configuration Examples

### Scenario 1: Local Network Only

**Server IP**: `192.168.1.100`

```bash
API_URL=http://192.168.1.100:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://192.168.1.100:3000
```

**Access from**: Computers on same network

### Scenario 2: Public Server with Domain

**Domain**: `exercises.example.com`

```bash
API_URL=http://exercises.example.com:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://exercises.example.com:3000
```

**Access from**: Internet (ensure ports are open)

### Scenario 3: Public Server with IP (no domain)

**Public IP**: `203.0.113.10`

```bash
API_URL=http://203.0.113.10:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://203.0.113.10:3000
```

**Access from**: Internet (ensure ports are open)

### Scenario 4: Multiple Access Points

Allow access from multiple origins:

```bash
API_URL=http://192.168.1.100:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://192.168.1.100:3000,http://localhost:3000,http://example.com:3000
```

## Security Considerations

### Production Best Practices

1. **Use HTTPS** (SSL/TLS)
   - Get SSL certificates (Let's Encrypt is free)
   - Use reverse proxy (Nginx or Traefik)
   - Change ports to 443 (HTTPS) and redirect 80→443

2. **Restrict CORS Origins**
   ```bash
   # Only allow your domain
   CORS_ALLOWED_ORIGINS=https://yourdomain.com
   ```

3. **Strong Passwords**
   ```bash
   # Generate strong JWT secret
   openssl rand -base64 64
   
   # Generate strong DB password
   openssl rand -base64 32
   ```

4. **Firewall Rules**
   ```bash
   # Only allow necessary ports
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow ssh
   sudo ufw allow 80/tcp   # HTTP
   sudo ufw allow 443/tcp  # HTTPS
   sudo ufw enable
   ```

5. **Don't expose database port**
   - Remove `5432:5432` from postgres service in docker-compose
   - Database should only be accessible from containers

## Advanced: Using Reverse Proxy

### With Nginx (Recommended)

**Benefits:**
- Single entry point
- HTTPS/SSL support
- No need to expose multiple ports

**Setup:**
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Backend API
    location /exercise-logging {
        proxy_pass http://localhost:8080/exercise-logging;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Then configure:**
```bash
API_URL=http://your-domain.com/exercise-logging
CORS_ALLOWED_ORIGINS=http://your-domain.com
```

## Testing Checklist

After deployment, test these:

- [ ] Frontend accessible at `http://YOUR_SERVER_IP:3000`
- [ ] Backend health check: `http://YOUR_SERVER_IP:8080/exercise-logging/actuator/health`
- [ ] User registration works
- [ ] User login works and returns JWT token
- [ ] Can view exercises
- [ ] Can log workouts
- [ ] CORS errors resolved in browser console
- [ ] Database persists data (restart containers and check)

## Quick Commands Reference

```bash
# Check server IP
hostname -I

# Edit configuration
cd exercises-infra/prod
nano .env

# Restart services
docker-compose down
docker-compose up -d

# View logs
docker-compose logs -f

# Check environment variables
docker-compose exec backend env | grep -E "CORS|API"
docker-compose exec frontend env | grep API

# Test endpoints
curl http://YOUR_SERVER_IP:8080/exercise-logging/actuator/health

# Check if ports are open
sudo netstat -tlnp | grep -E "3000|8080"

# Open firewall ports
sudo ufw allow 3000
sudo ufw allow 8080
```

## Need Help?

### Common Commands

**View container logs:**
```bash
docker-compose logs backend
docker-compose logs frontend
```

**Restart specific service:**
```bash
docker-compose restart backend
docker-compose restart frontend
```

**Check container status:**
```bash
docker-compose ps
```

**Remove everything and start fresh:**
```bash
docker-compose down -v  # WARNING: Deletes database!
docker-compose up -d
```

### Contact

If issues persist:
1. Check logs: `docker-compose logs`
2. Verify configuration: `docker-compose config`
3. Review CORS settings in backend logs
4. Ensure firewall allows ports 3000 and 8080

---

**Remember**: Replace `YOUR_SERVER_IP` with your actual server IP address or domain name in all commands and configuration files!
