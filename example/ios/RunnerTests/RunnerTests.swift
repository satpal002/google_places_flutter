import Flutter
import UIKit
import XCTest

@testable import places_sdk_flutter

class RunnerTests: XCTestCase {
  func testPluginTypeExists() {
    XCTAssertNotNil(GooglePlacesFlutterPlugin.self)
  }
}
