import Cocoa
import AVFoundation
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let openFileChannelName = "free_macos_player/open_file"
  private let fileAccessChannelName = "free_macos_player/file_access"
  private let thumbnailChannelName = "free_macos_player/thumbnail"
  private var pendingOpenFiles: [String] = []
  private var openFileChannel: FlutterMethodChannel?
  private var fileAccessChannel: FlutterMethodChannel?
  private var thumbnailChannel: FlutterMethodChannel?

  func registerFlutterViewController(_ flutterViewController: FlutterViewController) {
    let messenger = flutterViewController.engine.binaryMessenger
    registerOpenFileChannel(messenger)
    registerFileAccessChannel(messenger)
    registerThumbnailChannel(messenger)
  }

  private func registerOpenFileChannel(_ messenger: FlutterBinaryMessenger) {
    if openFileChannel != nil {
      return
    }
    let channel = FlutterMethodChannel(
      name: openFileChannelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takePendingOpenFiles" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let files = self?.pendingOpenFiles ?? []
      self?.pendingOpenFiles.removeAll()
      result(files)
    }
    openFileChannel = channel

    for path in pendingOpenFiles {
      channel.invokeMethod("openFile", arguments: path)
    }
    pendingOpenFiles.removeAll()
  }

  private func registerFileAccessChannel(_ messenger: FlutterBinaryMessenger) {
    if fileAccessChannel != nil {
      return
    }

    let channel = FlutterMethodChannel(
      name: fileAccessChannelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "createBookmark":
        self?.createBookmark(call: call, result: result)
      case "startAccessing":
        self?.startAccessing(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    fileAccessChannel = channel
  }

  private func createBookmark(call: FlutterMethodCall, result: FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String
    else {
      result(FlutterError(
        code: "invalid_arguments",
        message: "path is required",
        details: nil
      ))
      return
    }

    do {
      let url = URL(fileURLWithPath: path)
      let bookmark = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      result(bookmark.base64EncodedString())
    } catch {
      result(FlutterError(
        code: "bookmark_failed",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }

  private func startAccessing(call: FlutterMethodCall, result: FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let bookmarkValue = arguments["bookmark"] as? String,
      let bookmark = Data(base64Encoded: bookmarkValue)
    else {
      result(FlutterError(
        code: "invalid_arguments",
        message: "bookmark is required",
        details: nil
      ))
      return
    }

    do {
      var stale = false
      let url = try URL(
        resolvingBookmarkData: bookmark,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )

      guard url.startAccessingSecurityScopedResource() else {
        result(FlutterError(
          code: "access_denied",
          message: "Could not access security scoped resource",
          details: nil
        ))
        return
      }

      var response: [String: Any] = ["path": url.path]
      if stale {
        let renewedBookmark = try url.bookmarkData(
          options: .withSecurityScope,
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        response["bookmark"] = renewedBookmark.base64EncodedString()
      }
      result(response)
    } catch {
      result(FlutterError(
        code: "access_failed",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }

  private func registerThumbnailChannel(_ messenger: FlutterBinaryMessenger) {
    if thumbnailChannel != nil {
      return
    }

    let channel = FlutterMethodChannel(
      name: thumbnailChannelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "generate" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let sourcePath = arguments["sourcePath"] as? String,
        let outputPath = arguments["outputPath"] as? String
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "sourcePath and outputPath are required",
          details: nil
        ))
        return
      }

      self?.generateThumbnail(
        sourcePath: sourcePath,
        outputPath: outputPath,
        result: result
      )
    }
    thumbnailChannel = channel
  }

  private func generateThumbnail(
    sourcePath: String,
    outputPath: String,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let outputURL = URL(fileURLWithPath: outputPath)
        let asset = AVAsset(url: sourceURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 960, height: 540)

        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let preferredSecond = durationSeconds.isFinite && durationSeconds > 2
          ? min(2.0, durationSeconds * 0.2)
          : 0.2
        let time = CMTime(seconds: preferredSecond, preferredTimescale: 600)
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let image = NSImage(
          cgImage: cgImage,
          size: NSSize(width: cgImage.width, height: cgImage.height)
        )

        guard
          let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let jpegData = bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: NSNumber(value: 0.82)]
          )
        else {
          throw NSError(
            domain: "free_macos_player.thumbnail",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to encode thumbnail"]
          )
        }

        try FileManager.default.createDirectory(
          at: outputURL.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )
        try jpegData.write(to: outputURL, options: .atomic)

        DispatchQueue.main.async {
          result(outputPath)
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "thumbnail_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    for path in filenames {
      if let channel = openFileChannel {
        channel.invokeMethod("openFile", arguments: path)
      } else {
        pendingOpenFiles.append(path)
      }
    }
    sender.reply(toOpenOrPrint: .success)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
