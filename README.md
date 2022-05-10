# swift-log-supabase

A logging backend for [apple/swift-log](https://github.com/apple/swift-log) that sends log entries to [Supabase](https://github.com/supabase/supabase).

## Getting Started

Add `swift-log-supabase` as a dependency to your project using SPM.

```swift
.package(url: "https://github.com/binaryscraping/swift-log-supabase", from: "0.1.0"),
```

And in your application/target, add `"SupabaseLogging"` to your `"dependencies"`.

```swift
.target(
  name: "YourTarget",
  dependencies: [
    .product(name: "SupabaseLogging", package: "swift-log-supabase"),
  ]
)
```

## Usage

Start by creating the logs table on Supabase dashboard by running the [supabase-init.sql](/supabase-init.sql) script on Supabase SQL Editor.

During app startup/initialization.

```swift
import Logging
import SupabaseLogging

LoggingSystem.bootstrap { label in 
  SupabaseLogHandler(
    label: label,
    config: SupabaseLogConfig(
      table: "logs", // optional table name to use, defaults to "logs".
      supabaseURL: "https://your-supabase-project-url.com/rest/v1",
      supabaseAnonKey: "your-supabase-anon-key",
      isDebug: true // optional flag to turn on/off internal logging, defaults to "false".
    )
  )
}

let logger = Logger(label: "co.binaryscraping.swift-log-supabase")
logger.info("Supabase is super cool")
```

For more details on all the features of the Swift Logging API, check out the [swift-log](https://github.com/apple/swift-log) repo.
