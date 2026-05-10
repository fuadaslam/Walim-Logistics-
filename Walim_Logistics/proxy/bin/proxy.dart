import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:http/http.dart' as http;

const _target = 'https://beta-api-iot.alrakeen.sa/api';
const _apiKey = '57A645391187945A971B78D029383038';

final _client = http.Client();

Map<String, String> _corsHeaders(Map<String, String> extra) => {
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
      'access-control-allow-headers':
          'Content-Type, Accept, X-API-KEY, Authorization',
      ...extra,
    };

Future<Response> _apiHandler(Request req) async {
  // Handle CORS preflight
  if (req.method == 'OPTIONS') {
    return Response.ok('', headers: _corsHeaders({}));
  }

  final path = req.requestedUri.path.replaceFirst('/rakeen', '');
  final query = req.requestedUri.query;
  final url = Uri.parse('$_target$path${query.isNotEmpty ? '?$query' : ''}');

  final headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-KEY': _apiKey,
  };

  http.Response res;
  try {
    if (req.method == 'POST' || req.method == 'PATCH' || req.method == 'PUT') {
      final body = await req.readAsString();
      res = await _client
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 45));
    } else if (req.method == 'DELETE') {
      res = await _client
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 45));
    } else {
      // Retry once on 504 — transient gateway timeouts on Rakeen side
      res = await _client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 45));
      if (res.statusCode == 504) {
        await Future.delayed(const Duration(seconds: 2));
        res = await _client
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 45));
      }
    }
  } catch (e) {
    print('[proxy] EXCEPTION for $url: $e');
    return Response(
      504, 
      body: '{"error": "Gateway Timeout", "details": "$e"}',
      headers: _corsHeaders({'content-type': 'application/json; charset=utf-8'}),
    );
  }

  print('[proxy] ${req.method} $url → ${res.statusCode}');
  if (res.statusCode != 200) {
    final preview = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
    print('[proxy] ERROR body: $preview');
  }

  return Response(
    res.statusCode,
    body: res.body,
    headers: _corsHeaders({'content-type': 'application/json; charset=utf-8'}),
  );
}

void main() async {
  final router = Router();

  router.get('/health', (_) => Response.ok('{"status":"ok"}',
      headers: _corsHeaders({'content-type': 'application/json'})));

  router.all('/rakeen/<path|.*>', _apiHandler);

  String webPath = '../build/web';
  if (!Directory(webPath).existsSync()) {
    webPath = 'build/web';
  }

  final staticHandler = createStaticHandler(
    webPath,
    defaultDocument: 'index.html',
    serveFilesOutsidePath: true,
  );

  final handler = Cascade().add(router.call).add(staticHandler).handler;

  final server = await io.serve(handler, 'localhost', 8080);
  print('Proxy running at http://localhost:${server.port}');
}
