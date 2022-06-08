
import 'package:dio/dio.dart';

import './helpers.dart';

class FembedResolver {
  Future<List> resolveUrl(webUrl) async {
    Dio client = Dio();
    final String host = Uri.parse(webUrl).host;
    final String mediaId = List.from(webUrl.split('/').reversed)[0];
    final Map<String, String> headers = {
      'User-Agent': randUA(),
    };
    headers['Referer'] = webUrl;
    String apiUrl = 'https://$host/api/source/$mediaId';
    final res = await client.post(apiUrl, options: Options(headers: headers));
    if (res.statusCode == 200) {

      if (res.data['success']) {
        return res.data['data'];
      }
    }
    return [];
  }
}
