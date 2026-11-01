import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  var backgroundAudioPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 1. Configure audio session for background execution
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
      try audioSession.setActive(true)
    } catch {
      print("[AppDelegate] AudioSession setup error: \(error)")
    }

    // 2. Start looping silent audio track to prevent iOS background suspension
    startBackgroundAudioKeepAlive()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func startBackgroundAudioKeepAlive() {
    guard let soundURL = Bundle.main.url(forResource: "silence", withExtension: "wav") else {
      print("[AppDelegate] silence.wav not found in main bundle")
      return
    }

    do {
      backgroundAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      backgroundAudioPlayer?.numberOfLoops = -1 // Infinite loop
      backgroundAudioPlayer?.volume = 0.01 // Inaudible
      backgroundAudioPlayer?.prepareToPlay()
      backgroundAudioPlayer?.play()
      print("[AppDelegate] Native background audio keep-alive started successfully.")
    } catch {
      print("[AppDelegate] Could not start native background audio: \(error)")
    }
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    // Guarantee background audio is running when user locks phone or switches app
    if backgroundAudioPlayer == nil || !(backgroundAudioPlayer?.isPlaying ?? false) {
      startBackgroundAudioKeepAlive()
    }
  }
}
