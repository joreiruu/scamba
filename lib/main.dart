import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SpamDetectionUI(),
    );
  }
}

class SpamDetectionUI extends StatefulWidget {
  @override
  _SpamDetectionUIState createState() => _SpamDetectionUIState();
}

class _SpamDetectionUIState extends State<SpamDetectionUI> {
  TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _result = "";
  double _confidence = 0.0;
  int _inferenceTime = 0;

  void _simulatePrediction() {
    setState(() {
      _isLoading = true;
      _result = "";
      _confidence = 0.0;
      _inferenceTime = 0;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _result = "Ham"; 
        _confidence = 0.85;
        _inferenceTime = 120; 
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scamba Tester")),
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
                _isLoading
                    ? CircularProgressIndicator()
                    : SizedBox.shrink(),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _simulatePrediction,
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
}
