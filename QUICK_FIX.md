# Quick Fix for CORS Error on Server

## The Problem

Getting this error?
```
Cross-Origin Request Blocked: The Same Origin Policy disallows reading 
the remote resource at http://localhost:8080/...
```

## The Solution (2 minutes)

### Step 1: Find Your Server IP

```bash
hostname -I
```

Example output: `192.168.1.100` ← Use this!

### Step 2: Update Configuration

```bash
cd exercises-infra/prod
nano .env
```

Add these two lines at the end (replace `192.168.1.100` with YOUR server IP):

```bash
API_URL=http://192.168.1.100:8080/exercise-logging
CORS_ALLOWED_ORIGINS=http://192.168.1.100:3000
```

### Step 3: Restart

```bash
docker-compose down
docker-compose up -d
```

### Step 4: Access Correctly

❌ Don't use: `http://localhost:3000`  
✅ Use: `http://192.168.1.100:3000` (your server IP!)

## Done! 🎉

The application should now work without CORS errors.

---

## Need More Help?

- **Detailed Guide**: See `SERVER_DEPLOYMENT_GUIDE.md`
- **Full Docs**: See `README.md` - CORS troubleshooting section
- **Automated Setup**: Run `./setup-server.sh` for guided configuration
