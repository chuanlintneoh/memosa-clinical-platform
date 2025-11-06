import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MainService {
  // static const String _baseUrl = "http://10.0.2.2:8000";
  static final String _baseUrl = "${dotenv.env['BACKEND_SERVER_URL']}";

  static Future<bool> ping({int timeout = 3}) async {
    try {
      final url = Uri.parse("$_baseUrl/");
      final response = await http.get(url).timeout(Duration(seconds: timeout));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
