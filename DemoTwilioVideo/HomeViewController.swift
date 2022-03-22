//
//  HomeViewController.swift
//  DemoTwilioVideo
//
//  Created by Duy Tran N. VN.Danang on 2/22/22.
//

import UIKit
import AVFoundation

final class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        requestCameraAccess()
        requestAudioAccess()
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { isAllowed in
            print("🍀 \(#function) \(isAllowed)")
        }
    }

    private func requestAudioAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { isAllowed in
            print("🍀 \(#function) \(isAllowed)")
        }
    }
}
