import XCTest
@testable import WuKongEasySDK

final class DeviceFlagTests: XCTestCase {
    func testRawValuesMatchWuKongIMProtocol() {
        XCTAssertEqual(DeviceFlag.app.rawValue, 0)
        XCTAssertEqual(DeviceFlag.web.rawValue, 1)
        XCTAssertEqual(DeviceFlag.desktop.rawValue, 2)
    }
}
