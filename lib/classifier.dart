import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class PredictionResult {
  final bool isSpam;
  final double confidence;

  PredictionResult({required this.isSpam, required this.confidence});
}

class Classifier {
  final String _modelFile = 'assets/lite_scamba_bert_model_tv0_fix2.tflite';
  final String _vocabFile = 'assets/vocab.txt';
  static const int MAX_SEQUENCE_LENGTH = 128;
  static const int EMBEDDING_SIZE = 768;  // Standard BERT embedding size

  late Interpreter _interpreter;
  bool isModelLoaded = false;
  Map<String, int> _vocab = {};

  Future<void> loadModel() async {
    try {
      print("🟡 Loading TensorFlow Lite model...");
      
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(_modelFile, options: options);
      await _loadDictionary();
      isModelLoaded = true;

      // Get input tensors
      var inputTensors = _interpreter.getInputTensors();
      for (int i = 0; i < inputTensors.length; i++) {
        print("📌 Input Tensor $i Shape: ${inputTensors[i].shape}");
        print("📌 Input Tensor $i Type: ${inputTensors[i].type}");
      }
      
      // Get output tensors
      var outputTensors = _interpreter.getOutputTensors();
      for (int i = 0; i < outputTensors.length; i++) {
        print("📌 Output Tensor $i Shape: ${outputTensors[i].shape}");
        print("📌 Output Tensor $i Type: ${outputTensors[i].type}");
      }
    } catch (e) {
      print("❌ Error loading model: $e");
      rethrow;
    }
  }

  Future<void> _loadDictionary() async {
    try {
      print("🟡 Loading vocabulary...");
      final vocabData = await rootBundle.loadString(_vocabFile);
      _vocab.clear();

      for (var line in vocabData.split('\n')) {
        line = line.trim();
        if (line.isEmpty) continue;
        
        // Handle both formats: with and without index
        if (line.contains(' ')) {
          final parts = line.split(' ');
          final token = parts[0];
          final index = int.tryParse(parts[1]);
          if (index != null) {
            _vocab[token] = index;
          }
        }
      }

      print("✅ Vocabulary loaded with ${_vocab.length} tokens");
    } catch (e) {
      print("❌ Error loading vocabulary: $e");
      rethrow;
    }
  }

  Map<String, List<List<dynamic>>> _tokenize(String text) {
    try {
      print("🟡 Tokenizing: '$text'");
      
      // Initialize tensors with correct shapes
      var inputIds = List.generate(1, (_) => List.filled(MAX_SEQUENCE_LENGTH, 0));
      var attentionMask = List.generate(1, (_) => List.filled(MAX_SEQUENCE_LENGTH, 0));
      var tokenTypeIds = List.generate(1, (_) => List.filled(MAX_SEQUENCE_LENGTH, 0));
      
      // Start with [CLS]
      inputIds[0][0] = _vocab['[CLS]'] ?? 101;
      attentionMask[0][0] = 1;
      
      // Tokenize text
      text = text.toLowerCase().trim();
      List<String> words = text.split(RegExp(r'\s+'));
      
      int position = 1;
      for (String word in words) {
        if (position >= MAX_SEQUENCE_LENGTH - 1) break;
        
        int tokenId = _vocab[word] ?? _vocab['[UNK]'] ?? 100;
        inputIds[0][position] = tokenId;
        attentionMask[0][position] = 1;
        position++;
      }
      
      // Add [SEP]
      if (position < MAX_SEQUENCE_LENGTH) {
        inputIds[0][position] = _vocab['[SEP]'] ?? 102;
        attentionMask[0][position] = 1;
      }

      print("✅ Input shape: [1, $MAX_SEQUENCE_LENGTH]");
      print("✅ First few tokens: ${inputIds[0].take(position + 1).toList()}");
      
      return {
        'input_ids': inputIds,
        'attention_mask': attentionMask,
        'token_type_ids': tokenTypeIds,
      };
    } catch (e) {
      print("❌ Tokenization error: $e");
      rethrow;
    }
  }

  Future<PredictionResult> classify(String text) async {
    if (!isModelLoaded) {
      throw StateError("Model not loaded");
    }

    try {
      print("🟡 Classifying text: \"$text\"");
      
      // Get tokenized inputs
      final tokenized = _tokenize(text);
      
      // Prepare inputs list in the correct order
      final inputs = [
        tokenized['input_ids']!,
        tokenized['attention_mask']!,
        tokenized['token_type_ids']!,
      ];
      
      // Prepare output buffer with shape [1, 2] for binary classification
      var outputs = List.generate(1, (_) => List<double>.filled(2, 0));
      
      // Run inference
      final startTime = DateTime.now();
      _interpreter.runForMultipleInputs(inputs, {0: outputs});
      final inferenceTime = DateTime.now().difference(startTime);
      
      // Process results
      final confidence = outputs[0][1];
      final isSpam = confidence > 0.5;
      
      print("✅ Inference complete in ${inferenceTime.inMilliseconds}ms");
      print("📊 Raw outputs: $outputs");
      print("📊 Confidence: ${(confidence * 100).toStringAsFixed(2)}%");
      
      return PredictionResult(isSpam: isSpam, confidence: confidence);
    } catch (e) {
      print("❌ Classification error: $e");
      rethrow;
    }
  }

  void close() {
    if (isModelLoaded) {
      _interpreter.close();
      isModelLoaded = false;
    }
  }
}