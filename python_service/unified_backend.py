#!/usr/bin/env python3
"""
Unified Backend Service for Dell Photobooth
Combines hand detection and face swapping functionality
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
from gfpgan import GFPGANer
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
# Face Swapping Module
# ============================================================================

class FaceSwapper:
    def __init__(self):
        self.face_app = None
        self.swapper = None
        self.gfpganer = None
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
            
            # Download and load GFPGAN model
            gfpgan_path = 'models/GFPGANv1.4.pth'
            gfpgan_url = 'https://huggingface.co/gmk123/GFPGAN/resolve/main/GFPGANv1.4.pth'
            self._download_model(gfpgan_url, gfpgan_path)
            
            self.gfpganer = GFPGANer(
                model_path=gfpgan_path,
                upscale=1,
                arch='clean',
                channel_multiplier=2
            )
            logger.info("GFPGAN model loaded successfully")
            
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
    
    def enhance_face(self, image):
        """Enhance a face using GFPGAN"""
        logger.info("Starting face enhancement...")
        _, _, restored_img = self.gfpganer.enhance(
            image, 
            has_aligned=False, 
            only_center_face=False, 
            paste_back=True
        )
        
        if isinstance(restored_img, np.ndarray):
            logger.info("Face enhancement completed")
            return restored_img
        else:
            raise Exception("Face enhancement failed")

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
        face_swapper = FaceSwapper()
    return face_swapper

# ============================================================================
# API Endpoints
# ============================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return JSONResponse({
        "status": "healthy",
        "service": "unified_photobooth_backend",
        "features": ["hand_detection", "face_swapping"],
        "port": PORT
    })

@app.post("/detect_palm")
async def detect_palm():
    """Detect if an open palm is present in the image"""
    try:
        from fastapi import Request
        request = Request.__new__(Request)
        data = await request.json()
        
        if not data or 'image' not in data:
            return JSONResponse({
                "success": False,
                "error": "No image data provided"
            }, status_code=400)
        
        image_data = data['image']
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

@app.post("/api/swap-face/")
async def swap_faces(
    sourceImage: UploadFile = File(...),
    targetImage: UploadFile = File(...),
    name: str = Form(...),
    email: str = Form(...)
):
    """API endpoint for face swapping"""
    try:
        if not name or not email:
            raise HTTPException(status_code=400, detail="Name and email are required")
        
        logger.info(f"Processing face swap for {name} ({email})")
        
        # Save uploaded files
        src_path = os.path.join(UPLOAD_FOLDER, f"source_{uuid.uuid4()}.jpg")
        tgt_path = os.path.join(UPLOAD_FOLDER, f"target_{uuid.uuid4()}.jpg")
        
        with open(src_path, "wb") as buffer:
            shutil.copyfileobj(sourceImage.file, buffer)
        with open(tgt_path, "wb") as buffer:
            shutil.copyfileobj(targetImage.file, buffer)
        
        # Load images
        source_img = cv2.imread(src_path)
        target_img = cv2.imread(tgt_path)
        
        if source_img is None or target_img is None:
            raise HTTPException(status_code=400, detail="Failed to load images")
        
        # Get face swapper instance
        swapper = get_face_swapper()
        
        # Perform face swap
        swapped_img = swapper.single_face_swap(source_img, target_img)
        
        if swapped_img is None:
            raise HTTPException(status_code=400, detail="Face swap failed - no faces detected")
        
        # Enhance the swapped image
        enhanced_img = swapper.enhance_face(swapped_img)
        
        # Save the result
        result_filename = f"result_{uuid.uuid4()}.jpg"
        result_path = os.path.join(RESULT_FOLDER, result_filename)
        cv2.imwrite(result_path, enhanced_img)
        
        # Save to database
        try:
            conn = sqlite3.connect(DB_PATH)
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO swaps (user_name, user_email, image_name)
                VALUES (?, ?, ?)
                """,
                (name, email, result_filename)
            )
            conn.commit()
            conn.close()
            logger.info(f"Saved to database: {name}, {email}, {result_filename}")
        except sqlite3.Error as db_error:
            logger.error(f"Database error: {db_error}")
            raise HTTPException(status_code=500, detail="Failed to save to database")
        
        return FileResponse(result_path)
        
    except Exception as e:
        logger.error(f"Error during face swap: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/process-photo")
async def process_photo():
    """Process captured photo from Flutter app and upload to Supabase"""
    try:
        from fastapi import Request
        request = Request.__new__(Request)
        data = await request.json()
        
        if not data:
            return JSONResponse({
                "success": False,
                "error": "No data provided"
            }, status_code=400)
        
        # Extract data
        captured_image = data.get('captured_image')  # Base64 encoded
        transformation_type = data.get('transformation_type')
        selected_character = data.get('selected_character')
        user_gender = data.get('gender', 'male')  # Get user gender
        user_name = data.get('name', 'Guest')
        user_email = data.get('email', 'guest@example.com')
        
        if not captured_image:
            return JSONResponse({
                "success": False,
                "error": "No captured image provided"
            }, status_code=400)
        
        # Decode captured image
        if ',' in captured_image:
            captured_image = captured_image.split(',')[1]
        
        image_bytes = base64.b64decode(captured_image)
        
        # Upload original image to Supabase
        original_url = None
        if supabase_storage.client:
            original_url = supabase_storage.upload_image_bytes(image_bytes, folder="originals")
        
        # Save locally for processing
        captured_path = os.path.join(UPLOAD_FOLDER, f"captured_{uuid.uuid4()}.jpg")
        with open(captured_path, 'wb') as f:
            f.write(image_bytes)
        
        # Process based on transformation type
        result_url = None
        result_path = captured_path  # Default to original if no transformation
        
        if transformation_type == "AI Transformation":
            # Get random character image from Supabase
            logger.info(f"Fetching random character image for gender: {user_gender}")
            character_image_bytes = None
            
            if supabase_storage.client:
                character_image_bytes = supabase_storage.get_random_character_image(user_gender)
            
            if character_image_bytes:
                # Save character image temporarily
                character_path = os.path.join(UPLOAD_FOLDER, f"character_{uuid.uuid4()}.jpg")
                with open(character_path, 'wb') as f:
                    f.write(character_image_bytes)
                
                # Load images
                source_img = cv2.imread(captured_path)
                target_img = cv2.imread(character_path)
                
                if source_img is not None and target_img is not None:
                    # Get face swapper instance
                    swapper = get_face_swapper()
                    
                    # Perform face swap
                    swapped_img = swapper.single_face_swap(source_img, target_img)
                    
                    if swapped_img is not None:
                        # Enhance and save
                        enhanced_img = swapper.enhance_face(swapped_img)
                        result_filename = f"result_{uuid.uuid4()}.jpg"
                        result_path = os.path.join(RESULT_FOLDER, result_filename)
                        cv2.imwrite(result_path, enhanced_img)
                        
                        # Upload transformed image to Supabase
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
                    
                    # Clean up temporary file
                    os.remove(character_path)
                else:
                    logger.error("Failed to load source or character image")
            else:
                logger.warning("No character image available from Supabase, using original image")
        
        # If no Supabase URL, read the file for base64 response
        if not result_url:
            with open(result_path, 'rb') as f:
                result_bytes = f.read()
            result_base64 = base64.b64encode(result_bytes).decode('utf-8')
            result_url = f"data:image/jpeg;base64,{result_base64}"
        
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
    logger.info(f"Starting Unified Photobooth Backend on port {PORT}...")
    logger.info("Available endpoints:")
    logger.info(f"  - GET  http://localhost:{PORT}/health - Health check")
    logger.info(f"  - POST http://localhost:{PORT}/detect_palm - Palm detection")
    logger.info(f"  - POST http://localhost:{PORT}/reset - Reset detector")
    logger.info(f"  - POST http://localhost:{PORT}/api/swap-face/ - Face swapping")
    logger.info(f"  - POST http://localhost:{PORT}/api/process-photo - Process captured photo")
    
    uvicorn.run(app, host="0.0.0.0", port=PORT, reload=False)