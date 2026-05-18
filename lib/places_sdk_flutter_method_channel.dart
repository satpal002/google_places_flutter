import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'places_sdk_flutter_platform_interface.dart';

class MethodChannelGooglePlacesFlutter extends GooglePlacesFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('places_sdk_flutter');

  @override
  Future<List<Map<String, dynamic>>> searchPlace({
    required String query,
    String? apiKey,
    String? countryCode,
    int limit = 10,
  }) async {
    final raw = await methodChannel.invokeMethod<List<dynamic>>(
      'searchPlace',
      <String, dynamic>{
        'query': query,
        if (apiKey != null && apiKey.isNotEmpty) 'apiKey': apiKey,
        if (countryCode != null && countryCode.isNotEmpty) 'countryCode': countryCode,
        'limit': limit,
      },
    );
    if (raw == null) {
      return [];
    }
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getPlaceDetails({
    required String placeId,
    String? apiKey,
  }) async {
    final raw = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getPlaceDetails',
      <String, dynamic>{
        'placeId': placeId,
        if (apiKey != null && apiKey.isNotEmpty) 'apiKey': apiKey,
      },
    );
    if (raw == null) {
      throw PlatformException(
        code: 'PLACE_DETAILS_EMPTY',
        message: 'Native layer returned no data',
      );
    }
    return Map<String, dynamic>.from(raw);
  }
}
