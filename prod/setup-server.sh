#!/bin/bash
# Server Deployment Setup Script
# This script helps configure the .env file for server deployment

set -e

echo "=========================================="
echo "Exercise App - Server Deployment Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ -f .env ]; then
    echo -e "${YELLOW}Warning: .env file already exists${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    cp .env .env.backup
    echo -e "${GREEN}Backed up existing .env to .env.backup${NC}"
fi

echo ""
echo "=========================================="
echo "Step 1: Network Configuration"
echo "=========================================="
echo ""

# Detect server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}Detected server IP: $SERVER_IP${NC}"
echo ""
read -p "Is this correct? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    read -p "Enter your server IP or domain: " SERVER_IP
fi

echo ""
echo "=========================================="
echo "Step 2: Docker Configuration"
echo "=========================================="
echo ""

read -p "Enter your Docker Hub username: " DOCKER_USERNAME
read -p "Enter backend image version (default: latest): " IMAGE_VERSION
IMAGE_VERSION=${IMAGE_VERSION:-latest}
read -p "Enter frontend image version (default: latest): " FRONTEND_VERSION
FRONTEND_VERSION=${FRONTEND_VERSION:-latest}

echo ""
echo "=========================================="
echo "Step 3: Database Configuration"
echo "=========================================="
echo ""

read -p "Enter database username (default: postgres): " DB_USERNAME
DB_USERNAME=${DB_USERNAME:-postgres}
read -sp "Enter database password: " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Error: Database password is required${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 4: JWT Configuration"
echo "=========================================="
echo ""

echo "Generating JWT secret..."
JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
echo -e "${GREEN}JWT secret generated${NC}"
echo ""

read -p "Enter JWT token expiration in milliseconds (default: 86400000 = 24h): " JWT_EXPIRATION
JWT_EXPIRATION=${JWT_EXPIRATION:-86400000}

echo ""
echo "=========================================="
echo "Step 5: HTTPS/SSL Configuration"
echo "=========================================="
echo ""

read -p "Enable HTTPS with Let's Encrypt? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    LETSENCRYPT=true
    echo ""
    echo -e "${YELLOW}Important: For Let's Encrypt to work:${NC}"
    echo "  1. You must have a domain name (e.g., erodrich.duckdns.org)"
    echo "  2. Domain must point to this server's public IP"
    echo "  3. Ports 80 and 443 must be open on firewall"
    echo ""
    
    read -p "Enter your domain name (e.g., erodrich.duckdns.org): " LE_FQDN
    
    if [ -z "$LE_FQDN" ]; then
        echo -e "${RED}Error: Domain name is required for HTTPS${NC}"
        exit 1
    fi
    
    read -p "Enter your email for Let's Encrypt notifications: " LE_EMAIL
    
    if [ -z "$LE_EMAIL" ]; then
        echo -e "${RED}Error: Email is required for Let's Encrypt${NC}"
        exit 1
    fi
    
    read -p "Enter timezone (default: UTC): " TZ
    TZ=${TZ:-UTC}
    
    # Set URLs for HTTPS
    API_URL="https://${LE_FQDN}/exercise-logging"
    CORS_ORIGINS="https://${LE_FQDN},http://frontend"
    SERVER_URL="https://${LE_FQDN}"
else
    LETSENCRYPT=false
    LE_EMAIL=""
    LE_FQDN=""
    TZ="UTC"
    
    # Determine if using IP or domain
    if [[ $SERVER_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Using IP address: $SERVER_IP"
        API_URL="http://${SERVER_IP}:8080/exercise-logging"
        CORS_ORIGINS="http://${SERVER_IP}:3000"
        SERVER_URL="http://${SERVER_IP}:3000"
    else
        echo "Using domain: $SERVER_IP"
        API_URL="http://${SERVER_IP}:8080/exercise-logging"
        CORS_ORIGINS="http://${SERVER_IP}:3000"
        SERVER_URL="http://${SERVER_IP}:3000"
    fi
fi

echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo "----------------------------------------"
echo "Server: $SERVER_IP"
echo "Docker Hub: $DOCKER_USERNAME"
echo "Backend Version: $IMAGE_VERSION"
echo "Frontend Version: $FRONTEND_VERSION"
echo "Database User: $DB_USERNAME"
if [ "$LETSENCRYPT" = true ]; then
    echo "HTTPS: Enabled"
    echo "Domain: $LE_FQDN"
    echo "Email: $LE_EMAIL"
    echo "Timezone: $TZ"
else
    echo "HTTPS: Disabled"
fi
echo "API URL: $API_URL"
echo "CORS Origins: $CORS_ORIGINS"
echo "----------------------------------------"
echo ""

read -p "Does this look correct? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Aborted. Run the script again."
    exit 1
fi

echo ""
echo "Creating .env file..."

# Create .env file
if [ "$LETSENCRYPT" = true ]; then
cat > .env << EOF
# ============================================
# PRODUCTION CONFIGURATION (WITH HTTPS)
# Generated: $(date)
# ============================================

# Docker Configuration
DOCKER_USERNAME=$DOCKER_USERNAME
IMAGE_VERSION=$IMAGE_VERSION
FRONTEND_VERSION=$FRONTEND_VERSION

# Database Configuration
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRATION=$JWT_EXPIRATION

# HTTPS/SSL Configuration (Let's Encrypt)
LETSENCRYPT=$LETSENCRYPT
LE_EMAIL=$LE_EMAIL
LE_FQDN=$LE_FQDN
TZ=$TZ

# Network Configuration
CORS_ALLOWED_ORIGINS=$CORS_ORIGINS

# ============================================
# Notes:
# - Application accessible at: https://$LE_FQDN
# - HTTP (port 80) automatically redirects to HTTPS (port 443)
# - SSL certificate will be generated on first startup
# - Make sure firewall allows ports 80 and 443
# - Domain must point to this server's public IP
# ============================================
EOF
else
cat > .env << EOF
# ============================================
# PRODUCTION CONFIGURATION (HTTP ONLY)
# Generated: $(date)
# ============================================

# Docker Configuration
DOCKER_USERNAME=$DOCKER_USERNAME
IMAGE_VERSION=$IMAGE_VERSION
FRONTEND_VERSION=$FRONTEND_VERSION

# Database Configuration
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRATION=$JWT_EXPIRATION

# HTTPS/SSL Configuration (Disabled)
LETSENCRYPT=false
TZ=$TZ

# Network Configuration
CORS_ALLOWED_ORIGINS=$CORS_ORIGINS

# ============================================
# Notes:
# - Frontend accessible at: http://$SERVER_IP:3000
# - Backend API at: http://$SERVER_IP:8080/exercise-logging
# - Make sure firewall allows ports 3000 and 8080
# - HTTPS is disabled - consider enabling for production
# ============================================
EOF
fi

echo -e "${GREEN}✓ .env file created successfully${NC}"
echo ""

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Review the .env file:"
echo "   nano .env"
echo ""

if [ "$LETSENCRYPT" = true ]; then
    echo "2. Ensure firewall allows ports 80 and 443:"
    echo "   sudo ufw allow 80"
    echo "   sudo ufw allow 443"
    echo "   sudo ufw allow 8080  # For direct backend access (optional)"
    echo ""
    echo "3. Verify DNS points to this server:"
    echo "   nslookup $LE_FQDN"
    echo "   # Should return: $SERVER_IP"
    echo ""
    echo "4. Start the services:"
    echo "   docker-compose up -d"
    echo ""
    echo "5. Watch SSL certificate generation (IMPORTANT):"
    echo "   docker-compose logs -f nginx-le"
    echo "   # Wait for: 'Certificate successfully obtained'"
    echo "   # This takes 30-60 seconds on first startup"
    echo ""
    echo "6. Check the logs:"
    echo "   docker-compose logs -f backend"
    echo "   docker-compose logs -f frontend"
    echo ""
    echo "7. Access the application:"
    echo "   https://$LE_FQDN"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "- First startup takes 30-60 seconds for SSL certificate"
    echo "- HTTP requests will automatically redirect to HTTPS"
    echo "- Certificate renews automatically every 60 days"
else
    echo "2. Ensure firewall allows ports 3000 and 8080:"
    echo "   sudo ufw allow 3000"
    echo "   sudo ufw allow 8080"
    echo ""
    echo "3. Start the services:"
    echo "   docker-compose up -d"
    echo ""
    echo "4. Check the logs:"
    echo "   docker-compose logs -f"
    echo ""
    echo "5. Access the application:"
    echo "   $SERVER_URL"
    echo ""
    echo -e "${YELLOW}Note: HTTPS is disabled. Consider enabling for production.${NC}"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
