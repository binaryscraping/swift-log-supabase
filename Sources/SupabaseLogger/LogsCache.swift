import Foundation

final class LogsCache {

  private let maximumNumberOfLogsToPopAtOnce = 100

  private let queue = DispatchQueue(
    label: "co.binaryscraping.supabase-log-cache", attributes: .concurrent)
  private var cachedLogs: [[String: Any]] = []

  func push(_ log: [String: Any]) {
    queue.sync { self.cachedLogs.append(log) }
  }

  func push(_ logs: [[String: Any]]) {
    queue.sync { self.cachedLogs.append(contentsOf: logs) }
  }

  func pop() -> [[String: Any]] {
    var poppedLogs: [[String: Any]] = []
    queue.sync(flags: .barrier) {
      let sliceSize = min(maximumNumberOfLogsToPopAtOnce, cachedLogs.count)
      poppedLogs = Array(cachedLogs[..<sliceSize])
      cachedLogs.removeFirst(sliceSize)
    }
    return poppedLogs
  }

  func backupCache() {
    queue.sync(flags: .barrier) {
      do {
        let data = try JSONSerialization.data(withJSONObject: cachedLogs)
        try data.write(to: LogsCache.fileURL())
        self.cachedLogs = []
      } catch {
        print("Error saving Logs cache.")
      }
    }
  }

  private static func fileURL() -> URL {
    try! FileManager.default.url(
      for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false
    )
    .appendingPathComponent("supabase-log-cache")
  }

  init() {
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
