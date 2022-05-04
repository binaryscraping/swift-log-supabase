import Foundation
import Logging

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

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

  let cache: LogsCache
  let config: SupabaseLogConfig

  init(config: SupabaseLogConfig) {
    self.config = config
    self.cache = LogsCache.shared

    #if os(macOS)
      NotificationCenter.default.addObserver(
        self, selector: #selector(appWillTerminate), name: NSApplication.willTerminateNotification,
        object: nil)
    #elseif os(iOS)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        // We need to use a delay with these type of notifications because they fire on app load which causes a double load of the cache from disk
        NotificationCenter.default.addObserver(
          self, selector: #selector(self.didEnterForeground),
          name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(
          self, selector: #selector(self.didEnterBackground),
          name: UIApplication.didEnterBackgroundNotification, object: nil)
      }
    #endif
  }

  func log(_ payload: [String: Any]) {
    Task { await cache.push(payload) }
  }

  private func checkForLogsAndSend() {
    Task {
      let logs = await cache.pop()
      if logs.isEmpty { return }

      let data = try! JSONSerialization.data(withJSONObject: logs)
      guard
        let url = URL(string: self.config.supabaseURL)?.appendingPathComponent(self.config.table)
      else {
        return
      }

      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.httpBody = data

      do {
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
          if 200..<300 ~= httpResponse.statusCode {
            return
          }

          await cache.push(logs)
        }
      } catch {
        await cache.push(logs)
      }
    }
  }
}

extension SupabaseLogManager {
  @objc func appWillTerminate() {
    Task { await cache.backupCache() }
  }

  #if os(iOS)
    @objc func didEnterForeground() {
    }

    @objc func didEnterBackground() {
      Task {
        await cache.backupCache()
      }
    }
  #endif
}
