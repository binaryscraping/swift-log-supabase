import Logging

public struct SupabaseLogHandler: LogHandler {

    public var metadata: Logger.Metadata = [:]

    public var logLevel: Logger.Level = .debug

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        var parameters = self.metadata
        if let metadata = metadata {
            parameters.merge(metadata) { _, new in new }
        }
        parameters["file"] = .string(file)
        parameters["line"] = .stringConvertible(line)
        parameters["source"] = .string(source)
        parameters["function"] = .string(function)
    }
}
