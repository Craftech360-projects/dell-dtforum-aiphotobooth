#!/bin/bash

echo "Starting Python Hand Detection Service..."

# Check if virtual environment exists
if [ ! -d "python_service/venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv python_service/venv
fi

# Activate virtual environment
source python_service/venv/bin/activate

# Install requirements
echo "Installing dependencies..."
pip install -r python_service/requirements.txt

# Start the service
echo "Starting service on port 5555..."
python python_service/hand_detection_service.py