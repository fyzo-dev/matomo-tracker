import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'logger.dart';
import 'matomo_event.dart';

class MatomoDispatcher {
  final String? tokenAuth;
  final http.Client httpClient;
  final Logger? logger;

  final Uri baseUri;

  MatomoDispatcher(
    String baseUrl,
    this.tokenAuth, {
    http.Client? httpClient,
    this.logger,
  })  : baseUri = Uri.parse(baseUrl),
        httpClient = httpClient ?? http.Client();

  Future<void> send(MatomoEvent event) async {
    final userAgent = event.tracker.userAgent;
    final headers = <String, String>{
      if (!kIsWeb && userAgent != null) 'User-Agent': userAgent,
    };

    final uri = _buildUriForEvent(event);
    logger?.fine(' -> ${uri.toString()}');
    try {
      final response = await httpClient.post(uri, headers: headers);
      final statusCode = response.statusCode;
      logger?.fine(' <- $statusCode');
    } catch (e) {
      logger?.fine(' <- ${e.toString()}');
    }
  }

  Future<void> sendBatch(List<MatomoEvent> events) async {
    if (events.isEmpty) {
      return;
    }

    final userAgent = events.first.tracker.userAgent;
    final headers = <String, String>{
      if (!kIsWeb && userAgent != null) 'User-Agent': userAgent,
    };

    final batch = {
      "requests": [
        for (final event in events)
          "?${_buildUriForEvent(event).query}",
      ],
    };
    logger?.fine(' -> ${batch.toString()}');
    try {
      final response = await httpClient.post(
        baseUri,
        headers: headers,
        body: jsonEncode(batch),
      );
      final statusCode = response.statusCode;
      logger?.fine(' <- $statusCode');
    } catch (e) {
      logger?.fine(' <- ${e.toString()}');
    }
  }

  Uri _buildUriForEvent(MatomoEvent event) {
    final queryParameters = Map<String, String>.from(baseUri.queryParameters)
      ..addAll(event.toMap());
    final aTokenAuth = tokenAuth;
    if (aTokenAuth != null) {
      queryParameters.addEntries([MapEntry('token_auth', aTokenAuth)]);
    }

    return baseUri.replace(queryParameters: queryParameters);
  }
}
