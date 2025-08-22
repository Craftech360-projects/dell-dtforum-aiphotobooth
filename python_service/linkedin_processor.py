#!/usr/bin/env python3
"""
LinkedIn Professional Headshot Processor
Provides background removal, face detection, smart cropping, and image enhancements
"""

import cv2
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter, ImageOps
from rembg import remove
import io
import base64
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LinkedInProcessor:
    def __init__(self):
        # Initialize face detector
        self.face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        )
        
        # LinkedIn recommended dimensions
        self.output_size = (800, 800)  # 1:1 ratio
        
        # Professional background colors (can be customized)
        self.background_colors = {
            'white': (255, 255, 255),
            'light_gray': (240, 240, 240),
            'linkedin_blue': (10, 102, 194),
            'gradient_gray': None,  # Will create gradient
            'gradient_blue': None,  # Will create gradient
        }
    
    def process_image(self, image_bytes, background_type='white', 
                     enhance_skin=False, auto_enhance=False):
        """
        Main processing pipeline for LinkedIn headshot
        
        Args:
            image_bytes: Input image as bytes
            background_type: Type of background to apply
            enhance_skin: Whether to apply skin smoothing
            auto_enhance: Whether to apply automatic enhancements
        
        Returns:
            Processed image as base64 string
        """
        try:
            # Convert bytes to PIL Image
            input_image = Image.open(io.BytesIO(image_bytes))
            
            logger.info(f"Processing image: {input_image.size}")
            
            # Step 1: Remove background
            logger.info("Removing background...")
            img_no_bg = self.remove_background(input_image)
            
            # Step 2: Just use the image as-is, no cropping or enhancements
            processed_img = img_no_bg
            
            # Step 3: Add white background
            logger.info(f"Adding {background_type} background...")
            final_img = self.add_background(processed_img, background_type)
            
            # Step 4: Final resize to LinkedIn dimensions
            final_img = final_img.resize(self.output_size, Image.Resampling.LANCZOS)
            
            # Convert to base64
            output_buffer = io.BytesIO()
            final_img.save(output_buffer, format='JPEG', quality=95, optimize=True)
            output_bytes = output_buffer.getvalue()
            
            logger.info("Processing complete!")
            return base64.b64encode(output_bytes).decode('utf-8')
            
        except Exception as e:
            logger.error(f"Error processing image: {str(e)}")
            raise
    
    def remove_background(self, image):
        """Remove background using rembg"""
        # Convert PIL to bytes for rembg
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG')
        img_bytes = img_buffer.getvalue()
        
        # Remove background
        output_bytes = remove(img_bytes)
        
        # Convert back to PIL Image
        return Image.open(io.BytesIO(output_bytes))
    
    def smart_crop_face(self, image):
        """Detect face and crop with appropriate padding"""
        # Convert to OpenCV format
        img_cv = cv2.cvtColor(np.array(image), cv2.COLOR_RGBA2RGB)
        gray = cv2.cvtColor(img_cv, cv2.COLOR_RGB2GRAY)
        
        # Detect faces
        faces = self.face_cascade.detectMultiScale(
            gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30)
        )
        
        if len(faces) == 0:
            logger.warning("No face detected, using center crop")
            return self.center_crop(image)
        
        # Get the largest face (assuming it's the main subject)
        face = max(faces, key=lambda f: f[2] * f[3])
        x, y, w, h = face
        
        # Calculate padding for professional headshot
        # Add 40% padding above head, 20% below chin, 30% on sides
        pad_top = int(h * 0.4)
        pad_bottom = int(h * 0.2)
        pad_sides = int(w * 0.3)
        
        # Calculate crop region
        crop_x1 = max(0, x - pad_sides)
        crop_y1 = max(0, y - pad_top)
        crop_x2 = min(image.width, x + w + pad_sides)
        crop_y2 = min(image.height, y + h + pad_bottom)
        
        # Make it square (LinkedIn prefers 1:1)
        crop_w = crop_x2 - crop_x1
        crop_h = crop_y2 - crop_y1
        
        if crop_w > crop_h:
            # Extend height
            diff = crop_w - crop_h
            crop_y1 = max(0, crop_y1 - diff // 2)
            crop_y2 = min(image.height, crop_y2 + diff // 2)
        else:
            # Extend width
            diff = crop_h - crop_w
            crop_x1 = max(0, crop_x1 - diff // 2)
            crop_x2 = min(image.width, crop_x2 + diff // 2)
        
        # Crop the image
        cropped = image.crop((crop_x1, crop_y1, crop_x2, crop_y2))
        
        return cropped
    
    def center_crop(self, image):
        """Fallback center crop if no face detected"""
        width, height = image.size
        size = min(width, height)
        
        left = (width - size) // 2
        top = (height - size) // 2
        right = left + size
        bottom = top + size
        
        return image.crop((left, top, right, bottom))
    
    def mild_smooth_skin(self, image):
        """Apply very mild skin smoothing filter"""
        # Convert to RGB if RGBA
        if image.mode == 'RGBA':
            # Store alpha channel
            alpha = image.split()[3]
            image = image.convert('RGB')
            has_alpha = True
        else:
            has_alpha = False
        
        # Apply bilateral filter with reduced parameters for milder effect
        img_array = np.array(image)
        
        # Use OpenCV's bilateral filter with milder settings
        # Reduced d (diameter) from 9 to 5
        # Reduced sigmaColor from 75 to 30 (less aggressive color filtering)
        # Reduced sigmaSpace from 75 to 30 (less aggressive spatial filtering)
        smoothed = cv2.bilateralFilter(img_array, 5, 30, 30)
        
        # Blend with original for very subtle effect (85% original, 15% smoothed)
        blended = cv2.addWeighted(img_array, 0.85, smoothed, 0.15, 0)
        
        # Convert back to PIL
        result = Image.fromarray(blended)
        
        # Restore alpha channel if it existed
        if has_alpha:
            result.putalpha(alpha)
        
        return result
    
    def subtle_enhance_image(self, image):
        """Apply very subtle image enhancements"""
        # Convert to RGB for processing if needed
        if image.mode == 'RGBA':
            alpha = image.split()[3]
            image = image.convert('RGB')
            has_alpha = True
        else:
            has_alpha = False
        
        # Very mild auto contrast (increased cutoff for less aggressive adjustment)
        image = ImageOps.autocontrast(image, cutoff=5)
        
        # Very slight brightness increase (reduced from 1.1 to 1.03)
        enhancer = ImageEnhance.Brightness(image)
        image = enhancer.enhance(1.03)  # Only 3% brighter
        
        # Very subtle color enhancement (reduced from 1.05 to 1.02)
        enhancer = ImageEnhance.Color(image)
        image = enhancer.enhance(1.02)  # Only 2% more vibrant
        
        # Minimal sharpening (reduced from 1.2 to 1.05)
        enhancer = ImageEnhance.Sharpness(image)
        image = enhancer.enhance(1.05)  # Only 5% sharper
        
        # Restore alpha if needed
        if has_alpha:
            image.putalpha(alpha)
        
        return image
    
    def enhance_image(self, image):
        """Apply automatic image enhancements (kept for backward compatibility)"""
        # Convert to RGB for processing if needed
        if image.mode == 'RGBA':
            alpha = image.split()[3]
            image = image.convert('RGB')
            has_alpha = True
        else:
            has_alpha = False
        
        # Auto contrast
        image = ImageOps.autocontrast(image, cutoff=2)
        
        # Slight brightness increase
        enhancer = ImageEnhance.Brightness(image)
        image = enhancer.enhance(1.1)  # 10% brighter
        
        # Slight color enhancement
        enhancer = ImageEnhance.Color(image)
        image = enhancer.enhance(1.05)  # 5% more vibrant
        
        # Subtle sharpening
        enhancer = ImageEnhance.Sharpness(image)
        image = enhancer.enhance(1.2)  # 20% sharper
        
        # Restore alpha if needed
        if has_alpha:
            image.putalpha(alpha)
        
        return image
    
    def add_background(self, image, background_type):
        """Add professional background to the image"""
        # Ensure image has alpha channel
        if image.mode != 'RGBA':
            image = image.convert('RGBA')
        
        # Create background
        if background_type == 'gradient_gray':
            background = self.create_gradient(
                self.output_size, 
                (250, 250, 250), 
                (220, 220, 220)
            )
        elif background_type == 'gradient_blue':
            background = self.create_gradient(
                self.output_size,
                (240, 245, 255),  # Light blue
                (200, 220, 240)   # Darker blue
            )
        elif background_type in self.background_colors:
            color = self.background_colors[background_type]
            background = Image.new('RGB', self.output_size, color)
        else:
            # Default to white
            background = Image.new('RGB', self.output_size, (255, 255, 255))
        
        # Resize image to fit background
        image.thumbnail(self.output_size, Image.Resampling.LANCZOS)
        
        # Center the image on background
        x_offset = (self.output_size[0] - image.width) // 2
        y_offset = (self.output_size[1] - image.height) // 2
        
        # Composite the images
        background.paste(image, (x_offset, y_offset), image)
        
        return background
    
    def create_gradient(self, size, color1, color2):
        """Create a vertical gradient background"""
        width, height = size
        gradient = Image.new('RGB', (width, height))
        
        # Create gradient array
        for y in range(height):
            # Calculate color for this row
            ratio = y / height
            r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
            g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
            b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
            
            # Draw horizontal line
            for x in range(width):
                gradient.putpixel((x, y), (r, g, b))
        
        return gradient
    
    def process_quick_enhance(self, image_bytes):
        """Quick enhancement without background removal (for already good photos)"""
        try:
            # Convert bytes to PIL Image
            input_image = Image.open(io.BytesIO(image_bytes))
            
            # Apply enhancements
            enhanced = self.enhance_image(input_image)
            
            # Resize to LinkedIn dimensions
            final_img = enhanced.resize(self.output_size, Image.Resampling.LANCZOS)
            
            # Convert to base64
            output_buffer = io.BytesIO()
            final_img.save(output_buffer, format='JPEG', quality=95)
            output_bytes = output_buffer.getvalue()
            
            return base64.b64encode(output_bytes).decode('utf-8')
            
        except Exception as e:
            logger.error(f"Error in quick enhance: {str(e)}")
            raise