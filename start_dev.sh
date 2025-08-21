#!/bin/bash

# Quick development startup script
# Starts both services in separate terminal tabs (macOS)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Start Python backend in new terminal tab
osascript -e "
tell application \"Terminal\"
    activate
    do script \"cd '$SCRIPT_DIR/python_service' && source venv/bin/activate 2>/dev/null || python3 -m venv venv && source venv/bin/activate && pip install -r requirements_unified.txt 2>/dev/null || pip install -r requirements.txt && python unified_backend.py || python hand_detection_service.py\"
end tell
"

# Wait a bit for backend to start
sleep 3

# Start Flutter in new terminal tab
osascript -e "
tell application \"Terminal\"
    activate
    do script \"cd '$SCRIPT_DIR' && flutter run -d web-server --web-port 8080\"
end tell
"

echo "==========================================="
echo "    Dell Photobooth 2025 - Dev Mode       "
echo "==========================================="
echo ""
echo "Services starting in separate Terminal windows:"
echo "  • Python backend on http://localhost:5555"
echo "  • Flutter web on http://localhost:8080"
echo ""
echo "Close Terminal windows to stop services."