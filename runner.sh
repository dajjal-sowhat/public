#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Parse command line arguments
REPO_URL=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            REPO_URL="$2"
            shift 2
            ;;
        *)
            REPO_URL="$1"
            shift
            ;;
    esac
done

# Check if repository URL is provided
if [ -z "$REPO_URL" ]; then
    print_error "Repository URL is required!"
    echo "Usage: curl [SCRIPT_URL] | bash -s -- -o [REPOSITORY_URL]"
    exit 1
fi

print_info "Starting installation process..."
print_info "Repository: $REPO_URL"

# Extract folder name from repository URL
FOLDER_NAME=$(basename "$REPO_URL" .git)
print_info "Project folder: $FOLDER_NAME"

# Install Git if not present
if ! command -v git &> /dev/null; then
    print_info "Installing Git..."
    sudo apt-get update
    sudo apt-get install -y git
    print_status "Git installed successfully"
else
    print_status "Git is already installed"
fi

# Install NVM if not present
if [ ! -d "$HOME/.nvm" ]; then
    print_info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    print_status "NVM installed successfully"
else
    print_status "NVM is already installed"
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install and use Node.js 22
print_info "Installing Node.js 22..."
nvm install 22
nvm use 22
print_status "Node.js 22 is now active"

# Install PM2 globally
print_info "Installing PM2 globally..."
npm install -g pm2
print_status "PM2 installed successfully"

# Clone repository
if [ -d "$FOLDER_NAME" ]; then
    print_info "Folder $FOLDER_NAME already exists, removing it..."
    rm -rf "$FOLDER_NAME"
fi

print_info "Cloning repository..."
git clone "$REPO_URL" "$FOLDER_NAME"
print_status "Repository cloned successfully"

# Navigate to project directory
cd "$FOLDER_NAME"

# Install dependencies
print_info "Installing dependencies (this may take a while)..."
npm install --force
print_status "Dependencies installed successfully"

# Ask for environment variables
print_info "Configuration needed..."
echo ""
read -p "Enter BOT_TOKEN: " BOT_TOKEN

# Create .env file
print_info "Creating .env file..."
cat > .env << EOF
BOT_TOKEN=$BOT_TOKEN
EOF
print_status ".env file created"

# Start application with PM2
print_info "Starting application with PM2..."
pm2 start npm --name "$FOLDER_NAME" -- run dev
print_status "Application started successfully"

# Save PM2 process list
pm2 save
print_status "PM2 configuration saved"

# Display final information
echo ""
print_status "Installation completed successfully!"
echo ""
echo "Project: $FOLDER_NAME"
echo "Location: $(pwd)"
echo ""
echo "Useful PM2 commands:"
echo "  pm2 list          - Show all running processes"
echo "  pm2 logs $FOLDER_NAME    - Show logs"
echo "  pm2 restart $FOLDER_NAME - Restart application"
echo "  pm2 stop $FOLDER_NAME    - Stop application"
echo "  pm2 delete $FOLDER_NAME  - Remove from PM2"
echo ""
