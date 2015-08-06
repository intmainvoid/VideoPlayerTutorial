//
//  ViewController.swift
//  CustomVideoPlayer
//
//  Created by Gavin Conway on 05/08/2015.
//  Copyright (c) 2015 Binary Mosaic. All rights reserved.
//

import UIKit
import AVFoundation

let playbackLikelyToKeepUpContext = UnsafeMutablePointer<(Void)>()

class ViewController: UIViewController {

    var avPlayerView: UIView = UIView()
    var avPlayer: AVPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var invisibleButton: UIButton = UIButton()
    var timeRemainingLabel: UILabel = UILabel()
    var timeObserver: AnyObject!
    var seekSlider: UISlider = UISlider()
    var playerRateBeforeSeek: Float = 0
    var loadingIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)

    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blackColor()

        self.avPlayerLayer = AVPlayerLayer(player: avPlayer)
        self.view.layer.insertSublayer(avPlayerLayer, atIndex: 0)

        self.invisibleButton.addTarget(self, action: "invisibleButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(invisibleButton)

        let url = NSURL(string: "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8");
        let playerItem = AVPlayerItem(URL: url)
        self.avPlayer.replaceCurrentItemWithPlayerItem(playerItem)

        self.timeRemainingLabel.textColor = UIColor.whiteColor()
        self.view.addSubview(self.timeRemainingLabel);

        let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, 10)
        self.timeObserver = self.avPlayer.addPeriodicTimeObserverForInterval(timeInterval, queue: dispatch_get_main_queue()) { (elapsedTime: CMTime) -> Void in
            let duration = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
            if (isfinite(duration)) {
                let elapsedTime = CMTimeGetSeconds(elapsedTime)
                self.updateTimeLabel(elapsedTime, duration: duration)
                self.seekSlider.value = Float(elapsedTime / duration)
            }
        }

        self.view.addSubview(seekSlider)
        self.seekSlider.addTarget(self, action: "sliderBeganTracking:", forControlEvents: UIControlEvents.TouchDown)
        self.seekSlider.addTarget(self, action: "sliderEndedTracking:", forControlEvents: UIControlEvents.TouchUpInside | UIControlEvents.TouchUpOutside)
        self.seekSlider.addTarget(self, action: "sliderValueChanged:", forControlEvents: UIControlEvents.ValueChanged)

        self.loadingIndicatorView.hidesWhenStopped = true
        self.view.addSubview(self.loadingIndicatorView)
        self.avPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.New, context: playbackLikelyToKeepUpContext)
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
    {
        if (context == playbackLikelyToKeepUpContext) {
            if (self.avPlayer.currentItem.playbackLikelyToKeepUp) {
                self.loadingIndicatorView.stopAnimating()
            } else {
                self.loadingIndicatorView.startAnimating()
            }
        }
    }

    deinit
    {
        self.avPlayer.removeTimeObserver(self.timeObserver)
        self.avPlayer.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
    }

    override func viewWillAppear(animated: Bool)
    {
        self.loadingIndicatorView.startAnimating()
        self.avPlayer.play()
    }

    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()

        self.avPlayerLayer.frame = self.view.bounds;
        self.invisibleButton.frame = self.view.bounds;
        let controlsHeight: CGFloat = 30
        let controlsY = self.view.bounds.size.height - controlsHeight;
        self.timeRemainingLabel.frame = CGRectMake(0, controlsY, 60, controlsHeight)
        self.seekSlider.frame = CGRectMake(
            timeRemainingLabel.frame.origin.x + timeRemainingLabel.bounds.size.width,
            controlsY,
            self.view.bounds.size.width - self.timeRemainingLabel.bounds.size.width,
            controlsHeight)
        self.loadingIndicatorView.center = CGPointMake(
            CGRectGetMidX(self.view.bounds),
            CGRectGetMidY(self.view.bounds))
    }

    override func supportedInterfaceOrientations() -> Int
    {
        return Int(UIInterfaceOrientationMask.Landscape.rawValue)
    }

    func invisibleButtonTapped(sender: UIButton!)
    {
        var playerIsPlaying:Bool = self.avPlayer.rate > 0
        if (playerIsPlaying) {
            self.avPlayer.pause();
        } else {
            self.avPlayer.play();
        }
    }

    func sliderBeganTracking(slider: UISlider!)
    {
        self.playerRateBeforeSeek = self.avPlayer.rate
        self.avPlayer.pause()
    }

    func sliderEndedTracking(slider: UISlider!)
    {
        let videoDuration = CMTimeGetSeconds(self.avPlayer.currentItem.duration)
        let elapsedTime: Float64 = videoDuration * Float64(self.seekSlider.value)
        self.updateTimeLabel(elapsedTime, duration: videoDuration)
        self.avPlayer.seekToTime(CMTimeMakeWithSeconds(elapsedTime, 10), completionHandler: { (completed: Bool) -> Void in
            if (self.playerRateBeforeSeek > 0) {
                self.avPlayer.play()
            }
        })
    }

    func sliderValueChanged(slider: UISlider!)
    {
        let videoDuration = CMTimeGetSeconds(self.avPlayer.currentItem.duration)
        let elapsedTime: Float64 = videoDuration * Float64(self.seekSlider.value)
        self.updateTimeLabel(elapsedTime, duration: videoDuration)
    }

    func updateTimeLabel(elapsedTime: Float64, duration: Float64)
    {
        let timeRemaining: Float64 = CMTimeGetSeconds(self.avPlayer.currentItem.duration) - elapsedTime
        self.timeRemainingLabel.text = String(format: "%02.f:%02.f", (floor(timeRemaining / 60)) % 60, timeRemaining % 60)
    }

}

