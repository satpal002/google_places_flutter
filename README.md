# places_sdk_flutter

Flutter plugin that wraps the [Places SDK for Android](https://developers.google.com/maps/documentation/places/android-sdk/overview) and [Places SDK for iOS](https://developers.google.com/maps/documentation/places/ios-sdk/overview). Requests run through the native SDKs (not the HTTP Places Web Service).

Published on pub.dev as **`places_sdk_flutter`** (the name `google_places_flutter` is already used by [another package](https://pub.dev/packages/google_places_flutter) that calls the HTTP API).

> **Disclaimer:** This is an unofficial package and is not affiliated with, endorsed by, or sponsored by Google.

## Setup

1. Enable **Places API (New)** in [Google Cloud Console](https://console.cloud.google.com/).
2. Create an API key and restrict it:
   - **Android**: package name + SHA-1
   - **iOS**: bundle identifier
3. Add the key to your app (recommended — no key in Dart):

   **Android** — inside `<application>` in `AndroidManifest.xml`:

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_PLACES_API_KEY" />
   ```

   **iOS** — in `Info.plist`:

   ```xml
   <key>GMSApiKey</key>
   <string>YOUR_PLACES_API_KEY</string>
   ```

4. Android: `minSdk` 24+ (plugin default). Uses `Places.initializeWithNewPlacesApiEnabled`.
5. iOS: deployment target **14.0+**. CocoaPods pulls `GooglePlaces` (~> 8.5).

## Usage

Add to `pubspec.yaml`:

```yaml
dependencies:
  places_sdk_flutter: ^0.0.1
```

```dart
import 'package:places_sdk_flutter/places_sdk_flutter.dart';

// Autocomplete (API key read from AndroidManifest / Info.plist)
final predictions = await searchPlace(
  query: 'coffee shop',
  countryCode: 'US', // optional ISO 3166-1 alpha-2
  limit: 5,
);

// Place details
final details = await getPlaceDetails(
  placeId: predictions.first.placeId,
);

print(details.name);
print(details.formattedAddress);
print(details.latitude);
```

## API

| Function | Native call |
|----------|-------------|
| `searchPlace` | Android: `findAutocompletePredictions` · iOS: `findAutocompletePredictions` |
| `getPlaceDetails` | Android: `fetchPlace` · iOS: `fetchPlace(fromPlaceID:)` |

Models: `PlacePrediction`, `PlaceDetails`.

## Example app

```bash
cd example
# Set YOUR_PLACES_API_KEY in example/android/.../AndroidManifest.xml
# and example/ios/Runner/Info.plist, then:
flutter run
```

## Notes

- Autocomplete (New) on Android returns **up to 5** predictions per request; `limit` only trims that list on the Dart side.
- Billing follows [Google Places SDK pricing](https://developers.google.com/maps/billing-and-pricing); the plugin requests a fixed field set for details (name, address, location, phone, website, rating, hours, types, etc.).
- Show [required attributions](https://developers.google.com/maps/documentation/places/ios-sdk/attributions) when displaying Google place data in your UI.
