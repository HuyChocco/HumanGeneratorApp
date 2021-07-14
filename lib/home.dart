import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:humangenerator/drawingarea.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home();

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<DrawingArea> points = [];
  Widget imageOutput;

  void savetoImage(List<DrawingArea> points) async {
    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(200, 200)));

    Paint paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;
    canvas.drawRect(Rect.fromLTRB(0, 0, 256, 256), paint2);
    for (int x = 0; x < points.length - 1; x++) {
      if (points[x] != null && points[x + 1] != null) {
        canvas.drawLine(points[x].point, points[x + 1].point, paint);
      }
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);

    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final listBytes = Uint8List.view(pngBytes.buffer);
    String base64 = base64Encode(listBytes);
    fetchResponse(base64);
  }

  void fetchResponse(base64Image) async {
    var data = {'image': base64Image};

    Uri url = Uri.parse('http://192.168.1.4:5000/predict');

    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Connection': 'Keep-Alive',
    };
    var body = json.encode(data);
    try {
      var response = await http.post(url, body: body, headers: headers);
      final Map<String, dynamic> responseData = json.decode(response.body);
      String outputBytes = responseData['Image'];
      print(outputBytes.substring(2, outputBytes.length - 1));
      displayResponseImage(outputBytes.substring(2, outputBytes.length - 1));
    } catch (e) {
      print('* ERROR HAS OCCURED');
      print(e.toString());
      return null;
    }
  }

  void displayResponseImage(String bytes) async {
    Uint8List convertedBytes = base64Decode(bytes);

    setState(() {
      imageOutput = Container(
        width: 256,
        height: 256,
        child: Image.memory(
          convertedBytes,
          fit: BoxFit.cover,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(8, 35, 135, 1.0),
                    Color.fromRGBO(255, 64, 87, 1.0),
                    Color.fromRGBO(242, 113, 33, 1.0),
                  ]),
            ),
          ),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 5.0,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onPanDown: (details) {
                        this.setState(() {
                          points.add(DrawingArea(
                              point: details.localPosition,
                              areaPaint: Paint()
                                ..strokeCap = StrokeCap.round
                                ..isAntiAlias = true
                                ..color = Colors.white
                                ..strokeWidth = 2.0));
                        });
                      },
                      onPanUpdate: (details) {
                        this.setState(() {
                          points.add(DrawingArea(
                              point: details.localPosition,
                              areaPaint: Paint()
                                ..strokeCap = StrokeCap.round
                                ..isAntiAlias = true
                                ..color = Colors.white
                                ..strokeWidth = 2.0));
                        });
                      },
                      onPanEnd: (details) {
                        savetoImage(points);
                        this.setState(() {
                          points.add(null);
                        });
                      },
                      child: SizedBox.expand(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CustomPaint(
                            painter: MyCustomPainter(
                              points: points.toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.layers_clear,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            points.clear();
                          });
                        },
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.0,
                  ),
                  child: Container(
                    child: Center(
                      child: Container(
                        width: 256,
                        height: 256,
                        child: imageOutput,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
