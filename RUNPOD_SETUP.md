# Runpod Integration Setup Guide

## Overview
This photobooth app is integrated with Runpod for AI-powered face swapping using ComfyUI workflows. The app captures user photos, uploads them to Supabase, and processes them through a Runpod workflow to generate transformed images.

## Setup Steps

### 1. Configure API Keys
The API keys are loaded from the `.env` file in the project root:

```env
RUNPOD_API_KEY=your_runpod_api_key_here
RUNPOD_SWAPLAB_URL=your_runpod_endpoint_url_here
```

The app automatically loads these values via `flutter_dotenv` package.

### 2. Supabase Configuration
The app uses the following Supabase structure:
- **Bucket**: `outputimages` - Stores user captured images
- **Bucket**: `themes` - Stores character images for face swapping
- **Table**: `event_output_images` - Tracks image processing status

Table schema for `event_output_images`:
```sql
CREATE TABLE event_output_images (
  unique_id TEXT PRIMARY KEY,
  name TEXT,
  email TEXT,
  gender TEXT,
  image_url TEXT,
  characterimage TEXT,
  output TEXT,
  created_at TIMESTAMP
);
```

### 3. Runpod Workflow
The workflow JSON (`lib/workflow/swaplabonline.json`) contains:
- Node 44: Supabase Table Watcher (monitors for new images)
- Node 45: Character Image Fetcher
- Node 1: ReActor Face Swap
- Node 43: Upload processed image back to Supabase

### 4. Character Images Structure
In Supabase storage (`themes` bucket), the images are organized as follows:

**6 Themes available:**
- `cyberpunk_future`
- `extreme_sports`
- `fantasy_kingdom`
- `futuristic_workspace`
- `space_explorer`
- `sustainability_champions`

**Structure:**
```
themes/
├── male/
│   ├── cyberpunk_future/
│   │   ├── Male 01.png
│   │   ├── Male 02.png
│   │   └── ... (up to Male 07.png)
│   ├── space_explorer/
│   │   └── ... (Male 01.png to Male 07.png)
│   └── ... (all 6 themes)
└── female/
    ├── cyberpunk_future/
    │   ├── Female 01.png
    │   ├── Female 02.png
    │   └── ... (up to Female 07.png)
    └── ... (all 6 themes)
```

Each theme contains 7 images for both male and female categories.

## Process Flow

1. **User Capture**: User takes a photo in the app
2. **Upload to Supabase**: Image is uploaded to `outputimages` bucket
3. **Store Details**: User details and image URL stored in `event_output_images` table
4. **Update Workflow**: 
   - Generate unique UUID
   - Update workflow with UUID and random seed
   - Select random character image based on gender/theme
5. **Send to Runpod**: Workflow sent to Runpod for processing
6. **Poll for Result**: App polls the `output` column for processed image
7. **Display Result**: Processed image shown to user

## Key Files

- `lib/screens/face_capture_screen.dart` - Main capture and processing logic
- `lib/services/runpod_service.dart` - Runpod API integration
- `lib/services/supabase_service.dart` - Supabase operations
- `lib/workflow/workflow.dart` - Workflow JSON manipulation
- `lib/workflow/swaplabonline.json` - ComfyUI workflow definition

## Testing

1. Run `flutter pub get` to install dependencies
2. Update API keys in `app_config.dart`
3. Ensure Supabase buckets and table are created
4. Upload character images to Supabase
5. Test with: `flutter run -d chrome` (for web) or appropriate device

## Troubleshooting

- **Image not uploading**: Check Supabase bucket permissions
- **Workflow not triggering**: Verify Runpod API key and endpoint URL
- **No output image**: Check Runpod logs and ensure workflow nodes are configured correctly
- **Polling timeout**: Increase `maxAttempts` in `_processWithRunpod()` method

## Current Configuration
The `.env` file already contains:
- `RUNPOD_API_KEY`: Your Runpod API key
- `RUNPOD_SWAPLAB_URL`: The Runpod endpoint URL for the swaplab workflow

These are automatically loaded when the app starts using the `flutter_dotenv` package.