import Flutter
import UIKit
import GooglePlaces

public class GooglePlacesFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "places_sdk_flutter",
      binaryMessenger: registrar.messenger())
    let instance = GooglePlacesFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "searchPlace":
      handleSearchPlace(call, result: result)
    case "getPlaceDetails":
      handleGetPlaceDetails(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Standard Google Maps / Places Info.plist key (host app).
  private static let infoPlistApiKey = "GMSApiKey"
  /// Fallback plist key if `GMSApiKey` is absent.
  private static let infoPlistApiKeyAlternate = "apiKey"

  private func provideApiKey(_ key: String) {
    GMSPlacesClient.provideAPIKey(key)
  }

  private func resolveApiKey(_ args: [String: Any]) -> String? {
    if let key = args["apiKey"] as? String {
      let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
    }
    return Self.readApiKeyFromInfoPlist()
  }

  private static func readApiKeyFromInfoPlist() -> String? {
    for plistKey in [infoPlistApiKey, infoPlistApiKeyAlternate] {
      guard let key = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String else {
        continue
      }
      let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
    }
    return nil
  }

  /// README / example plist placeholders — not usable keys.
  private static func invalidResolvedApiKeyReason(_ key: String) -> String? {
    let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
    let upper = trimmed.uppercased()
    let placeholders: Set<String> = [
      "YOUR_PLACES_API_KEY",
      "YOUR_API_KEY",
      "<YOUR_API_KEY>",
      "REPLACE_ME",
    ]
    guard placeholders.contains(upper) else { return nil }
    return "GMSApiKey is still a placeholder (\(trimmed)). Replace it with a real key from Google Cloud Console (Credentials), or pass apiKey from Dart."
  }

  /// Google often returns \"invalid API key\" for restriction / wrong API issues too.
  private static func augmentedSdkErrorMessage(_ message: String) -> String {
    let lower = message.lowercased()
    let looksKeyRelated =
      lower.contains("api key") || (lower.contains("invalid") && lower.contains("key"))
    guard looksKeyRelated else { return message }
    return message
      + " — In Google Cloud Console: enable Places API (New) and billing; under Credentials, either remove Application restrictions temporarily or add an iOS apps restriction whose bundle ID matches the Runner target exactly."
  }

  private func mainResult(_ result: @escaping FlutterResult, value: Any?) {
    DispatchQueue.main.async {
      result(value)
    }
  }

  private func mainError(
    _ result: @escaping FlutterResult,
    code: String,
    message: String?
  ) {
    DispatchQueue.main.async {
      result(FlutterError(code: code, message: message, details: nil))
    }
  }

  private func handleSearchPlace(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let query = (args["query"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !query.isEmpty
    else {
      mainError(result, code: "INVALID_ARGUMENT", message: "query is required")
      return
    }

    guard let apiKey = resolveApiKey(args) else {
      mainError(
        result,
        code: "INVALID_ARGUMENT",
        message:
          "apiKey is required: pass apiKey from Dart or set \(Self.infoPlistApiKey) (or \(Self.infoPlistApiKeyAlternate)) in Info.plist"
      )
      return
    }

    if let msg = Self.invalidResolvedApiKeyReason(apiKey) {
      mainError(result, code: "INVALID_ARGUMENT", message: msg)
      return
    }

    let countryRaw = (args["countryCode"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .uppercased()
    let limit = min(max((args["limit"] as? Int) ?? 10, 1), 20)

    provideApiKey(apiKey)
    let client = GMSPlacesClient.shared()
    let filter = GMSAutocompleteFilter()
    if let country = countryRaw, !country.isEmpty {
      filter.countries = [country]
    }

    client.findAutocompletePredictions(
      fromQuery: query,
      filter: filter,
      sessionToken: nil
    ) { predictions, error in
      if let error = error {
        let msg = Self.augmentedSdkErrorMessage(error.localizedDescription)
        self.mainError(result, code: "PLACE_SEARCH_FAILED", message: msg)
        return
      }
      let preds = predictions ?? []
      let sliced = preds.prefix(limit)
      let out: [[String: Any?]] = sliced.map { p in
        [
          "placeId": p.placeID,
          "primaryText": p.attributedPrimaryText.string,
          "secondaryText": p.attributedSecondaryText?.string ?? "",
          "fullText": p.attributedFullText.string,
          "types": p.types,
        ]
      }
      self.mainResult(result, value: out)
    }
  }

  private func detailPlaceFields() -> GMSPlaceField {
    var raw: UInt64 = 0
    func add(_ field: GMSPlaceField) {
      raw |= field.rawValue
    }
    add(.name)
    add(.placeID)
    add(.formattedAddress)
    add(.addressComponents)
    add(.coordinate)
    add(.phoneNumber)
    add(.website)
    add(.rating)
    add(.userRatingsTotal)
    add(.openingHours)
    add(.utcOffsetMinutes)
    add(.businessStatus)
    add(.types)
    return GMSPlaceField(rawValue: raw)
  }

  private static func businessStatusString(_ status: GMSPlacesBusinessStatus) -> String {
    switch status {
    case .unknown:
      return "UNKNOWN"
    case .operational:
      return "OPERATIONAL"
    case .closedTemporarily:
      return "CLOSED_TEMPORARILY"
    case .closedPermanently:
      return "CLOSED_PERMANENTLY"
    @unknown default:
      return String(describing: status)
    }
  }

  private func addressComponentsToList(_ place: GMSPlace) -> [[String: Any?]] {
    guard let components = place.addressComponents else { return [] }
    return components.map { component in
      [
        "long_name": component.name,
        "short_name": component.shortName ?? component.name,
        "types": component.types,
      ]
    }
  }

  private func handleGetPlaceDetails(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let placeId = (args["placeId"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !placeId.isEmpty
    else {
      mainError(result, code: "INVALID_ARGUMENT", message: "placeId is required")
      return
    }

    guard let apiKey = resolveApiKey(args) else {
      mainError(
        result,
        code: "INVALID_ARGUMENT",
        message:
          "apiKey is required: pass apiKey from Dart or set \(Self.infoPlistApiKey) (or \(Self.infoPlistApiKeyAlternate)) in Info.plist"
      )
      return
    }

    if let msg = Self.invalidResolvedApiKeyReason(apiKey) {
      mainError(result, code: "INVALID_ARGUMENT", message: msg)
      return
    }

    provideApiKey(apiKey)
    let client = GMSPlacesClient.shared()
    let fields = detailPlaceFields()

    client.fetchPlace(fromPlaceID: placeId, placeFields: fields, sessionToken: nil) {
      (place: GMSPlace?, error: Error?) in
      if let error = error {
        let msg = Self.augmentedSdkErrorMessage(error.localizedDescription)
        self.mainError(result, code: "PLACE_DETAILS_FAILED", message: msg)
        return
      }
      guard let place = place else {
        self.mainError(result, code: "PLACE_DETAILS_EMPTY", message: "No place in response")
        return
      }

      let coord = place.coordinate
      let weekdayText = place.openingHours?.weekdayText

      let map: [String: Any?] = [
        "placeId": place.placeID,
        "name": place.name,
        "formattedAddress": place.formattedAddress,
        "addressComponents": self.addressComponentsToList(place),
        "latitude": coord.latitude,
        "longitude": coord.longitude,
        "phoneNumber": place.phoneNumber,
        "website": place.website?.absoluteString,
        "rating": place.rating,
        "userRatingsTotal": Int(place.userRatingsTotal),
        "businessStatus": Self.businessStatusString(place.businessStatus),
        "types": place.types,
        "weekdayText": weekdayText,
      ]
      self.mainResult(result, value: map)
    }
  }
}
