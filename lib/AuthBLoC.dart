import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_no_sleep/AuthEvents.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthBLoC {
  final _authCodeStreamController = StreamController<String>();
  StreamSink<String> get _authCodeSink => _authCodeStreamController.sink;
  Stream<String> get _streamAuthCode => _authCodeStreamController.stream;

  final _accessTokenStreamController = StreamController<String>();
  StreamSink<String> get _accessTokenSink => _accessTokenStreamController.sink;
  Stream<String> get streamAccessToken => _accessTokenStreamController.stream;

  final _authRequestEventController = StreamController<AuthRequestEvent>();
  Sink<AuthRequestEvent> get authRequestEventSink =>
      _authRequestEventController.sink;
  Stream<AuthRequestEvent> get _streamAuthRequestEvent =>
      _authRequestEventController.stream;

  final _profileDataController = StreamController<String>();
  Sink<String> get _profileDataSink => _profileDataController.sink;
  Stream<String> get streamProfileData => _profileDataController.stream;

  final String _redditUrl = 'https://www.reddit.com/api/v1/authorize.compact?'
      'client_id=oXXqVSaNuv9nWg'
      '&response_type=code'
      '&state=hi'
      '&redirect_uri=http://localhost:8084'
      '&duration=temporary'
      '&scope=identity, edit, flair, history, modconfig, modflair, modlog, modposts, modwiki, mysubreddits, privatemessages, read, report, save, submit, subscribe, vote, wikiedit, wikiread';

  Future<HttpServer> _server(port) async {
    return await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  }

  void _authRequestReceived(AuthRequestEvent event) async {
    await launch(_redditUrl);
    var server = await _server(8084);

    server.listen((HttpRequest request) async {
      final String authCode = request.uri.queryParameters["code"];

      request.response
        ..statusCode = 200
        ..headers.set("Content-Type", ContentType.html.mimeType)
        ..write("<html><h1>You can now close this window</h1></html>");

      await request.response.close();
      await server.close();

      _authCodeSink.add(authCode);
    });
  }

  void _authCodeReceived(String authCode) async {
    final Response response = await post(
        'https://www.reddit.com/api/v1/access_token',
        headers: {
          'Content-type': 'application/x-www-form-urlencoded',
          'Authorization':
              'Basic ' + base64.encode(latin1.encode('oXXqVSaNuv9nWg:'))
        },
        body: 'grant_type=authorization_code&code=' +
            authCode +
            '&redirect_uri=http://localhost:8084');

    final Map<String, dynamic> responseFields = jsonDecode(response.body);
    final String accessToken = responseFields['access_token'];

    _accessTokenSink.add(accessToken);
  }

  void _requestProfile(String accessToken) async {
    final Response response = await get('https://oauth.reddit.com/api/v1/me',
        headers: {'Authorization': 'Bearer ' + accessToken});

    final Map<String, dynamic> responseFields = jsonDecode(response.body);
    final String name = responseFields['name'];

    _profileDataSink.add(name);
  }

  AuthBLoC() {
    _streamAuthRequestEvent.listen(_authRequestReceived);
    _streamAuthCode.listen(_authCodeReceived);
    streamAccessToken.listen(_requestProfile);
  }

  dispose() {
    _authCodeStreamController.close();
    _accessTokenStreamController.close();
    _authRequestEventController.close();
    _profileDataController.close();
  }
}
