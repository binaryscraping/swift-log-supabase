import Foundation

actor LogsCache {

  private let maximumNumberOfLogsToPopAtOnce = 100

  private var cachedLogs: [[String: Any]] = []

  func push(_ log: [String: Any]) {
    cachedLogs.append(log)
  }

  func push(_ logs: [[String: Any]]) {
    cachedLogs.append(contentsOf: logs)
  }

  func pop() -> [[String: Any]] {
    let sliceSize = min(maximumNumberOfLogsToPopAtOnce, cachedLogs.count)
    let poppedLogs = Array(cachedLogs[..<sliceSize])
    cachedLogs.removeFirst(sliceSize)
    return poppedLogs
  }

  func backupCache() {
    do {
      let data = try JSONSerialization.data(withJSONObject: cachedLogs)
      try data.write(to: LogsCache.fileURL())
      self.cachedLogs = []
    } catch {
      print("Error saving Logs cache.")
    }
  }

  private static func fileURL() -> URL {
    try! FileManager.default.url(
      for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false
    )
    .appendingPathComponent("supabase-log-cache")
  }

  static let shared = LogsCache()

  private init() {
    do {
      let data = try Data(contentsOf: LogsCache.fileURL())
      try FileManager.default.removeItem(at: LogsCache.fileURL())

      let logs = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
      self.cachedLogs = logs
    } catch {
      print("Error recovering logs from cache.")
    }
  }
}
