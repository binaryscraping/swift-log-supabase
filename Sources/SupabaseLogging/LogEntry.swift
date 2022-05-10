import Foundation
import Logging

struct LogEntry: Codable {
  let label: String
  let file: String
  let line: String
  let source: String
  let function: String
  let level: String
  let message: String
  let loggedAt: Date
  let metadata: Logger.Metadata?
}

extension Logger.MetadataValue: Codable {

  public init(from decoder: Decoder) throws {
    if let string = try? decoder.singleValueContainer().decode(String.self) {
      self = .string(string)
    } else if let dictionary = try? decoder.singleValueContainer().decode(Logger.Metadata.self) {
      self = .dictionary(dictionary)
    } else if let array = try? decoder.singleValueContainer().decode([Logger.MetadataValue].self) {
      self = .array(array)
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unsupported \(Logger.MetadataValue.self) type."))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .stringConvertible(let value):
      try container.encode(value.description)
    case .dictionary(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    }
  }
}

private let dateFormatter = { () -> DateFormatter in
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  return formatter
}()

let decoder = { () -> JSONDecoder in
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .formatted(dateFormatter)
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return decoder
}()

let encoder = { () -> JSONEncoder in
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .formatted(dateFormatter)
  encoder.keyEncodingStrategy = .convertToSnakeCase
  return encoder
}()
