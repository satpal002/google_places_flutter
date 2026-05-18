import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'places_sdk_flutter_method_channel.dart';

abstract class GooglePlacesFlutterPlatform extends PlatformInterface {
  GooglePlacesFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static GooglePlacesFlutterPlatform _instance = MethodChannelGooglePlacesFlutter();

  static GooglePlacesFlutterPlatform get instance => _instance;

  static set instance(GooglePlacesFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<Map<String, dynamic>>> searchPlace({
    required String query,
    String? apiKey,
    String? countryCode,
    int limit = 10,
  }) {
    throw UnimplementedError('searchPlace has not been implemented.');
  }

  Future<Map<String, dynamic>> getPlaceDetails({
    required String placeId,
    String? apiKey,
  }) {
    throw UnimplementedError('getPlaceDetails has not been implemented.');
  }
}
