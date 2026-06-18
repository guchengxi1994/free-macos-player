import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let openFileChannelName = "free_macos_player/open_file"
  private var pendingOpenFiles: [String] = []
  private var openFileChannel: FlutterMethodChannel?

  func registerFlutterViewController(_ flutterViewController: FlutterViewController) {
    if openFileChannel != nil {
      return
    }

    let channel = FlutterMethodChannel(
      name: openFileChannelName,
      binaryMessenger: flutterViewController.engine.binaryMessenger
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
