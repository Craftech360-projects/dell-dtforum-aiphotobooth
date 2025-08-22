#!/bin/bash

echo "Stopping existing Python service..."
# Kill any existing process on port 5555
lsof -ti:5555 | xargs kill -9 2>/dev/null

echo "Waiting for port to be released..."
sleep 2

echo "Starting Python Hand Detection Service..."

# Check if virtual environment exists
if [ ! -d "python_service/venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv python_service/venv
fi

# Activate virtual environment
source python_service/venv/bin/activate

# Install requirements (quick check)
pip install -r python_service/requirements.txt --quiet

# Start the service
echo "Starting service on port 5555 with CORS enabled for all origins..."
python python_service/hand_detection_service.py