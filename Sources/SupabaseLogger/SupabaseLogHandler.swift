import Foundation
import Logging

public struct SupabaseLogConfig {
  let supabaseURL: String
  let supabaseAnonKey: String

  let table: String

  public init(
    supabaseURL: String,
    supabaseAnonKey: String,
    table: String = "logs"
  ) {
    self.supabaseURL = supabaseURL
    self.supabaseAnonKey = supabaseAnonKey
    self.table = table
  }
}

public struct SupabaseLogHandler: LogHandler {

  public var metadata: Logger.Metadata = [:]

  public var logLevel: Logger.Level = .debug

  public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get { metadata[key] }
    set { metadata[key] = newValue }
  }

  private let logManager: SupabaseLogManager

  public init(config: SupabaseLogConfig) {
    logManager = SupabaseLogManager(config: config)
  }

  public func log(
    level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String,
    file: String, function: String, line: UInt
  ) {
    var parameters = self.metadata
    if let metadata = metadata {
      parameters.merge(metadata) { _, new in new }
    }
    parameters["file"] = .string(file)
    parameters["line"] = .stringConvertible(line)
    parameters["source"] = .string(source)
    parameters["function"] = .string(function)

    var payload: [String: Any] = [:]
    payload["level"] = level.rawValue
    payload["message"] = metadata?.description
    payload["metadata"] = parameters.mapValues(\.description)

    logManager.log(payload)
  }
}

final class SupabaseLogManager {

  let queue = DispatchQueue(label: "co.binaryscraping.supabase-log-manager", qos: .background)
  var payloads: [[String: Any]] = []
  let config: SupabaseLogConfig

  init(config: SupabaseLogConfig) {
    self.config = config
  }

  func log(_ payload: [String: Any]) {
    queue.async {
      self.payloads.append(payload)
    }
  }

  func uploadLogs() {
    queue.async {
      let data = try! JSONSerialization.data(withJSONObject: self.payloads)
      guard
        let url = URL(string: self.config.supabaseURL)?.appendingPathComponent(self.config.table)
      else {
        return
      }

      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.httpBody = data

      URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          print(error)
          return
        }

        self.payloads = []
      }.resume()
    }
  }
}
