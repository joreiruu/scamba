import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SpamDetectionApp(),
    );
  }
}

class SpamDetectionApp extends StatefulWidget {
  @override
  _SpamDetectionAppState createState() => _SpamDetectionAppState();
}

class _SpamDetectionAppState extends State<SpamDetectionApp> {
  TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _modelLoaded = false;
  String _result = "";
  double _confidence = 0.0;
  int _inferenceTime = 0;
  Interpreter? _interpreter;

  Map<String, int> vocab = {
    "[PAD]": 0,
    "[UNK]": 1,
    "[CLS]": 2,
    "[SEP]": 3,
    "spam": 4,
    "ham": 5,
  };

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("assets/lite_scam_ham_bert_model_tv0.tflite");
      print("Model Loaded Successfully!");
      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  List<int> tokenizeText(String text) {
    List<String> words = text.toLowerCase().split(" ");
    List<int> tokenized = [vocab["[CLS]"] ?? 2]; // BERT CLS token

    for (var word in words) {
      tokenized.add(vocab[word] ?? vocab["[UNK]"]!); // Convert to token ID, default to UNK
    }

    tokenized.add(vocab["[SEP]"] ?? 3); // BERT SEP token
    while (tokenized.length < 128) {
      tokenized.add(vocab["[PAD]"] ?? 0); // Pad to 128 tokens
    }
    
    return tokenized.sublist(0, 128); // Ensure input is 128 tokens
  }

  Future<void> classifyText(String text) async {
    if (!_modelLoaded || _interpreter == null) {
      print("Error: Model not loaded yet!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final startTime = DateTime.now().millisecondsSinceEpoch;

    List<int> tokenizedInput = tokenizeText(text);
    Uint8List inputTensor = Uint8List.fromList(tokenizedInput);

    var output = List.filled(2, 0).reshape([1, 2]);

    _interpreter!.run([inputTensor], output);

    final endTime = DateTime.now().millisecondsSinceEpoch;

    int predictedLabelIndex = output[0][0]; // Assuming classification index
    double confidence = output[0][1] / 255.0; // Normalize

    setState(() {
      _isLoading = false;
      _result = predictedLabelIndex == 1 ? "Spam" : "Ham";
      _confidence = confidence;
      _inferenceTime = endTime - startTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scamba")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter SMS Text",
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoading ? CircularProgressIndicator() : SizedBox.shrink(),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: (!_isLoading && _modelLoaded)
                      ? () => classifyText(_controller.text)
                      : null,
                  child: Text("Predict"),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_result.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text("Prediction: $_result", style: TextStyle(fontSize: 18)),
                    Text("Confidence: ${(_confidence * 100).toStringAsFixed(2)}%"),
                    Text("Inference Time: ${_inferenceTime}ms"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
