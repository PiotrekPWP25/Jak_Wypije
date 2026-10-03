import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Opens Google Maps / Safari without an extra Flutter package.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ExternalLauncher") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "pl.hackyeah.jakwypije/external",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "openUrl",
            let args = call.arguments as? [String: Any],
            let value = args["url"] as? String,
            let url = URL(string: value) else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.open(url) { opened in result(opened) }
    }
  }
}
