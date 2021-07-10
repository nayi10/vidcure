import 'dart:convert';

import 'package:http/http.dart' as http;

const APP_ID = '992cb6fb14eb4efd9cfaddf901cacbb9';

Future<String> getToken() async {
  Uri url = Uri.parse(
      'https://vidcure.herokuapp.com/access_token?channel=public&uid=0');
  var res = await http.get(url);
  String token = jsonDecode(res.body)['token'];
  return token;
}