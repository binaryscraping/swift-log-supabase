import Logging
import XCTest

@testable import SupabaseLogging

final class SupabaseLogHandlerTests: XCTestCase {
  func testLive() throws {
    LoggingSystem.bootstrap { label in
      MultiplexLogHandler(
        [
          StreamLogHandler.standardOutput(label: label),
          SupabaseLogHandler(
            label: label,
            config: SupabaseLogConfig(
              supabaseURL: Secrets.supabaseURL, supabaseAnonKey: Secrets.supabaseAnonKey,
              isDebug: true)
          ),
        ]
      )
    }

    let logger = Logger(label: "co.binaryscraping.supabase-log.tests")
    let metadata: Logger.Metadata = [
      "string": .string("string"),
      "integer": .stringConvertible(1),
      "array": .array([.string("a"), .string("b")]),
      "dictionary": .dictionary([
        "key": .string("value")
      ]),
    ]

    logger.critical("This is a critical message", metadata: metadata)
    logger.debug("This is a debug message", metadata: metadata)
    logger.error("This is an error message", metadata: metadata)
    logger.info("This is an info message", metadata: metadata)
    logger.notice("This is a notice message", metadata: metadata)
    logger.trace("This is a trace message", metadata: metadata)
    logger.warning("This is a warning message", metadata: metadata)

    let expectation = self.expectation(description: #function)

    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 20)
  }
}
