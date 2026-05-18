import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_sdk_flutter/places_sdk_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelGooglePlacesFlutter();
  const channel = MethodChannel('places_sdk_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'searchPlace':
          return [
            {
              'placeId': 'abc',
              'primaryText': 'P',
              'secondaryText': 'S',
              'fullText': 'P S',
              'types': <String>[],
            },
          ];
        case 'getPlaceDetails':
          return {'placeId': methodCall.arguments['placeId'], 'name': 'X'};
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('searchPlace', () async {
    final rows = await platform.searchPlace(query: 'paris', apiKey: 'key');
    expect(rows.single['placeId'], 'abc');
  });

  test('getPlaceDetails', () async {
    final row = await platform.getPlaceDetails(placeId: 'abc', apiKey: 'key');
    expect(row['name'], 'X');
  });
}
