//
//  ViewController.swift
//  CustomVideoPlayer
//
//  Created by Gavin Conway on 05/08/2015.
//  Copyright (c) 2015 Binary Mosaic. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var avPlayerView: UIView = UIView();
    var avPlayer: AVPlayer = AVPlayer();
    var avPlayerLayer: AVPlayerLayer!
    var invisibleButton: UIButton = UIButton();
    var timeRemainingLabel: UILabel = UILabel();
    var timeObserver: AnyObject!;

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
                let timeRemaining = CMTimeGetSeconds(self.avPlayer.currentItem.duration) - CMTimeGetSeconds(elapsedTime)
                self.timeRemainingLabel.text = String(format: "%02.f:%02.f", (floor(timeRemaining / 60)) % 60, timeRemaining % 60)
            }
        }
    }

    deinit
    {
        self.avPlayer.removeTimeObserver(self.timeObserver)
    }

    override func viewWillAppear(animated: Bool)
    {
        self.avPlayer.play()
    }

    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        self.avPlayerLayer.frame = self.view.bounds;
        self.invisibleButton.frame = self.view.bounds;
        let timeRemainingLabelY = self.view.bounds.size.height - 25;
        self.timeRemainingLabel.frame = CGRectMake(0, timeRemainingLabelY, 60, 25)
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

}

