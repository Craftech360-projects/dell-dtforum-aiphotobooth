"""
Supabase Configuration and Helper Functions
"""

import os
from typing import Optional, Tuple
from supabase import create_client, Client
import logging
from datetime import datetime
import uuid

logger = logging.getLogger(__name__)

class SupabaseStorage:
    def __init__(self):
        """Initialize Supabase client with environment variables"""
        self.supabase_url = os.environ.get('SUPABASE_URL', '')
        self.supabase_key = os.environ.get('SUPABASE_ANON_KEY', '')
        self.bucket_name = os.environ.get('SUPABASE_BUCKET', 'photobooth-images')
        
        if not self.supabase_url or not self.supabase_key:
            logger.warning("Supabase credentials not found in environment variables")
            logger.info("Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables")
            self.client = None
        else:
            try:
                # Create client without proxy parameter for compatibility
                self.client: Client = create_client(self.supabase_url, self.supabase_key)
                logger.info("Supabase client initialized successfully")
                self._ensure_bucket_exists()
            except TypeError as e:
                # Try without any extra parameters if proxy is not supported
                try:
                    from supabase import Client as SupabaseClient
                    self.client = SupabaseClient(self.supabase_url, self.supabase_key)
                    logger.info("Supabase client initialized (fallback method)")
                    self._ensure_bucket_exists()
                except Exception as e2:
                    logger.error(f"Failed to initialize Supabase client: {e2}")
                    self.client = None
            except Exception as e:
                logger.error(f"Failed to initialize Supabase client: {e}")
                self.client = None
    
    def _ensure_bucket_exists(self):
        """Ensure the storage bucket exists"""
        try:
            # Try to get bucket info
            buckets = self.client.storage.list_buckets()
            bucket_exists = any(b['name'] == self.bucket_name for b in buckets)
            
            if not bucket_exists:
                # Create bucket if it doesn't exist
                self.client.storage.create_bucket(
                    self.bucket_name,
                    options={
                        'public': True,  # Make bucket public for easy access
                        'file_size_limit': 10485760  # 10MB limit
                    }
                )
                logger.info(f"Created storage bucket: {self.bucket_name}")
            else:
                logger.info(f"Storage bucket exists: {self.bucket_name}")
        except Exception as e:
            logger.error(f"Error checking/creating bucket: {e}")
    
    def upload_image(self, file_path: str, folder: str = "outputs") -> Optional[str]:
        """
        Upload image to Supabase storage and return public URL
        
        Args:
            file_path: Path to the image file
            folder: Folder name in the bucket (outputs, originals, etc.)
            
        Returns:
            Public URL of the uploaded image or None if failed
        """
        if not self.client:
            logger.error("Supabase client not initialized")
            return None
        
        try:
            # Generate unique filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            unique_id = str(uuid.uuid4())[:8]
            file_extension = os.path.splitext(file_path)[1]
            file_name = f"{folder}/{timestamp}_{unique_id}{file_extension}"
            
            # Read file
            with open(file_path, 'rb') as f:
                file_data = f.read()
            
            # Upload to Supabase
            response = self.client.storage.from_(self.bucket_name).upload(
                path=file_name,
                file=file_data,
                file_options={"content-type": "image/jpeg"}
            )
            
            # Get public URL
            public_url = self.client.storage.from_(self.bucket_name).get_public_url(file_name)
            
            logger.info(f"Image uploaded successfully: {public_url}")
            return public_url
            
        except Exception as e:
            logger.error(f"Failed to upload image to Supabase: {e}")
            return None
    
    def upload_image_bytes(self, image_bytes: bytes, folder: str = "outputs") -> Optional[str]:
        """
        Upload image bytes directly to Supabase storage
        
        Args:
            image_bytes: Image data as bytes
            folder: Folder name in the bucket
            
        Returns:
            Public URL of the uploaded image or None if failed
        """
        if not self.client:
            logger.error("Supabase client not initialized")
            return None
        
        try:
            # Generate unique filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            unique_id = str(uuid.uuid4())[:8]
            file_name = f"{folder}/{timestamp}_{unique_id}.jpg"
            
            # Upload to Supabase
            response = self.client.storage.from_(self.bucket_name).upload(
                path=file_name,
                file=image_bytes,
                file_options={"content-type": "image/jpeg"}
            )
            
            # Get public URL
            public_url = self.client.storage.from_(self.bucket_name).get_public_url(file_name)
            
            logger.info(f"Image uploaded successfully: {public_url}")
            return public_url
            
        except Exception as e:
            logger.error(f"Failed to upload image bytes to Supabase: {e}")
            return None
    
    def save_transformation_record(self, user_name: str, user_email: str, 
                                  original_url: str, transformed_url: str,
                                  transformation_type: str) -> bool:
        """
        Save transformation record to Supabase database
        
        Args:
            user_name: User's name
            user_email: User's email
            original_url: URL of original image
            transformed_url: URL of transformed image
            transformation_type: Type of transformation applied
            
        Returns:
            True if successful, False otherwise
        """
        if not self.client:
            logger.error("Supabase client not initialized")
            return False
        
        try:
            data = {
                'user_name': user_name,
                'user_email': user_email,
                'original_image_url': original_url,
                'transformed_image_url': transformed_url,
                'transformation_type': transformation_type,
                'created_at': datetime.now().isoformat()
            }
            
            response = self.client.table('photobooth_transformations').insert(data).execute()
            logger.info(f"Transformation record saved for {user_email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to save transformation record: {e}")
            return False
    
    def get_image_url(self, file_path: str) -> str:
        """
        Get public URL for a file in the bucket
        
        Args:
            file_path: Path to file in bucket
            
        Returns:
            Public URL
        """
        if not self.client:
            return ""
        
        return self.client.storage.from_(self.bucket_name).get_public_url(file_path)
    
    def download_image(self, file_path: str) -> Optional[bytes]:
        """
        Download an image from Supabase storage
        
        Args:
            file_path: Path to file in bucket
            
        Returns:
            Image bytes or None if failed
        """
        if not self.client:
            logger.error("Supabase client not initialized")
            return None
        
        try:
            # Download from Supabase
            response = self.client.storage.from_(self.bucket_name).download(file_path)
            logger.info(f"Image downloaded successfully: {file_path}")
            return response
            
        except Exception as e:
            logger.error(f"Failed to download image from Supabase: {e}")
            return None
    
    def list_files(self, folder_path: str) -> list:
        """
        List files in a specific folder
        
        Args:
            folder_path: Path to folder in bucket
            
        Returns:
            List of file names
        """
        if not self.client:
            logger.error("Supabase client not initialized")
            return []
        
        try:
            # List files in folder
            files = self.client.storage.from_(self.bucket_name).list(folder_path)
            return [f['name'] for f in files if 'name' in f]
            
        except Exception as e:
            logger.error(f"Failed to list files in {folder_path}: {e}")
            return []
    
    def get_random_character_image(self, gender: str = "male") -> Optional[bytes]:
        """
        Get a random character image from Supabase themes folder
        
        Args:
            gender: "male" or "female"
            
        Returns:
            Image bytes or None if failed
        """
        import random
        
        if not self.client:
            logger.error("Supabase client not initialized")
            return None
        
        try:
            # Available theme folders
            themes = [
                "sustainability_champions",
                "space_explorer", 
                "cyberpunk_future",
                "futuristic_workspace",
                "extreme_sports",
                "fantasy_kingdom"
            ]
            
            # Pick random theme
            random_theme = random.choice(themes)
            
            # Construct folder path
            folder_path = f"themes/{gender.lower()}/{random_theme}"
            
            # List files in the folder
            files = self.list_files(folder_path)
            
            # Filter for image files
            image_files = [f for f in files if f.endswith(('.png', '.jpg', '.jpeg'))]
            
            if not image_files:
                logger.warning(f"No images found in {folder_path}")
                # Try another theme
                themes.remove(random_theme)
                if themes:
                    random_theme = random.choice(themes)
                    folder_path = f"themes/{gender.lower()}/{random_theme}"
                    files = self.list_files(folder_path)
                    image_files = [f for f in files if f.endswith(('.png', '.jpg', '.jpeg'))]
            
            if image_files:
                # Pick random image
                random_image = random.choice(image_files)
                file_path = f"{folder_path}/{random_image}"
                
                logger.info(f"Selected character image: {file_path}")
                
                # Download the image
                return self.download_image(file_path)
            else:
                logger.error(f"No character images found for {gender}")
                return None
                
        except Exception as e:
            logger.error(f"Failed to get random character image: {e}")
            return None