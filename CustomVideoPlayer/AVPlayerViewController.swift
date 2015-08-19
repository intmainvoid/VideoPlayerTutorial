/*
* Copyright (c) 2015 Binary Mosaic
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import AVFoundation

let playbackLikelyToKeepUpContext = UnsafeMutablePointer<(Void)>()

class AVPlayerViewController: UIViewController {
  var avPlayer = AVPlayer()
  var avPlayerLayer: AVPlayerLayer!
  var invisibleButton = UIButton()
  var timeObserver: AnyObject!
  var timeRemainingLabel = UILabel()
  var seekSlider = UISlider()
  var playerRateBeforeSeek: Float = 0.0
  var loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.blackColor()

    // An AVPlayerLayer is a CALayer instance to which the AVPlayer can
    // direct its visual output. Without it, the user will see nothing.
    avPlayerLayer = AVPlayerLayer(player: avPlayer)
    view.layer.insertSublayer(avPlayerLayer, atIndex: 0)

    view.addSubview(invisibleButton)
    invisibleButton.addTarget(self, action: "invisibleButtonTapped:",
        forControlEvents: UIControlEvents.TouchUpInside)

    let url = NSURL(string: "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8");
    let playerItem = AVPlayerItem(URL: url)
    avPlayer.replaceCurrentItemWithPlayerItem(playerItem)

    let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, 10)
    timeObserver = avPlayer.addPeriodicTimeObserverForInterval(timeInterval,
        queue: dispatch_get_main_queue()) { (elapsedTime: CMTime) -> Void in

      // NSLog("elapsedTime now %f", CMTimeGetSeconds(elapsedTime));
      self.observeTime(elapsedTime)
    }

    timeRemainingLabel.textColor = UIColor.whiteColor()
    view.addSubview(timeRemainingLabel);

    view.addSubview(seekSlider)
    seekSlider.addTarget(self, action: "sliderBeganTracking:",
        forControlEvents: UIControlEvents.TouchDown)
    seekSlider.addTarget(self, action: "sliderEndedTracking:",
        forControlEvents: UIControlEvents.TouchUpInside | UIControlEvents.TouchUpOutside)
    seekSlider.addTarget(self, action: "sliderValueChanged:",
        forControlEvents: UIControlEvents.ValueChanged)

    loadingIndicatorView.hidesWhenStopped = true
    view.addSubview(loadingIndicatorView)
    avPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp",
        options: NSKeyValueObservingOptions.New, context: playbackLikelyToKeepUpContext)
  }

  override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject,
      change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {

    if (context == playbackLikelyToKeepUpContext) {
      if (avPlayer.currentItem.playbackLikelyToKeepUp) {
        loadingIndicatorView.stopAnimating()
      } else {
        loadingIndicatorView.startAnimating()
      }
    }
  }

  deinit {
    avPlayer.removeTimeObserver(timeObserver)
    avPlayer.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    loadingIndicatorView.startAnimating()
    avPlayer.play() // Start the playback
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    // Layout subviews manually
    avPlayerLayer.frame = view.bounds;
    invisibleButton.frame = view.bounds;
    let controlsHeight: CGFloat = 30
    let controlsY: CGFloat = view.bounds.size.height - controlsHeight;
    timeRemainingLabel.frame = CGRect(x: 5, y: controlsY, width: 60, height: controlsHeight)
    seekSlider.frame = CGRect(x: timeRemainingLabel.frame.origin.x + timeRemainingLabel.bounds.size.width,
      y: controlsY, width: view.bounds.size.width - timeRemainingLabel.bounds.size.width - 5, height: controlsHeight)
    loadingIndicatorView.center = CGPoint(x: CGRectGetMidX(view.bounds), y: CGRectGetMidY(view.bounds))
  }

  // Force the view into landscape mode (which is how most video media is consumed.)
  override func supportedInterfaceOrientations() -> Int {
    return Int(UIInterfaceOrientationMask.Landscape.rawValue)
  }

  func invisibleButtonTapped(sender: UIButton!) {
    var playerIsPlaying:Bool = avPlayer.rate > 0
    if (playerIsPlaying) {
      avPlayer.pause();
    } else {
      avPlayer.play();
    }
  }

  func sliderBeganTracking(slider: UISlider!) {
    playerRateBeforeSeek = avPlayer.rate
    avPlayer.pause()
  }

  func sliderEndedTracking(slider: UISlider!) {
    let videoDuration = CMTimeGetSeconds(avPlayer.currentItem.duration)
    let elapsedTime: Float64 = videoDuration * Float64(seekSlider.value)
    updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)

    avPlayer.seekToTime(CMTimeMakeWithSeconds(elapsedTime, 10)) { (completed: Bool) -> Void in
      if (self.playerRateBeforeSeek > 0) {
        self.avPlayer.play()
      }
    }
  }

  func sliderValueChanged(slider: UISlider!) {
    let videoDuration = CMTimeGetSeconds(avPlayer.currentItem.duration)
    let elapsedTime: Float64 = videoDuration * Float64(seekSlider.value)
    updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
  }

  private func updateTimeLabel(#elapsedTime: Float64, duration: Float64) {
    let timeRemaining: Float64 = CMTimeGetSeconds(avPlayer.currentItem.duration) - elapsedTime
    timeRemainingLabel.text = String(format: "%02.f:%02.f", (floor(timeRemaining / 60)) % 60, timeRemaining % 60)
  }

  private func observeTime(elapsedTime: CMTime) {
    let duration = CMTimeGetSeconds(avPlayer.currentItem.duration);
    if (isfinite(duration)) {
      let elapsedTime = CMTimeGetSeconds(elapsedTime)
      updateTimeLabel(elapsedTime: elapsedTime, duration: duration)
      seekSlider.value = Float(elapsedTime / duration)
    }
  }
}

