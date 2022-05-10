import Foundation
import Logging

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

public struct SupabaseLogConfig: Hashable {
  let supabaseURL: String
  let supabaseAnonKey: String

  let table: String
  let isDebug: Bool

  public init(
    supabaseURL: String,
    supabaseAnonKey: String,
    table: String = "logs",
    isDebug: Bool = true
  ) {
    self.supabaseURL = supabaseURL
    self.supabaseAnonKey = supabaseAnonKey
    self.table = table
    #if DEBUG
      self.isDebug = isDebug
    #else
      self.isDebug = false
    #endif
  }
}

public struct SupabaseLogHandler: LogHandler {
  public var metadata: Logger.Metadata = [:]
  public var logLevel: Logger.Level = .debug

  public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get { metadata[key] }
    set { metadata[key] = newValue }
  }

  private let label: String
  private let logManager: SupabaseLogManager

  public init(label: String, config: SupabaseLogConfig) {
    self.label = label
    logManager = SupabaseLogManager.shared(config)
  }

  public func log(
    level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String,
    file: String, function: String, line: UInt
  ) {
    let entry = LogEntry(
      label: label, file: file, line: "\(line)", source: source, function: function,
      level: level.rawValue, message: message.description, loggedAt: Date(),
      metadata: self.metadata.merging(metadata ?? [:]) { $1 })

    logManager.log(entry)
  }
}

final class SupabaseLogManager {

  let cache: LogsCache<LogEntry>
  let config: SupabaseLogConfig

  private let minimumWaitTimeBetweenRequests: TimeInterval = 10
  private var sendTimer: Timer?

  private static let queue = DispatchQueue(
    label: "co.binaryscraping.supabase-log-manager.instances")
  private static var instances: [SupabaseLogConfig: SupabaseLogManager] = [:]

  static func shared(_ config: SupabaseLogConfig) -> SupabaseLogManager {
    queue.sync {
      if let manager = instances[config] {
        return manager
      }

      let manager = SupabaseLogManager(config: config)
      instances[config] = manager
      return manager
    }
  }

  private init(config: SupabaseLogConfig) {
    self.config = config
    self.cache = LogsCache(isDebug: config.isDebug)

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

    startTimer()
  }

  private func startTimer() {
    sendTimer?.invalidate()
    sendTimer = Timer.scheduledTimer(
      timeInterval: minimumWaitTimeBetweenRequests, target: self,
      selector: #selector(checkForLogsAndSend), userInfo: nil, repeats: true)

    // Fire the timer to attempt to send any cached logs from a previous session.
    checkForLogsAndSend()
  }

  func log(_ payload: LogEntry) {
    cache.push(payload)
  }

  @objc
  private func checkForLogsAndSend() {
    let logs = cache.pop()

    guard !logs.isEmpty else { return }

    let data = try! encoder.encode(logs)
    guard
      let url = URL(string: self.config.supabaseURL)?.appendingPathComponent(self.config.table)
    else {
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = data

    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = true
    let session = URLSession(configuration: config)

    session.dataTask(with: request) { _, response, error in
      do {
        if let error = error {
          throw error
        }

        guard
          let httpResponse = response as? HTTPURLResponse,
          200..<300 ~= httpResponse.statusCode
        else {
          throw URLError(.badServerResponse)
        }
      } catch {
        if self.config.isDebug {
          print(error)
        }

        // An error ocurred, put logs back in cache.
        self.cache.push(logs)
      }
    }
    .resume()
  }
}

extension SupabaseLogManager {
  @objc func appWillTerminate() {
    if config.isDebug {
      print(#function)
    }

    cache.backupCache()
  }

  #if os(iOS)
    @objc func didEnterForeground() {
      if config.isDebug {
        print(#function)
      }

      startTimer()
    }

    @objc func didEnterBackground() {
      if config.isDebug {
        print(#function)
      }

      sendTimer?.invalidate()
      sendTimer = nil

      cache.backupCache()
    }
  #endif
}
