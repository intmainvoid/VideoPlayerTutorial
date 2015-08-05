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

    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blackColor()

        self.avPlayerLayer = AVPlayerLayer(player: avPlayer)
        self.view.layer.insertSublayer(avPlayerLayer, atIndex: 0)

        let url = NSURL(string: "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8");
        let playerItem = AVPlayerItem(URL: url)
        self.avPlayer.replaceCurrentItemWithPlayerItem(playerItem)
    }

    override func viewWillAppear(animated: Bool)
    {
        self.avPlayer.play()
    }

    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        self.avPlayerLayer.frame = self.view.bounds;
    }

    override func supportedInterfaceOrientations() -> Int
    {
        return Int(UIInterfaceOrientationMask.Landscape.rawValue)
    }

}

