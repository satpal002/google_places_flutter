import Flutter
import GooglePlaces
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Matches Places SDK setup: provide the key at launch (before SDK use).
    Self.configurePlacesApiKeyFromInfoPlistIfPresent()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private static func configurePlacesApiKeyFromInfoPlistIfPresent() {
    let candidates = ["GMSApiKey", "apiKey"]
    for name in candidates {
      guard let raw = Bundle.main.object(forInfoDictionaryKey: name) as? String else { continue }
      let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !key.isEmpty else { continue }
      let upper = key.uppercased()
      if upper == "YOUR_PLACES_API_KEY" || upper == "YOUR_API_KEY" || upper == "<YOUR_API_KEY>" {
        continue
      }
      GMSPlacesClient.provideAPIKey(key)
      return
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
