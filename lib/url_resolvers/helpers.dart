import 'dart:math';
import 'package:dio/dio.dart';

import '../globals.dart';

Future<String> girc(page_data, url, co) async {
  final client = Dio();
  final Map<String, String> hdrs = {
    'User-Agent': FF_USER_AGENT.toString(),
    'Referer': url,
  };
  var rurl = 'https://www.google.com/recaptcha/api.js';
  var aurl = 'https://www.google.com/recaptcha/api2';
  final key = RegExp(
    '(?:src="$rurl\?.*?render|data-sitekey)="?([^"]+)',
    caseSensitive: false,
  ).firstMatch(page_data)?.group(1);
  if (key != null) {
    rurl = '$rurl?render=$key';
    rurl = '$rurl?render=$key';
    final page_data1 = (await client.get(
      rurl,
      options: Options(headers: hdrs),
    ))
        .data;
    final v = RegExp(
      r'releases\/([^\/]+)',
      caseSensitive: false,
    ).firstMatch(page_data1)?.group(1);
    final rdata = {
      'ar': 1,
      'k': key,
      'co': co,
      'hl': 'en',
      'v': v,
      'size': 'invisible',
      'cb': '123456789',
    };
    final furl = '$aurl/anchor?${urlEncode(rdata)}';
    final page_data2 = (await client.get(
      furl,
      options: Options(headers: hdrs),
    ))
        .data;
    final rtoken = RegExp(
      r'recaptcha-token.+?="([^"]+)',
      caseSensitive: false,
    ).firstMatch(page_data2)?.group(1);
    if (rtoken != null) {
      final pdata = {
        'v': v,
        'reason': 'q',
        'k': key,
        'c': rtoken,
        'sa': '',
        'co': co,
      };
      hdrs['Referer'] = aurl;
      final page_data3 = (await client.post(
        '$aurl/reload?k=$key',
        data: pdata,
        options: Options(headers: hdrs),
      ))
          .data;
      final gtoken = RegExp(
        'rresp","([^"]+)',
        caseSensitive: false,
      ).firstMatch(page_data3)?.group(1);
      if (gtoken != null) return gtoken;
    }
  }
  return '';
}

String urlEncode(Map data) {
  String encodedData = '';
  for (int i = 0; i < data.keys.toList().length; i++) {
    final key = data.keys.toList()[i];
    encodedData = encodedData + '$key=${data[key]}';
    if (i < data.keys.toList().length - 1) encodedData = encodedData + '&';
  }
  return encodedData;
}

Map<String, String> getHidden(String html) {
  final matches = RegExp('<input type="hidden" name=".*" value=.(.*).>',
          caseSensitive: false)
      .allMatches(html);
  const keys = ['op', 'id', 'mode', 'hash'];
  Map<String, String> hidden = {};
  try {
    for (int i = 0; i < 4; i++) {
      hidden[keys[i]] = matches.toList()[i].group(1).toString();
    }
    return hidden;
  } catch (e) {
    return {};
  }
}

String randUA() {
  const uAS = [
    IE_USER_AGENT,
    FF_USER_AGENT,
    OPERA_USER_AGENT,
    IOS_USER_AGENT,
    EDGE_USER_AGENT,
    CHROME_USER_AGENT,
    SAFARI_USER_AGENT,
    ANDROID_USER_AGENT
  ];
  return uAS[Random().nextInt(8)];
}
