//
//  ViewController.swift
//  FrameExtraction
//
//  Created by admin on 2020. 10. 08..
//  Copyright © 2020. admin. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, FrameExtractorDelegate {

    @IBOutlet weak var imageView: UIImageView!
    var frameExtractor: FrameExtractor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
    }

    func captured(image: UIImage) {
        imageView.image = image
    }
    
}

