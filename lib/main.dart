import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

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
  String _result = "";
  double _confidence = 0.0;
  int _inferenceTime = 0;
  late Interpreter _interpreter;
  bool _modelLoaded = false;
  Map<String, int> _vocab = {};
  final int _sentenceLen = 128;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("assets/lite_scamba_bert_model_tv0_fix2.tflite");
      await _loadDictionary();
      setState(() {
        _modelLoaded = true;
      });
      print("Model Loaded Successfully!");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _loadDictionary() async {
  try {
    final vocabData = await rootBundle.loadString("assets/vocab.txt");
    final lines = vocabData.split('\n').where((line) => line.isNotEmpty).toList();
    
    _vocab = {for (var i = 0; i < lines.length; i++) lines[i].trim(): i};
    
    print("Vocabulary Loaded Successfully! Size: ${_vocab.length}");
  } catch (e) {
    print("Error loading vocabulary: $e");
  }
}


  Future<void> classifyText(String text) async {
    if (!_modelLoaded) {
      print("Error: Model not loaded yet!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final startTime = DateTime.now().millisecondsSinceEpoch;
    List<List<double>> input = _tokenize(text);
    var output = List.filled(2, 0.0).reshape([1, 2]);

    _interpreter.run(input, output);
    final endTime = DateTime.now().millisecondsSinceEpoch;

    bool isSpam = output[0][1] > output[0][0]; // Spam detection logic
    setState(() {
      _isLoading = false;
      _result = isSpam ? "Spam" : "Ham";
      _confidence = isSpam ? output[0][1] : output[0][0];
      _inferenceTime = endTime - startTime;
    });
  }

  List<List<double>> _tokenize(String text) {
  List<String> words = text.split(' ');
  List<double> tokenized = List.filled(_sentenceLen, (_vocab["[PAD]"] ?? 0).toDouble());

  int index = 0;
  tokenized[index++] = (_vocab["[CLS]"] ?? 2).toDouble(); // BERT CLS token

  for (var word in words.take(_sentenceLen - 1)) {
    tokenized[index++] = (_vocab[word] ?? _vocab["[UNK]"] ?? 1).toDouble();
  }

  return [tokenized];
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
    _interpreter.close();
    super.dispose();
  }
}
