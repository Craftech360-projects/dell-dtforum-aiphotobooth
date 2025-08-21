#!/usr/bin/env python3
"""
Test script for Supabase integration
Tests character image fetching from themes folder
"""

import os
import sys
from supabase_config import SupabaseStorage
import cv2
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_supabase_connection():
    """Test basic Supabase connection"""
    storage = SupabaseStorage()
    
    if storage.client:
        print("✅ Supabase client initialized successfully")
        return storage
    else:
        print("❌ Failed to initialize Supabase client")
        print("Make sure to set environment variables:")
        print("  export SUPABASE_URL='your-url'")
        print("  export SUPABASE_ANON_KEY='your-key'")
        return None

def test_list_themes(storage: SupabaseStorage):
    """Test listing theme folders"""
    print("\n📁 Testing theme folder listing...")
    
    for gender in ['male', 'female']:
        print(f"\nThemes for {gender}:")
        themes_path = f"themes/{gender}"
        
        try:
            # List folders in themes/gender
            folders = storage.client.storage.from_(storage.bucket_name).list(themes_path)
            for folder in folders:
                if 'name' in folder:
                    print(f"  - {folder['name']}")
                    
                    # List files in each theme folder
                    theme_path = f"{themes_path}/{folder['name']}"
                    files = storage.list_files(theme_path)
                    image_count = len([f for f in files if f.endswith(('.png', '.jpg', '.jpeg'))])
                    print(f"    ({image_count} images)")
        except Exception as e:
            print(f"  ❌ Error: {e}")

def test_random_character(storage: SupabaseStorage):
    """Test fetching random character images"""
    print("\n🎲 Testing random character image fetching...")
    
    for gender in ['male', 'female']:
        print(f"\nFetching random {gender} character...")
        
        # Get random character image
        image_bytes = storage.get_random_character_image(gender)
        
        if image_bytes:
            print(f"  ✅ Successfully fetched {gender} character image")
            print(f"  📏 Image size: {len(image_bytes)} bytes")
            
            # Save to test file
            test_file = f"test_{gender}_character.jpg"
            with open(test_file, 'wb') as f:
                f.write(image_bytes)
            
            # Load with OpenCV to verify
            img = cv2.imread(test_file)
            if img is not None:
                height, width = img.shape[:2]
                print(f"  📐 Image dimensions: {width}x{height}")
                os.remove(test_file)  # Clean up
            else:
                print(f"  ⚠️ Could not read image with OpenCV")
        else:
            print(f"  ❌ Failed to fetch {gender} character image")

def test_specific_theme(storage: SupabaseStorage, gender: str, theme: str):
    """Test fetching from a specific theme"""
    print(f"\n🎯 Testing specific theme: {theme} ({gender})")
    
    folder_path = f"themes/{gender}/{theme}"
    files = storage.list_files(folder_path)
    
    image_files = [f for f in files if f.endswith(('.png', '.jpg', '.jpeg'))]
    print(f"  Found {len(image_files)} images:")
    for img_file in image_files[:5]:  # Show first 5
        print(f"    - {img_file}")
    
    if image_files:
        # Download first image as test
        test_file_path = f"{folder_path}/{image_files[0]}"
        image_bytes = storage.download_image(test_file_path)
        
        if image_bytes:
            print(f"  ✅ Successfully downloaded: {image_files[0]}")
        else:
            print(f"  ❌ Failed to download: {image_files[0]}")

def main():
    """Run all tests"""
    print("=" * 60)
    print("🧪 SUPABASE CHARACTER IMAGE TEST")
    print("=" * 60)
    
    # Test connection
    storage = test_supabase_connection()
    if not storage:
        sys.exit(1)
    
    # Test listing themes
    test_list_themes(storage)
    
    # Test random character fetching
    test_random_character(storage)
    
    # Test specific themes
    test_specific_theme(storage, "male", "cyberpunk_future")
    test_specific_theme(storage, "female", "extreme_sports")
    
    print("\n" + "=" * 60)
    print("✅ Tests completed!")
    print("=" * 60)

if __name__ == "__main__":
    main()