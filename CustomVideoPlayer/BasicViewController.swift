//
//  BasicViewController.swift
//  CustomVideoPlayer
//
//  Created by Gavin Conway on 06/08/2015.
//  Copyright (c) 2015 Binary Mosaic. All rights reserved.
//

import MediaPlayer

class BasicViewController: UIViewController
{
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)

        var movieController: MPMoviePlayerViewController = MPMoviePlayerViewController(
            contentURL: NSURL(string: "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8"))
        self.presentMoviePlayerViewControllerAnimated(movieController)
        movieController.moviePlayer.play()
    }
}
