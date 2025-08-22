import 'dart:convert';
import 'package:flutter/services.dart';

class Workflow {
  final Map<String, dynamic> _workflow;

  Workflow(this._workflow);

  static Future<Workflow> getWorkflow(String fileName) async {
    final String jsonString = await rootBundle.loadString('lib/workflow/$fileName');
    final Map<String, dynamic> workflowData = jsonDecode(jsonString);
    return Workflow(workflowData);
  }

  void updateSupabaseWatcherNode(String uniqueId, {required String nodeId}) {
    if (_workflow.containsKey(nodeId) &&
        _workflow[nodeId].containsKey('inputs')) {
      _workflow[nodeId]['inputs']['unique_id'] = uniqueId;
    }
  }

  void updateSwaplabCharacterImage(String path) {
    // Node 46 is the Image Load node for the character image in swaplabonline.json
    if (_workflow.containsKey('46') && _workflow['46'].containsKey('inputs')) {
      _workflow['46']['inputs']['image_path'] = path.replaceAll(r'\', '/');
    }
  }

  void updateNoiseSeed(int seed) {
    // For swaplabonline.json, there is no noise seed node
    // Check if node 25 exists (for other workflows)
    if (_workflow.containsKey('25') && _workflow['25'].containsKey('inputs')) {
      _workflow['25']['inputs']['noise_seed'] = seed;
    }
    // Also check for other common seed nodes
    _workflow.forEach((key, value) {
      if (value is Map && value.containsKey('inputs')) {
        final inputs = value['inputs'];
        if (inputs is Map && inputs.containsKey('noise_seed')) {
          inputs['noise_seed'] = seed;
        }
      }
    });
  }

  void updateSupabaseCredentials(String url, String key) {
    // Update all nodes that have Supabase URL and key
    _workflow.forEach((nodeId, node) {
      if (node is Map && node.containsKey('inputs')) {
        final inputs = node['inputs'];
        if (inputs is Map) {
          // Update URL if present
          if (inputs.containsKey('supabase_url')) {
            inputs['supabase_url'] = url;
          }
          // Update key if present
          if (inputs.containsKey('supabase_key')) {
            inputs['supabase_key'] = key;
          }
        }
      }
    });
  }

  Map<String, dynamic> toMap() {
    return _workflow;
  }

  /// Converts the workflow map to a JSON string.
  String toJSON() {
    return jsonEncode(_workflow);
  }
}