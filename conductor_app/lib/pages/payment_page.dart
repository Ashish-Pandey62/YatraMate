import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:conductor_app/utils/utils.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as djwt;
import 'package:basic_utils/basic_utils.dart';
import 'dart:ui' as ui;

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  ImageProvider? _textAsImageProvider;
  final TextEditingController _priceController = TextEditingController();
  String _qrData = "";
  String _secretKey = "";
  String? _token = "";
  bool _isLoading = false;
  String? username = "";
  get center => null;
  @override
  void initState() {
    super.initState();
    _onPageRendered();
  }

  bool clicked = false;

  void _onPageRendered() async {
    setState(() {
      _isLoading = true;
    });
    // Add your code here that needs to be executed when the page renders
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    username = prefs.getString('username');
    _secretKey = (await getPrivateKey()).toString();
    if (_secretKey == "null") {
      _updateSecretKey();
    } else {
      setState(() {
        _isLoading = false;
        clicked = false;
      });
    }
  }

  void _updateSecretKey() async {
    setState(() {
      _isLoading = true;
    });
    final pair = generateRSAkeyPair(exampleSecureRandom());
    final public = pair.publicKey;
    final private = pair.privateKey;
    _secretKey = CryptoUtils.encodeRSAPrivateKeyToPem(private);
    final String baseUrl = dotenv.env['SITE_URL'] ?? '';
    final String secretKeyUpdate = '$baseUrl/api/update-secret-key/';
    if (baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SITE_URL not found in .env')),
      );
    }
    final response = await http.post(
      Uri.parse(secretKeyUpdate),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_token',
      },
      body: jsonEncode(
          {'secret_key': CryptoUtils.encodeRSAPublicKeyToPem(public)}),
    );
    if (response.statusCode == 200) {
      await storePrivateKey(CryptoUtils.encodeRSAPrivateKeyToPem(private));
      setState(() {
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update secret key')),
      );

      setState(() {
        _isLoading = false;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _generateQR() async {
    ImageProvider gg = await _generateTextImage(_priceController.text);
    setState(() {
      // Get the current date (used as the 'issued at' and 'expiration' date)
      final now = DateTime.now();
      clicked = true;
      // Define the payload (claims)
      final payload = {
        'sub':
            username, // 'sub' is typically used for the subject (user's identity)
        'price': _priceController.text, // Price in the payload
        'iat': now
            .toUtc()
            .millisecondsSinceEpoch, // 'iat' (Issued At) is the timestamp of when the JWT was created in UTC
        'exp': now
            .add(const Duration(minutes: 15))
            .toUtc()
            .millisecondsSinceEpoch, // 'exp' (Expiration) is 1 hour from now
      };
      final jwt = djwt.JWT(payload);
      final privateKey = djwt.RSAPrivateKey(_secretKey);
      final token = jwt.sign(privateKey, algorithm: djwt.JWTAlgorithm.RS256);
      _qrData = token.toString();
      _textAsImageProvider = gg;
    });
  }

  Future<ImageProvider> _generateTextImage(String text) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color.fromARGB(255, 236, 0, 0),
          fontSize: 60,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: Colors.white,
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final width = textPainter.width;
    final height = textPainter.height;
    textPainter.paint(canvas, const Offset(0, 0));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    return MemoryImage(pngBytes);
  }

  // Function to show the confirmation dialog
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm QR Code Generation'),
          content: const Text('Are you sure you want to generate new QR code?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _generateQR(); // Call the function after confirmation
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Caution : Don't generate multiple QR codes.",
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
              textAlign: TextAlign.left,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Enter Price',
                labelStyle: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight
                        .bold), // Increased font size and made it bold
                hintText: 'Enter the price to generate QR code',
                hintStyle: TextStyle(
                    fontSize: 15.0,
                    fontStyle: FontStyle.italic,
                    color: Color.fromARGB(
                        255, 158, 158, 158)), // Increased font size
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 25.0), // Increased font size
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                clicked ? _showConfirmationDialog(context) : _generateQR();
              },
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 20),
            _qrData.isNotEmpty
                ? QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    embeddedImage: _textAsImageProvider,
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
