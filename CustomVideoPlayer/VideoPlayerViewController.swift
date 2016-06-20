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

private var playbackLikelyToKeepUpContext = 0

class VideoPlayerViewController: UIViewController {
  let avPlayer = AVPlayer()
  var avPlayerLayer: AVPlayerLayer!
  let invisibleButton = UIButton()
  var timeObserver: AnyObject!
  let timeRemainingLabel = UILabel()
  let seekSlider = UISlider()
  var playerRateBeforeSeek: Float = 0
  let loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .blackColor()

    // An AVPlayerLayer is a CALayer instance to which the AVPlayer can
    // direct its visual output. Without it, the user will see nothing.
    avPlayerLayer = AVPlayerLayer(player: avPlayer)
    view.layer.insertSublayer(avPlayerLayer, atIndex: 0)

    view.addSubview(invisibleButton)
    invisibleButton.addTarget(self, action: #selector(invisibleButtonTapped), forControlEvents: .TouchUpInside)

    let url = NSURL(string: "https://content.jwplatform.com/manifests/vM7nH0Kl.m3u8")
    let playerItem = AVPlayerItem(URL: url!)
    avPlayer.replaceCurrentItemWithPlayerItem(playerItem)
    let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, 10)
    timeObserver = avPlayer.addPeriodicTimeObserverForInterval(timeInterval, queue: dispatch_get_main_queue()) { (elapsedTime: CMTime) -> Void in

      // print("elapsedTime now:", CMTimeGetSeconds(elapsedTime))
      self.observeTime(elapsedTime)
    }

    timeRemainingLabel.textColor = .whiteColor()
    view.addSubview(timeRemainingLabel)

    view.addSubview(seekSlider)
    seekSlider.addTarget(self, action: #selector(sliderBeganTracking), forControlEvents: .TouchDown)
    seekSlider.addTarget(self, action: #selector(sliderEndedTracking), forControlEvents: [.TouchUpInside, .TouchUpOutside])
    seekSlider.addTarget(self, action: #selector(sliderValueChanged), forControlEvents: .ValueChanged)

    loadingIndicatorView.hidesWhenStopped = true
    view.addSubview(loadingIndicatorView)
    avPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp", options: .New, context: &playbackLikelyToKeepUpContext)
  }

  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

    if context == &playbackLikelyToKeepUpContext {
      if avPlayer.currentItem!.playbackLikelyToKeepUp {
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
    avPlayerLayer.frame = view.bounds
    invisibleButton.frame = view.bounds
    let controlsHeight: CGFloat = 30
    let controlsY: CGFloat = view.bounds.size.height - controlsHeight
    timeRemainingLabel.frame = CGRect(x: 5, y: controlsY, width: 60, height: controlsHeight)
    seekSlider.frame = CGRect(x: timeRemainingLabel.frame.origin.x + timeRemainingLabel.bounds.size.width,
        y: controlsY, width: view.bounds.size.width - timeRemainingLabel.bounds.size.width - 5, height: controlsHeight)
    loadingIndicatorView.center = CGPoint(x: CGRectGetMidX(view.bounds), y: CGRectGetMidY(view.bounds))
  }

  // Force the view into landscape mode (which is how most video media is consumed.)
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.Landscape
  }

  func invisibleButtonTapped(sender: UIButton) {
    let playerIsPlaying = avPlayer.rate > 0
    if playerIsPlaying {
      avPlayer.pause()
    } else {
      avPlayer.play()
    }
  }

  func sliderBeganTracking(slider: UISlider) {
    playerRateBeforeSeek = avPlayer.rate
    avPlayer.pause()
  }

  func sliderEndedTracking(slider: UISlider) {
    let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
    let elapsedTime: Float64 = videoDuration * Float64(seekSlider.value)
    updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)

    avPlayer.seekToTime(CMTimeMakeWithSeconds(elapsedTime, 100)) { (completed: Bool) -> Void in
      if self.playerRateBeforeSeek > 0 {
        self.avPlayer.play()
      }
    }
  }

  func sliderValueChanged(slider: UISlider) {
    let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
    let elapsedTime: Float64 = videoDuration * Float64(seekSlider.value)
    updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
  }

  private func updateTimeLabel(elapsedTime elapsedTime: Float64, duration: Float64) {
    let timeRemaining: Float64 = CMTimeGetSeconds(avPlayer.currentItem!.duration) - elapsedTime
    timeRemainingLabel.text = String(format: "%02d:%02d", ((lround(timeRemaining) / 60) % 60), lround(timeRemaining) % 60)
  }

  private func observeTime(elapsedTime: CMTime) {
    let duration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
    if isfinite(duration) {
      let elapsedTime = CMTimeGetSeconds(elapsedTime)
      updateTimeLabel(elapsedTime: elapsedTime, duration: duration)
    }
  }

}
