import 'package:flutter/material.dart';
import 'classifier.dart';

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
  final TextEditingController _controller = TextEditingController();
  final Classifier _classifier = Classifier();
  bool _isLoading = false;
  String _result = "";
  double _confidence = 0.0;
  int _inferenceTime = 0;

  @override
  void initState() {
    super.initState();
    print("🟡 Loading model...");
    _classifier.loadModel().then((_) {
      setState(() {});
      print("✅ Model loaded successfully!");
    });
  }

  Future<void> classifyText(String text) async {
    if (!_classifier.isModelLoaded) {
      print("❌ Error: Model not loaded yet!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print("🟡 Classifying text: \"$text\"");

    final startTime = DateTime.now().millisecondsSinceEpoch;
    final prediction = await _classifier.classify(text);
    final endTime = DateTime.now().millisecondsSinceEpoch;

    print("✅ Classification completed!");
    print("📌 Prediction: ${prediction.isSpam ? "Spam" : "Ham"}");
    print("📊 Confidence: ${(prediction.confidence * 100).toStringAsFixed(2)}%");
    print("⏳ Inference Time: ${endTime - startTime}ms");

    setState(() {
      _isLoading = false;
      _result = prediction.isSpam ? "Spam" : "Ham";
      _confidence = prediction.confidence;
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
                  onPressed: (!_isLoading && _classifier.isModelLoaded)
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
    _classifier.close();
    super.dispose();
  }
}
