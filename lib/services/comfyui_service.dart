import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ComfyUIService {
  static Future<Map<String, dynamic>> sendLinkedInWorkflow({
    required String uniqueId,
    required String apiUrl,
    required String apiKey,
  }) async {
    try {
      // Load workflow JSON and replace the unique_id
      final workflow = await _getWorkflowWithUniqueId(uniqueId);

      // Debug: Print the workflow being sent
      debugPrint('🔧 ComfyUI Workflow being sent to RunPod:');
      debugPrint(jsonEncode(workflow));

      // Send workflow to ComfyUI RunPod endpoint
      // cft360/serverless handler.py expects workflow under input.workflow
      final payload = {
        'input': {'workflow': workflow},
      };

      // Debug: Print the full payload
      debugPrint('🚀 Full RunPod payload:');
      debugPrint(jsonEncode(payload));

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      // Ensure URL is properly formatted
      final cleanApiUrl = apiUrl.endsWith('/')
          ? apiUrl.substring(0, apiUrl.length - 1)
          : apiUrl;
      final runUrl = '$cleanApiUrl/run';

      debugPrint('📡 Sending to URL: $runUrl');

      final response = await http.post(
        Uri.parse(runUrl),
        headers: headers,
        body: jsonEncode(payload),
      );

      debugPrint('📨 Response status: ${response.statusCode}');
      debugPrint('📨 Response headers: ${response.headers}');

      // Accept both 200 and 201, and check for "IN_QUEUE" status
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Check if we got a job ID (RunPod returns id and status)
        if (responseData['id'] != null) {
          return {
            'status': 'success',
            'job_id': responseData['id'],
            'message': 'ComfyUI LinkedIn headshot job started successfully',
          };
        } else {
          // Got 200/201 but no job ID
          throw Exception('Invalid response from RunPod: ${response.body}');
        }
      } else {
        debugPrint('ComfyUI RunPod API error - Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception(
          'Failed to start ComfyUI job: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      debugPrint('Error in ComfyUI workflow request: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<bool> checkJobStatus({
    required String jobId,
    required String apiUrl,
    required String apiKey,
  }) async {
    try {
      final headers = {'Authorization': 'Bearer $apiKey'};

      // Ensure URL is properly formatted
      final cleanApiUrl = apiUrl.endsWith('/')
          ? apiUrl.substring(0, apiUrl.length - 1)
          : apiUrl;
      final statusUrl = '$cleanApiUrl/status/$jobId';

      final response = await http.get(Uri.parse(statusUrl), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'COMPLETED') {
          // ComfyUI workflow saves to Supabase via SupabaseImageUploader node
          return true;
        } else if (status == 'FAILED') {
          debugPrint('ComfyUI job failed: ${data['output']}');
          throw Exception('ComfyUI LinkedIn headshot job failed');
        }
      }

      return false; // Still processing
    } on Exception catch (e) {
      debugPrint('Error checking ComfyUI job status: $e');
      return false;
    }
  }

  /// Load workflow JSON and replace unique_id
  static Future<Map<String, dynamic>> _getWorkflowWithUniqueId(
    String uniqueId,
  ) async {
    // Read the workflow from linkedin.json - exact copy with proper formatting
    const workflowJson = '''
{
  "5": {
    "inputs": {
      "width": [
        "216",
        1
      ],
      "height": [
        "216",
        2
      ],
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage",
    "_meta": {
      "title": "Empty Latent Image"
    }
  },
  "6": {
    "inputs": {
      "text": [
        "270",
        0
      ],
      "clip": [
        "219",
        1
      ]
    },
    "class_type": "CLIPTextEncode",
    "_meta": {
      "title": "CLIP Text Encode (Prompt)"
    }
  },
  "13": {
    "inputs": {
      "noise": [
        "25",
        0
      ],
      "guider": [
        "22",
        0
      ],
      "sampler": [
        "16",
        0
      ],
      "sigmas": [
        "17",
        0
      ],
      "latent_image": [
        "5",
        0
      ]
    },
    "class_type": "SamplerCustomAdvanced",
    "_meta": {
      "title": "SamplerCustomAdvanced"
    }
  },
  "16": {
    "inputs": {
      "sampler_name": "euler"
    },
    "class_type": "KSamplerSelect",
    "_meta": {
      "title": "KSamplerSelect"
    }
  },
  "17": {
    "inputs": {
      "scheduler": "simple",
      "steps": 12,
      "denoise": 1,
      "model": [
        "61",
        0
      ]
    },
    "class_type": "BasicScheduler",
    "_meta": {
      "title": "BasicScheduler"
    }
  },
  "22": {
    "inputs": {
      "model": [
        "61",
        0
      ],
      "conditioning": [
        "60",
        0
      ]
    },
    "class_type": "BasicGuider",
    "_meta": {
      "title": "BasicGuider"
    }
  },
  "25": {
    "inputs": {
      "noise_seed": 130407868184706
    },
    "class_type": "RandomNoise",
    "_meta": {
      "title": "RandomNoise"
    }
  },
  "60": {
    "inputs": {
      "guidance": 3,
      "conditioning": [
        "6",
        0
      ]
    },
    "class_type": "FluxGuidance",
    "_meta": {
      "title": "FluxGuidance"
    }
  },
  "61": {
    "inputs": {
      "max_shift": 1.1500000000000001,
      "base_shift": 0.5000000000000001,
      "width": [
        "216",
        1
      ],
      "height": [
        "216",
        2
      ],
      "model": [
        "227",
        0
      ]
    },
    "class_type": "ModelSamplingFlux",
    "_meta": {
      "title": "ModelSamplingFlux"
    }
  },
  "147": {
    "inputs": {
      "samples": [
        "13",
        0
      ],
      "vae": [
        "228",
        2
      ]
    },
    "class_type": "VAEDecode",
    "_meta": {
      "title": "VAE Decode"
    }
  },
  "148": {
    "inputs": {
      "filename_prefix": "linkedin_headshot",
      "images": [
        "147",
        0
      ]
    },
    "class_type": "SaveImage",
    "_meta": {
      "title": "Save Image"
    }
  },
  "216": {
    "inputs": {
      "aspect_ratio": "2:3"
    },
    "class_type": "SDXLAspectRatioSelector",
    "_meta": {
      "title": "SDXL Aspect Ratio"
    }
  },
  "219": {
    "inputs": {
      "lora_name": "diffusion_pytorch_model.safetensors",
      "strength_model": 1.0000000000000002,
      "strength_clip": 1.0000000000000002,
      "model": [
        "257",
        0
      ],
      "clip": [
        "257",
        1
      ]
    },
    "class_type": "LoraLoader",
    "_meta": {
      "title": "Load LoRA"
    }
  },
  "223": {
    "inputs": {
      "pulid_file": "pulid_flux_v0.9.0.safetensors"
    },
    "class_type": "PulidFluxModelLoader",
    "_meta": {
      "title": "Load PuLID Flux Model"
    }
  },
  "224": {
    "inputs": {},
    "class_type": "PulidFluxEvaClipLoader",
    "_meta": {
      "title": "Load Eva Clip (PuLID Flux)"
    }
  },
  "225": {
    "inputs": {
      "provider": "CUDA"
    },
    "class_type": "PulidFluxInsightFaceLoader",
    "_meta": {
      "title": "Load InsightFace (PuLID Flux)"
    }
  },
  "227": {
    "inputs": {
      "weight": 0.8000000000000002,
      "start_at": 0,
      "end_at": 1,
      "model": [
        "219",
        0
      ],
      "pulid_flux": [
        "223",
        0
      ],
      "eva_clip": [
        "224",
        0
      ],
      "face_analysis": [
        "225",
        0
      ],
      "image": [
        "283",
        0
      ]
    },
    "class_type": "ApplyPulidFlux",
    "_meta": {
      "title": "Apply PuLID Flux"
    }
  },
  "228": {
    "inputs": {
      "ckpt_name": "flux1-dev-fp8.safetensors"
    },
    "class_type": "CheckpointLoaderSimple",
    "_meta": {
      "title": "Load Checkpoint"
    }
  },
  "237": {
    "inputs": {
      "text_input": "head",
      "task": "caption_to_phrase_grounding",
      "fill_mask": true,
      "keep_model_loaded": false,
      "max_new_tokens": 1024,
      "num_beams": 3,
      "do_sample": true,
      "output_mask_select": "",
      "seed": 642426227619723,
      "image": [
        "256",
        0
      ],
      "florence2_model": [
        "282",
        0
      ]
    },
    "class_type": "Florence2Run",
    "_meta": {
      "title": "Florence2Run"
    }
  },
  "256": {
    "inputs": {
      "upscale_method": "lanczos",
      "megapixels": 1.0000000000000002,
      "image": [
        "281",
        0
      ]
    },
    "class_type": "ImageScaleToTotalPixels",
    "_meta": {
      "title": "Scale Image to Total Pixels"
    }
  },
  "257": {
    "inputs": {
      "lora_name": "pixar-animation-flux.safetensors",
      "strength_model": 0.8000000000000002,
      "strength_clip": 1.0000000000000002,
      "model": [
        "228",
        0
      ],
      "clip": [
        "228",
        1
      ]
    },
    "class_type": "LoraLoader",
    "_meta": {
      "title": "Load LoRA"
    }
  },
  "261": {
    "inputs": {
      "index": "0",
      "batch": false,
      "data": [
        "237",
        3
      ]
    },
    "class_type": "Florence2toCoordinates",
    "_meta": {
      "title": "Florence2 Coordinates"
    }
  },
  "262": {
    "inputs": {
      "keep_model_loaded": true,
      "individual_objects": false,
      "sam2_model": [
        "263",
        0
      ],
      "image": [
        "256",
        0
      ],
      "coordinates_positive": [
        "261",
        0
      ],
      "bboxes": [
        "261",
        1
      ]
    },
    "class_type": "Sam2Segmentation",
    "_meta": {
      "title": "Sam2Segmentation"
    }
  },
  "263": {
    "inputs": {
      "model": "sam2_hiera_base_plus.safetensors",
      "segmentor": "single_image",
      "device": "cuda",
      "precision": "fp16"
    },
    "class_type": "DownloadAndLoadSAM2Model",
    "_meta": {
      "title": "(Down)Load SAM2Model"
    }
  },
  "268": {
    "inputs": {
      "text_input": "",
      "task": "more_detailed_caption",
      "fill_mask": true,
      "keep_model_loaded": false,
      "max_new_tokens": 1024,
      "num_beams": 3,
      "do_sample": true,
      "output_mask_select": "",
      "seed": 1075573289505291,
      "image": [
        "281",
        0
      ],
      "florence2_model": [
        "282",
        0
      ]
    },
    "class_type": "Florence2Run",
    "_meta": {
      "title": "Florence2Run"
    }
  },
  "270": {
    "inputs": {
      "text": "Sharp headshot against a clean white backdrop.  Business professional attire, neutral tones.  Natural light, direct,  modern.",
      "old": "[caption]",
      "new": [
        "268",
        2
      ]
    },
    "class_type": "Replace Text _O",
    "_meta": {
      "title": "Replace Text _O"
    }
  },
  "277": {
    "inputs": {
      "size": "custom",
      "custom_width": [
        "278",
        0
      ],
      "custom_height": [
        "278",
        1
      ],
      "color": "#fff"
    },
    "class_type": "LayerUtility: ColorImage V2",
    "_meta": {
      "title": "LayerUtility: ColorImage V2"
    }
  },
  "278": {
    "inputs": {
      "image": [
        "283",
        0
      ]
    },
    "class_type": "easy imageSize",
    "_meta": {
      "title": "ImageSize"
    }
  },
  "281": {
    "inputs": {
      "invert_mask": true,
      "blend_mode": "normal",
      "opacity": 100,
      "background_image": [
        "277",
        0
      ],
      "layer_image": [
        "283",
        0
      ]
    },
    "class_type": "LayerUtility: ImageBlend V2",
    "_meta": {
      "title": "LayerUtility: ImageBlend V2"
    }
  },
  "282": {
    "inputs": {
      "model": "microsoft/Florence-2-base",
      "precision": "fp16",
      "attention": "eager",
      "convert_to_safetensors": false
    },
    "class_type": "DownloadAndLoadFlorence2Model",
    "_meta": {
      "title": "DownloadAndLoadFlorence2Model"
    }
  },
  "283": {
    "inputs": {
      "supabase_url": "https://xyrvruzxxekcbvjtqqdf.supabase.co",
      "supabase_key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5cnZydXp4eGVrY2J2anRxcWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4ODU3NDAsImV4cCI6MjA3MjQ2MTc0MH0.2S8SaLawLym1vMXz_RCWG88Fs-A4sykVxB_TCsen1_I",
      "table_name": "event_output_images",
      "image_column": "image_url",
      "id_column": "unique_id",
      "unique_id": "UNIQUE_ID_PLACEHOLDER"
    },
    "class_type": "SupabaseTableWatcherNode",
    "_meta": {
      "title": "Supabase Table Watcher"
    }
  },
  "284": {
    "inputs": {
      "unique_id": [
        "283",
        2
      ],
      "supabase_url": "https://xyrvruzxxekcbvjtqqdf.supabase.co",
      "supabase_key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Y3hjZGNwb254Y3Rlbm5jaWxhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTc3OTY5NiwiZXhwIjoyMDcxMzU1Njk2fQ.6zcfpjAdIfUrQR3iKYkPCn-vdttpEcfTRJskMv9BnRk",
      "bucket": "outputimages",
      "base_file_name": "image",
      "table_name": "event_output_images",
      "unique_id_column": "unique_id",
      "table_column": "output",
      "image": [
        "147",
        0
      ]
    },
    "class_type": "SupabaseImageUploader",
    "_meta": {
      "title": "Upload Image to Supabase"
    }
  }
}
''';

    // Parse the JSON and replace the unique_id
    final workflow = jsonDecode(workflowJson) as Map<String, dynamic>;

    // Replace the placeholder unique_id in node 283 (ONLY change this)
    if (workflow.containsKey('283')) {
      final node283 = workflow['283'] as Map<String, dynamic>;
      final inputs = node283['inputs'] as Map<String, dynamic>;
      inputs['unique_id'] = uniqueId;
    }

    return workflow;
  }

  /// Health check for ComfyUI endpoint
  static Future<Map<String, dynamic>> healthCheckComfyUI({
    required String apiUrl,
    required String apiKey,
  }) async {
    try {
      final payload = {
        'input': {'health': true},
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      final cleanApiUrl = apiUrl.endsWith('/')
          ? apiUrl.substring(0, apiUrl.length - 1)
          : apiUrl;
      final runUrl = '$cleanApiUrl/run';

      final response = await http.post(
        Uri.parse(runUrl),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'status': 'success', 'data': responseData};
      } else {
        return {
          'status': 'error',
          'message': 'ComfyUI health check failed: ${response.statusCode}',
        };
      }
    } on Exception catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
