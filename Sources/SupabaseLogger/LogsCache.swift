import Foundation

final class LogsCache<T: Codable> {

  private let isDebug: Bool
  private let maximumNumberOfLogsToPopAtOnce = 100

  private let queue = DispatchQueue(
    label: "co.binaryscraping.supabase-log-cache", attributes: .concurrent)
  private var cachedLogs: [T] = []

  func push(_ log: T) {
    queue.sync { self.cachedLogs.append(log) }
  }

  func push(_ logs: [T]) {
    queue.sync { self.cachedLogs.append(contentsOf: logs) }
  }

  func pop() -> [T] {
    var poppedLogs: [T] = []
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
        if isDebug {
          print("Error saving Logs cache.")
        }
      }
    }
  }

  private static func fileURL() throws -> URL {
    try FileManager.default.url(
      for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false
    )
    .appendingPathComponent("supabase-log-cache")
  }

  init(isDebug: Bool) {
    self.isDebug = isDebug
    do {
      let data = try Data(contentsOf: LogsCache.fileURL())
      try FileManager.default.removeItem(at: LogsCache.fileURL())

      let logs = try decoder.decode([T].self, from: data)
      self.cachedLogs = logs
    } catch {
      if isDebug {
        print("Error recovering logs from cache.")
      }
    }
  }
}
