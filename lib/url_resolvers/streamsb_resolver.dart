import 'dart:convert';

import 'package:dio/dio.dart';

import './helpers.dart';

class StreamSBResolver {
  RegExp _downloadRegex = RegExp(
    r"download_video.'(.*?)'.*'n'.*'(.*?)'",
    caseSensitive: false,
  );
  RegExp _urlRegex = RegExp(
    r'href=\"([^\"]+)\">Direct',
    caseSensitive: false,
  );

  Future<List> resolveUrl(String url) async {
    Dio client = Dio();
    url = url.replaceAll('/e/', '/d/');
    String host = Uri.parse(url).host;
    String rurl = 'https://$host/';
    final headers = {
      'User-Agent': randUA(),
      'Referer': rurl,
    };
    final res = await client.get(url);
    if (res.statusCode == 200) {

      final downloadMatches = _downloadRegex.firstMatch(res.data);
      final id = downloadMatches?.group(1);
      final hash = downloadMatches?.group(2);
      final dUrl = '${rurl}dl?op=download_orig&id=$id&mode=n&hash=$hash';
      final res2 = await client.get(
        dUrl,
        options: Options(headers: headers),
      );
      if (res2.statusCode == 200) {
        var body2= res2.data;
        final domain = base64Encode(
                utf8.encode((rurl.substring(0, rurl.length - 1) + ':443')))
            .replaceAll('=', '');
        final token = await girc(body2, rurl, domain);
        headers['Referer'] = dUrl;
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        final form_content = getHidden(body2);
        form_content['g-recaptcha-response'] = token.toString();
        final res3 = await client.post(
          dUrl,
          data: form_content,
          options: Options(headers: headers),
        );
        if (res3.statusCode == 200) {
          String mediaUrl =
              _urlRegex.firstMatch(res3.data)?.group(1).toString() ?? '';
          return [
            {
              'label': '720p',
              'file': mediaUrl,
            }
          ];
        }
      }
    }

    return [];
  }
}
