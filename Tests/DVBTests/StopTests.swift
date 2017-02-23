import Foundation
import XCTest
@testable import DVB

class StopTests: XCTestCase {
    func testStopDescription() {
        let stop = Stop(id: "33000742", name: "Helmholtzstraße", region: nil, location: nil)
        XCTAssertEqual(stop.description, "Helmholtzstraße")
    }

    func testStopFromString() {
        let string = "33000742|||Helmholtzstraße|5655904|4621157|0||"
        // swiftlint:disable:next force_try
        let stop = try! Stop(string: string)

        XCTAssertEqual(stop.id, "33000742")
        XCTAssertEqual(stop.name, "Helmholtzstraße")
        XCTAssertEqual(stop.region, nil)
        XCTAssertEqual(stop.location?.latitude, 51.025570859830559)
        XCTAssertEqual(stop.location?.longitude, 13.72543580275704)
    }
}

#if os(Linux)
extension StopTests {
    static var allTests: [(String, (StopTests) -> () throws -> Void)] {
        return [
            ("testStopDescription", testStopDescription),
            ("testStopFromString", testStopFromString),
        ]
    }
}
#endif
