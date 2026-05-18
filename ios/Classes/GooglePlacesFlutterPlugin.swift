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

  private static let infoPlistApiKey = "GMSApiKey"

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
    guard let key = Bundle.main.object(forInfoDictionaryKey: infoPlistApiKey) as? String else {
      return nil
    }
    let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
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
          "apiKey is required: pass apiKey from Dart or set \(Self.infoPlistApiKey) in Info.plist"
      )
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
        self.mainError(result, code: "PLACE_SEARCH_FAILED", message: error.localizedDescription)
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
    var raw: UInt = 0
    func add(_ field: GMSPlaceField) {
      raw |= UInt(field.rawValue)
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

  private static func businessStatusString(_ status: GMSPlaceBusinessStatus) -> String {
    switch status {
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
          "apiKey is required: pass apiKey from Dart or set \(Self.infoPlistApiKey) in Info.plist"
      )
      return
    }

    provideApiKey(apiKey)
    let client = GMSPlacesClient.shared()
    let fields = detailPlaceFields()

    client.fetchPlace(fromPlaceID: placeId, placeFields: fields, sessionToken: nil) {
      (place: GMSPlace?, error: Error?) in
      if let error = error {
        self.mainError(result, code: "PLACE_DETAILS_FAILED", message: error.localizedDescription)
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
        "addressComponents": addressComponentsToList(place),
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
