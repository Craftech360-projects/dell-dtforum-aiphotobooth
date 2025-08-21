#!/usr/bin/env python3
"""
Hand Detection Service for Dell Photobooth
Uses MediaPipe to detect hand gestures and trigger photo capture
"""

import cv2
import mediapipe as mp
import numpy as np
from flask import Flask, jsonify, request
from flask_cors import CORS
import base64
from io import BytesIO
from PIL import Image
import threading
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, origins=['http://localhost:8080', 'http://127.0.0.1:8080'])

# Initialize MediaPipe
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils

class HandDetector:
    def __init__(self):
        self.hands = mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.palm_detected = False
        self.last_detection_time = 0
        self.cooldown_period = 3.0  # seconds
        
    def is_palm_open(self, hand_landmarks):
        """
        Check if the detected hand is showing an open palm
        Returns True if palm is open (all fingers extended)
        """
        if not hand_landmarks:
            return False
            
        # Get landmark positions
        landmarks = hand_landmarks.landmark
        
        # Finger tip and base indices for each finger
        finger_tips = [
            mp_hands.HandLandmark.THUMB_TIP,
            mp_hands.HandLandmark.INDEX_FINGER_TIP,
            mp_hands.HandLandmark.MIDDLE_FINGER_TIP,
            mp_hands.HandLandmark.RING_FINGER_TIP,
            mp_hands.HandLandmark.PINKY_TIP
        ]
        
        finger_bases = [
            mp_hands.HandLandmark.THUMB_MCP,
            mp_hands.HandLandmark.INDEX_FINGER_MCP,
            mp_hands.HandLandmark.MIDDLE_FINGER_MCP,
            mp_hands.HandLandmark.RING_FINGER_MCP,
            mp_hands.HandLandmark.PINKY_MCP
        ]
        
        extended_fingers = 0
        
        # Check each finger (except thumb which has different logic)
        for i in range(1, 5):
            tip_y = landmarks[finger_tips[i]].y
            base_y = landmarks[finger_bases[i]].y
            
            # Finger is extended if tip is above base (lower y value)
            if tip_y < base_y:
                extended_fingers += 1
        
        # Special check for thumb (horizontal movement)
        thumb_tip_x = landmarks[finger_tips[0]].x
        thumb_base_x = landmarks[finger_bases[0]].x
        
        # For right hand, thumb is extended if tip is to the right of base
        # For left hand, it would be opposite
        if abs(thumb_tip_x - thumb_base_x) > 0.1:
            extended_fingers += 1
        
        # Return True if at least 4 fingers are extended
        logger.info(f"Extended fingers count: {extended_fingers}")
        return extended_fingers >= 4
    
    def process_image(self, image_data):
        """
        Process a base64 encoded image and detect if palm is open
        """
        try:
            # Decode base64 image
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            image_bytes = base64.b64decode(image_data)
            image = Image.open(BytesIO(image_bytes))
            
            # Convert to OpenCV format
            frame = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            
            # Convert to RGB for MediaPipe
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Process the frame
            results = self.hands.process(rgb_frame)
            
            current_time = time.time()
            
            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    if self.is_palm_open(hand_landmarks):
                        # Check cooldown
                        if current_time - self.last_detection_time > self.cooldown_period:
                            self.palm_detected = True
                            self.last_detection_time = current_time
                            logger.info("✋ Palm detected!")
                            return True, "Palm detected"
                        else:
                            return False, f"Cooldown active, wait {self.cooldown_period - (current_time - self.last_detection_time):.1f}s"
                return False, "Hand detected but palm not open"
            
            return False, "No hand detected"
            
        except Exception as e:
            logger.error(f"Error processing image: {str(e)}")
            return False, f"Error: {str(e)}"
    
    def reset(self):
        """Reset the detection state"""
        self.palm_detected = False
        self.last_detection_time = 0

# Global detector instance
detector = HandDetector()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'hand_detection'})

@app.route('/detect_palm', methods=['POST'])
def detect_palm():
    """
    Detect if an open palm is present in the image
    Expects base64 encoded image in request body
    """
    try:
        data = request.get_json()
        
        if not data or 'image' not in data:
            return jsonify({
                'success': False,
                'error': 'No image data provided'
            }), 400
        
        image_data = data['image']
        
        # Process the image
        palm_detected, message = detector.process_image(image_data)
        
        return jsonify({
            'success': True,
            'palm_detected': palm_detected,
            'message': message,
            'timestamp': time.time()
        })
        
    except Exception as e:
        logger.error(f"Error in detect_palm: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/reset', methods=['POST'])
def reset_detector():
    """Reset the detector state"""
    detector.reset()
    return jsonify({'success': True, 'message': 'Detector reset'})

@app.route('/test_camera', methods=['GET'])
def test_camera():
    """Test camera access using OpenCV"""
    try:
        cap = cv2.VideoCapture(0)
        if cap.isOpened():
            ret, frame = cap.read()
            cap.release()
            if ret:
                return jsonify({
                    'success': True,
                    'message': 'Camera access successful',
                    'frame_shape': frame.shape
                })
        return jsonify({
            'success': False,
            'message': 'Could not access camera'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })

if __name__ == '__main__':
    logger.info("Starting Hand Detection Service on port 5555...")
    logger.info("Endpoints:")
    logger.info("  - POST /detect_palm - Detect palm in base64 image")
    logger.info("  - POST /reset - Reset detector state")
    logger.info("  - GET /health - Health check")
    logger.info("  - GET /test_camera - Test camera access")
    
    app.run(host='0.0.0.0', port=5555, debug=True)