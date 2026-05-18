import 'package:flutter_test/flutter_test.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/google_places_flutter_platform_interface.dart';
import 'package:google_places_flutter/google_places_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGooglePlacesFlutterPlatform with MockPlatformInterfaceMixin implements GooglePlacesFlutterPlatform {
  @override
  Future<List<Map<String, dynamic>>> searchPlace({
    required String query,
    String? apiKey,
    String? countryCode,
    int limit = 10,
  }) async {
    return [
      {
        'placeId': 'p1',
        'primaryText': 'Test',
        'secondaryText': 'Sub',
        'fullText': 'Test Sub',
        'types': <String>['establishment'],
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> getPlaceDetails({
    required String placeId,
    String? apiKey,
  }) async {
    return {
      'placeId': placeId,
      'name': 'N',
      'formattedAddress': 'A',
      'latitude': 1.0,
      'longitude': 2.0,
      'types': <String>['point_of_interest'],
    };
  }
}

void main() {
  final GooglePlacesFlutterPlatform initialPlatform = GooglePlacesFlutterPlatform.instance;

  test('$MethodChannelGooglePlacesFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGooglePlacesFlutter>());
  });

  test('searchPlace parses predictions', () async {
    GooglePlacesFlutterPlatform.instance = MockGooglePlacesFlutterPlatform();
    final list = await searchPlace(query: 'q', apiKey: 'k');
    expect(list, hasLength(1));
    expect(list.single.placeId, 'p1');
    expect(list.single.primaryText, 'Test');
  });

  test('getPlaceDetails parses model', () async {
    GooglePlacesFlutterPlatform.instance = MockGooglePlacesFlutterPlatform();
    final d = await getPlaceDetails(placeId: 'pid', apiKey: 'k');
    expect(d.placeId, 'pid');
    expect(d.name, 'N');
    expect(d.latitude, 1.0);
  });
}
