//
//  TwilioVideoManager.swift
//  DemoTwilioVideo
//
//  Created by Duy Tran N. VN.Danang on 2/22/22.
//

import Foundation
import TwilioVideo

final class TwilioVideoManager {

    let accessToken: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzI1ZjY1MzQ0MmQxYmM0NzVjNDNmYjczODVlYWZkZTFkLTE2NDU3NjE3MTYiLCJncmFudHMiOnsiaWRlbnRpdHkiOiIxNWU0NTdlMi03NTJlLTQzOWMtOWJiZS04NDliNGMxNWQwZmNEdXkgaU9TIiwidmlkZW8iOnt9fSwiaWF0IjoxNjQ1NzYxNzE2LCJleHAiOjE2NDU3NjUzMTYsImlzcyI6IlNLMjVmNjUzNDQyZDFiYzQ3NWM0M2ZiNzM4NWVhZmRlMWQiLCJzdWIiOiJBQzM4YTg2MjM2YWU0ZWI2YjVhMmFlOTZkNmQzNDI3YmZmIn0.0CDwjgw4uBLomcQAEOCI4vQEvv9fpbFs7i1_SPCYuH0"
    let roomName = "22daf166-2adf-4e26-af8e-1806033814c2"

    // MARK: - Singleton
    static let shared = TwilioVideoManager()

    // MARK: - Properties
    // Create an audio track
    var localAudioTrack: LocalAudioTrack?

    // Create a data track
    let localDataTrack = LocalDataTrack()

    // Create a CameraSource to provide content for the video track
    var localVideoTrack: LocalVideoTrack?

    var cameraSource: CameraSource?

//    func createRoom() {
//        let connectOptions = ConnectOptions(token: TwilioVideoManager.accessToken) { builder in
//            builder.roomName = "my-room"
//        }
//        let room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)
//    }
}
