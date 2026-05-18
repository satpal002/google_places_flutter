import 'places_sdk_flutter_platform_interface.dart';

/// A structured part of a place address (street, city, country, etc.).
///
/// Field names match the [Google Places address component](https://developers.google.com/maps/documentation/places/web-service/place-types#address-types)
/// JSON shape (`long_name`, `short_name`, `types`) for compatibility with map pickers.
class AddressComponent {
  const AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  final String longName;
  final String shortName;
  final List<String> types;

  factory AddressComponent.fromMap(Map<String, dynamic> map) {
    return AddressComponent(
      longName: map['long_name'] as String? ?? map['longName'] as String? ?? '',
      shortName: map['short_name'] as String? ?? map['shortName'] as String? ?? '',
      types: (map['types'] as List<dynamic>?)?.map((e) => '$e').toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'long_name': longName,
        'short_name': shortName,
        'types': types,
      };
}

/// Autocomplete row from [searchPlace].
class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
    required this.types,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
  final List<String> types;

  factory PlacePrediction.fromMap(Map<String, dynamic> map) {
    return PlacePrediction(
      placeId: map['placeId'] as String? ?? '',
      primaryText: map['primaryText'] as String? ?? '',
      secondaryText: map['secondaryText'] as String? ?? '',
      fullText: map['fullText'] as String? ?? '',
      types: (map['types'] as List<dynamic>?)?.map((e) => '$e').toList() ?? const [],
    );
  }
}

/// Rich place payload from [getPlaceDetails].
class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    this.name,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.website,
    this.rating,
    this.userRatingsTotal,
    this.businessStatus,
    this.types = const [],
    this.weekdayText,
    this.addressComponents = const [],
  });

  final String placeId;
  final String? name;
  final String? formattedAddress;
  final List<AddressComponent> addressComponents;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final int? userRatingsTotal;
  final String? businessStatus;
  final List<String> types;
  final List<String>? weekdayText;

  factory PlaceDetails.fromMap(Map<String, dynamic> map) {
    return PlaceDetails(
      placeId: map['placeId'] as String? ?? '',
      name: map['name'] as String?,
      formattedAddress: map['formattedAddress'] as String?,
      addressComponents: (map['addressComponents'] as List<dynamic>?)
              ?.map((e) => AddressComponent.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      phoneNumber: map['phoneNumber'] as String?,
      website: map['website'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      userRatingsTotal: (map['userRatingsTotal'] as num?)?.toInt(),
      businessStatus: map['businessStatus'] as String?,
      types: (map['types'] as List<dynamic>?)?.map((e) => '$e').toList() ?? const [],
      weekdayText: (map['weekdayText'] as List<dynamic>?)?.map((e) => '$e').toList(),
    );
  }
}

/// Programmatic place autocomplete using the **Google Places SDK for Android**
/// and **Google Places SDK for iOS** (not the web Places API).
///
/// [apiKey] is optional when configured natively:
/// - **Android**: `com.google.android.geo.API_KEY` in `AndroidManifest.xml`
/// - **iOS**: `GMSApiKey` in `Info.plist`
///
/// You may still pass [apiKey] from Dart to override the native value.
///
/// [countryCode] is an optional ISO 3166-1 Alpha-2 bias (e.g. `"US"`).
///
/// [limit] is capped per platform (Android Autocomplete (New) returns at most
/// five suggestions per request).
Future<List<PlacePrediction>> searchPlace({
  required String query,
  String? apiKey,
  String? countryCode,
  int limit = 10,
}) async {
  final rows = await GooglePlacesFlutterPlatform.instance.searchPlace(
    query: query,
    apiKey: apiKey,
    countryCode: countryCode,
    limit: limit,
  );
  return rows.map(PlacePrediction.fromMap).toList();
}

/// Place Details for [placeId] using the native Places SDK field mask defined
/// in the plugin (name, address, location, phone, website, rating, hours, etc.).
Future<PlaceDetails> getPlaceDetails({
  required String placeId,
  String? apiKey,
}) async {
  final map = await GooglePlacesFlutterPlatform.instance.getPlaceDetails(
    placeId: placeId,
    apiKey: apiKey,
  );
  return PlaceDetails.fromMap(map);
}
