#!/bin/bash

# Dell Photobooth 2025 - Startup Script
# This script starts both the Python backend and Flutter web application

echo "==========================================="
echo "    Dell Photobooth 2025 - Starting...     "
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    lsof -i:$1 >/dev/null 2>&1
}

# Function to kill process on port
kill_port() {
    local port=$1
    if port_in_use $port; then
        echo -e "${YELLOW}Port $port is in use. Killing existing process...${NC}"
        lsof -ti:$port | xargs kill -9 2>/dev/null
        sleep 1
    fi
}

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Python
if ! command_exists python3; then
    echo -e "${RED}Error: Python 3 is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python 3 found${NC}"

# Check Flutter
if ! command_exists flutter; then
    echo -e "${RED}Error: Flutter is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter found${NC}"

# Clean up any existing processes on our ports
kill_port 5555
kill_port 8080

# Setup Python backend
echo -e "\n${BLUE}Setting up Python backend...${NC}"
cd "$SCRIPT_DIR/python_service"

# Load environment variables from .env if it exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}Loading environment variables from .env file...${NC}"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${YELLOW}No .env file found. Make sure to set SUPABASE_URL and SUPABASE_ANON_KEY${NC}"
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install/upgrade pip
pip install --upgrade pip --quiet

# Install requirements
echo -e "${YELLOW}Installing Python dependencies...${NC}"
if [ -f "requirements_lite.txt" ]; then
    pip install -r requirements_lite.txt --quiet
elif [ -f "requirements_unified.txt" ]; then
    pip install -r requirements_unified.txt --quiet
else
    # Fallback to original requirements if unified doesn't exist
    pip install -r requirements.txt --quiet
fi

# Start Python backend in background
echo -e "${GREEN}Starting Python backend on port 5555...${NC}"
if [ -f "unified_backend_lite.py" ]; then
    python unified_backend_lite.py > backend.log 2>&1 &
elif [ -f "unified_backend.py" ]; then
    python unified_backend.py > backend.log 2>&1 &
else
    # Fallback to original service if unified doesn't exist
    python hand_detection_service.py > backend.log 2>&1 &
fi
PYTHON_PID=$!

# Wait for backend to start
echo -e "${YELLOW}Waiting for backend to initialize...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:5555/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Python backend is running${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: Backend failed to start. Check python_service/backend.log${NC}"
        kill $PYTHON_PID 2>/dev/null
        exit 1
    fi
    sleep 1
done

# Start Flutter web application
echo -e "\n${BLUE}Starting Flutter web application...${NC}"
cd "$SCRIPT_DIR"

# Get Flutter dependencies
echo -e "${YELLOW}Getting Flutter dependencies...${NC}"
flutter pub get --suppress-analytics

# Build and run Flutter web
echo -e "${GREEN}Starting Flutter web on port 8080...${NC}"
echo -e "${YELLOW}Running command: flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0${NC}"

# Run Flutter in background and capture output
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 > flutter.log 2>&1 &
FLUTTER_PID=$!

# Check if Flutter process started
sleep 2
if ! kill -0 $FLUTTER_PID 2>/dev/null; then
    echo -e "${RED}Flutter failed to start. Check flutter.log for details${NC}"
    cat flutter.log
    exit 1
fi

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    
    # Kill Flutter process
    if [ ! -z "$FLUTTER_PID" ]; then
        kill $FLUTTER_PID 2>/dev/null
        echo -e "${GREEN}✓ Flutter stopped${NC}"
    fi
    
    # Kill Python process
    if [ ! -z "$PYTHON_PID" ]; then
        kill $PYTHON_PID 2>/dev/null
        echo -e "${GREEN}✓ Python backend stopped${NC}"
    fi
    
    # Deactivate virtual environment
    deactivate 2>/dev/null
    
    echo -e "${GREEN}Photobooth shutdown complete${NC}"
    exit 0
}

# Set up trap to cleanup on script exit
trap cleanup EXIT INT TERM

# Wait for Flutter to be ready
echo -e "\n${YELLOW}Waiting for Flutter web to compile...${NC}"
sleep 5

# Display URLs
echo -e "\n${GREEN}==========================================="
echo -e "    Dell Photobooth 2025 - Ready!          "
echo -e "==========================================="
echo -e "${NC}"
echo -e "${BLUE}Access the application at:${NC}"
echo -e "  ${GREEN}➜${NC} Local:    http://localhost:8080"

# Get network IP (works on macOS)
if command -v ifconfig >/dev/null 2>&1; then
    NETWORK_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    echo -e "  ${GREEN}➜${NC} Network:  http://${NETWORK_IP}:8080"
fi

echo -e ""
echo -e "${BLUE}Backend API available at:${NC}"
echo -e "  ${GREEN}➜${NC} Health:   http://localhost:5555/health"
echo -e ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo -e ""
echo -e "${BLUE}Logs:${NC}"
echo -e "  Backend: python_service/backend.log"
echo -e "  Flutter: flutter.log"
echo -e ""
echo -e "${YELLOW}Monitoring Flutter output...${NC}"
echo -e ""

# Monitor Flutter output
tail -f flutter.log &
TAIL_PID=$!

# Wait for Flutter process
wait $FLUTTER_PID

# Kill tail when Flutter exits
kill $TAIL_PID 2>/dev/null