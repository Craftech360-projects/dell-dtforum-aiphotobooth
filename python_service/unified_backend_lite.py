#!/usr/bin/env python3
"""
Unified Backend Service for Dell Photobooth (Lite Version)
Combines hand detection and face swapping functionality
Without GFPGAN enhancement to reduce dependencies
"""

import sqlite3
import os
import uuid
import shutil
import warnings
import time
import logging
import base64
from io import BytesIO
import threading
from typing import Optional, Dict, Any

# Web framework imports
from fastapi import FastAPI, File, Form, UploadFile, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# Image processing imports
import cv2
import numpy as np
from PIL import Image
import mediapipe as mp

# Face swapping imports
from insightface.app import FaceAnalysis
import insightface
import requests

# Supabase integration
from supabase_config import SupabaseStorage

# Suppress warnings
warnings.filterwarnings("ignore", category=UserWarning, module="onnxruntime")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",  # Flutter web default
        "http://127.0.0.1:8080",
        "http://localhost:5173",
        "http://localhost:3000",
        "*"  # Allow all origins in development
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type", "Authorization"],
)

# Configuration
UPLOAD_FOLDER = "uploads"
RESULT_FOLDER = "results"
DB_PATH = "database.sqlite"
PORT = 5555  # Unified service port

# Ensure folders exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULT_FOLDER, exist_ok=True)
os.makedirs("models", exist_ok=True)

# ============================================================================
# Database Initialization
# ============================================================================

def init_db():
    """Initialize SQLite database"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS swaps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_name TEXT NOT NULL,
            user_email TEXT NOT NULL,
            image_name TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()
    logger.info("Database initialized")

# ============================================================================
# Hand Detection Module
# ============================================================================

class HandDetector:
    def __init__(self):
        self.mp_hands = mp.solutions.hands
        self.mp_drawing = mp.solutions.drawing_utils
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.palm_detected = False
        self.last_detection_time = 0
        self.cooldown_period = 3.0  # seconds
        
    def is_palm_open(self, hand_landmarks):
        """Check if the detected hand is showing an open palm"""
        if not hand_landmarks:
            return False
            
        landmarks = hand_landmarks.landmark
        
        # Finger tip and base indices
        finger_tips = [
            self.mp_hands.HandLandmark.THUMB_TIP,
            self.mp_hands.HandLandmark.INDEX_FINGER_TIP,
            self.mp_hands.HandLandmark.MIDDLE_FINGER_TIP,
            self.mp_hands.HandLandmark.RING_FINGER_TIP,
            self.mp_hands.HandLandmark.PINKY_TIP
        ]
        
        finger_bases = [
            self.mp_hands.HandLandmark.THUMB_MCP,
            self.mp_hands.HandLandmark.INDEX_FINGER_MCP,
            self.mp_hands.HandLandmark.MIDDLE_FINGER_MCP,
            self.mp_hands.HandLandmark.RING_FINGER_MCP,
            self.mp_hands.HandLandmark.PINKY_MCP
        ]
        
        extended_fingers = 0
        
        # Check each finger (except thumb)
        for i in range(1, 5):
            tip_y = landmarks[finger_tips[i]].y
            base_y = landmarks[finger_bases[i]].y
            
            if tip_y < base_y:
                extended_fingers += 1
        
        # Check thumb
        thumb_tip_x = landmarks[finger_tips[0]].x
        thumb_base_x = landmarks[finger_bases[0]].x
        
        if abs(thumb_tip_x - thumb_base_x) > 0.1:
            extended_fingers += 1
        
        logger.info(f"Extended fingers count: {extended_fingers}")
        return extended_fingers >= 4
    
    def process_image(self, image_data):
        """Process a base64 encoded image and detect if palm is open"""
        try:
            # Decode base64 image
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            # Log image data size for debugging
            logger.info(f"Processing image, base64 length: {len(image_data)}")
            
            image_bytes = base64.b64decode(image_data)
            image = Image.open(BytesIO(image_bytes))
            
            # Convert to OpenCV format
            frame = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
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
                            remaining = self.cooldown_period - (current_time - self.last_detection_time)
                            return False, f"Cooldown active, wait {remaining:.1f}s"
                return False, "Hand detected but palm not open"
            
            return False, "No hand detected"
            
        except Exception as e:
            logger.error(f"Error processing image: {str(e)}")
            return False, f"Error: {str(e)}"
    
    def reset(self):
        """Reset the detection state"""
        self.palm_detected = False
        self.last_detection_time = 0

# ============================================================================
# Face Swapping Module (Lite - without GFPGAN)
# ============================================================================

class FaceSwapperLite:
    def __init__(self):
        self.face_app = None
        self.swapper = None
        self._initialize_models()
    
    def _download_model(self, url: str, path: str):
        """Download model if it doesn't exist"""
        if not os.path.exists(path):
            logger.info(f"Downloading model to {path}...")
            try:
                response = requests.get(url, stream=True)
                response.raise_for_status()
                
                with open(path, 'wb') as model_file:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            model_file.write(chunk)
                logger.info(f"Model downloaded successfully: {path}")
            except Exception as e:
                logger.error(f"Error downloading model: {e}")
                raise
    
    def _initialize_models(self):
        """Initialize all face swapping models"""
        try:
            # Initialize FaceAnalysis
            logger.info("Initializing FaceAnalysis...")
            self.face_app = FaceAnalysis(name='buffalo_l')
            self.face_app.prepare(ctx_id=0, det_size=(640, 640))
            
            # Download and load Face Swapper model
            swapper_path = 'models/inswapper_128.onnx'
            swapper_url = 'https://huggingface.co/ezioruan/inswapper_128.onnx/resolve/main/inswapper_128.onnx'
            self._download_model(swapper_url, swapper_path)
            self.swapper = insightface.model_zoo.get_model(swapper_path, download=False, download_zip=False)
            logger.info("Face Swapper model loaded successfully")
            
        except Exception as e:
            logger.error(f"Error initializing models: {e}")
            raise
    
    def single_face_swap(self, source_img, target_img):
        """Perform a single face swap"""
        logger.info("Starting single face swap...")
        faces_src = self.face_app.get(source_img)
        faces_tgt = self.face_app.get(target_img)
        
        logger.info(f"Faces detected - Source: {len(faces_src)}, Target: {len(faces_tgt)}")
        
        if not faces_src or not faces_tgt:
            logger.warning("No faces detected in one or both images")
            return None
        
        face_src = faces_src[0]
        face_tgt = faces_tgt[0]
        swapped_img = self.swapper.get(source_img, face_src, face_tgt, paste_back=True)
        logger.info("Single face swap completed")
        return swapped_img

# ============================================================================
# Global Instances
# ============================================================================

hand_detector = HandDetector()
face_swapper = None  # Will be initialized on first use to save memory
supabase_storage = SupabaseStorage()  # Initialize Supabase storage

def get_face_swapper():
    """Lazy initialization of face swapper"""
    global face_swapper
    if face_swapper is None:
        logger.info("Initializing face swapper on first use...")
        face_swapper = FaceSwapperLite()
    return face_swapper

# ============================================================================
# API Endpoints
# ============================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return JSONResponse({
        "status": "healthy",
        "service": "unified_photobooth_backend_lite",
        "features": ["hand_detection", "face_swapping"],
        "port": PORT,
        "version": "lite"
    })

@app.post("/detect_palm")
async def detect_palm(request: dict):
    """Detect if an open palm is present in the image"""
    try:
        if not request or 'image' not in request:
            return JSONResponse({
                "success": False,
                "error": "No image data provided"
            }, status_code=400)
        
        image_data = request['image']
        palm_detected, message = hand_detector.process_image(image_data)
        
        return JSONResponse({
            "success": True,
            "palm_detected": palm_detected,
            "message": message,
            "timestamp": time.time()
        })
        
    except Exception as e:
        logger.error(f"Error in detect_palm: {str(e)}")
        return JSONResponse({
            "success": False,
            "error": str(e)
        }, status_code=500)

@app.post("/reset")
async def reset_detector():
    """Reset the hand detector state"""
    hand_detector.reset()
    return JSONResponse({"success": True, "message": "Detector reset"})

@app.get("/image/{image_id}")
async def get_image(image_id: str):
    """Serve image by ID"""
    if not hasattr(app.state, 'image_cache'):
        raise HTTPException(status_code=404, detail="Image not found")
    
    image_path = app.state.image_cache.get(image_id)
    if not image_path or not os.path.exists(image_path):
        raise HTTPException(status_code=404, detail="Image not found")
    
    return FileResponse(image_path, media_type="image/jpeg")

@app.post("/api/process-photo")
async def process_photo(data: dict):
    """Process captured photo from Flutter app with face swapping"""
    try:
        if not data:
            return JSONResponse({
                "success": False,
                "error": "No data provided"
            }, status_code=400)
        
        # Extract data - now expecting both source and target images
        source_image = data.get('source_image') or data.get('captured_image')  # Base64 encoded
        target_image = data.get('target_image')  # Base64 encoded character image
        transformation_type = data.get('transformation_type')
        user_gender = data.get('gender', 'male')
        user_name = data.get('name', 'Guest')
        user_email = data.get('email', 'guest@example.com')
        
        logger.info(f"Received request with transformation_type: {transformation_type}")
        logger.info(f"Has source_image: {bool(source_image)}, Has target_image: {bool(target_image)}")
        
        if not source_image:
            return JSONResponse({
                "success": False,
                "error": "No source image provided"
            }, status_code=400)
        
        # Decode source image
        if ',' in source_image:
            source_image = source_image.split(',')[1]
        
        source_bytes = base64.b64decode(source_image)
        
        # Upload original image to Supabase (optional)
        original_url = None
        if supabase_storage.client:
            original_url = supabase_storage.upload_image_bytes(source_bytes, folder="originals")
        
        # Save source image locally
        source_path = os.path.join(UPLOAD_FOLDER, f"source_{uuid.uuid4()}.jpg")
        with open(source_path, 'wb') as f:
            f.write(source_bytes)
        
        # Process based on transformation type
        result_url = None
        result_path = source_path  # Default to original if no transformation
        
        # Check if we have both images for face swapping
        # Any transformation type with a target image should trigger face swap
        if target_image:
            logger.info("Processing face swap with provided target image")
            
            # Decode target image
            if ',' in target_image:
                target_image = target_image.split(',')[1]
            
            target_bytes = base64.b64decode(target_image)
            
            if target_bytes:
                # Save target image temporarily (as PNG since character images are PNG)
                target_path = os.path.join(UPLOAD_FOLDER, f"target_{uuid.uuid4()}.png")
                with open(target_path, 'wb') as f:
                    f.write(target_bytes)
                logger.info(f"Saved target image: {len(target_bytes)} bytes")
                
                # Load images for face swapping
                source_img = cv2.imread(source_path)
                target_img = cv2.imread(target_path)
                
                if source_img is not None and target_img is not None:
                    logger.info(f"Source image shape: {source_img.shape}, Target image shape: {target_img.shape}")
                    
                    # Get face swapper instance
                    swapper = get_face_swapper()
                    
                    # Perform face swap (swap source face onto target character)
                    swapped_img = swapper.single_face_swap(source_img, target_img)
                    
                    if swapped_img is not None:
                        logger.info("Face swap successful")
                        # Save swapped image
                        result_filename = f"result_{uuid.uuid4()}.jpg"
                        result_path = os.path.join(RESULT_FOLDER, result_filename)
                        cv2.imwrite(result_path, swapped_img)
                        
                        # Upload transformed image to Supabase (if available)
                        if supabase_storage.client:
                            result_url = supabase_storage.upload_image(result_path, folder="outputs")
                            
                            # Save transformation record
                            supabase_storage.save_transformation_record(
                                user_name=user_name,
                                user_email=user_email,
                                original_url=original_url or "",
                                transformed_url=result_url or "",
                                transformation_type=transformation_type
                            )
                    else:
                        logger.warning("Face swap failed - no faces detected or swap unsuccessful")
                        # Still return the original image
                        result_path = source_path
                    
                    # Clean up temporary file
                    try:
                        os.remove(target_path)
                    except:
                        pass
                else:
                    logger.error(f"Failed to load images - Source: {source_img is not None}, Target: {target_img is not None}")
                    result_path = source_path
            else:
                logger.warning("No target image provided for face swap")
        
        # If no Supabase URL, create a local URL
        if not result_url:
            # Save the result with a unique ID that can be accessed via GET
            result_id = str(uuid.uuid4())
            result_filename = os.path.basename(result_path)
            # Store the path for later retrieval
            if not hasattr(app.state, 'image_cache'):
                app.state.image_cache = {}
            app.state.image_cache[result_id] = result_path
            # Create a URL that can be used to retrieve the image
            result_url = f"http://localhost:{PORT}/image/{result_id}"
        
        # Save to local database as backup
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO swaps (user_name, user_email, image_name)
            VALUES (?, ?, ?)
            """,
            (user_name, user_email, os.path.basename(result_path))
        )
        conn.commit()
        conn.close()
        
        # Return response with image URL
        return JSONResponse({
            "success": True,
            "image_url": result_url,
            "original_url": original_url,
            "transformation_type": transformation_type,
            "message": "Image processed successfully"
        })
            
    except Exception as e:
        logger.error(f"Error processing photo: {e}")
        return JSONResponse({
            "success": False,
            "error": str(e)
        }, status_code=500)

# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    # Initialize database
    init_db()
    
    # Start server
    logger.info(f"Starting Unified Photobooth Backend (Lite) on port {PORT}...")
    logger.info("Available endpoints:")
    logger.info(f"  - GET  http://localhost:{PORT}/health - Health check")
    logger.info(f"  - POST http://localhost:{PORT}/detect_palm - Palm detection")
    logger.info(f"  - POST http://localhost:{PORT}/reset - Reset detector")
    logger.info(f"  - POST http://localhost:{PORT}/api/process-photo - Process captured photo")
    
    uvicorn.run(app, host="0.0.0.0", port=PORT, reload=False)