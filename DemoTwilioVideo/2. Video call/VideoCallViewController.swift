//
//  VideoCallViewController.swift
//  DemoTwilioVideo
//
//  Created by Duy Tran N. VN.Danang on 2/22/22.
//

import UIKit
import TwilioVideo

final class VideoCallViewController: UIViewController {

    @IBOutlet private weak var roomNameLabel: UILabel!
    @IBOutlet private weak var myView: VideoView!
    @IBOutlet private weak var remoteView: VideoView!
    @IBOutlet private weak var microphoneButton: UIButton!
    @IBOutlet private weak var videoButton: UIButton!

    var room: Room?
    var remoteParticipant: RemoteParticipant?

    override func viewDidLoad() {
        super.viewDidLoad()
        requestCameraAccess()
        requestAudioAccess()
        connectToARoom()
        setupRemoteView()
    }

    @IBAction private func flipCameraButtonTouchUpInside(_ button: UIButton) {
        flipCamera()
    }
    
    @IBAction private func microphoneButtonTouchUpInside(_ button: UIButton) {
        toggleMic()
    }

    @IBAction private func videoButtonTouchUpInside(_ button: UIButton) {
        toggleCamera()
    }

    @IBAction private func outButtonTouchUpInside(_ button: UIButton) {
        disconnectFromRoom()
    }
}

extension VideoCallViewController: RoomDelegate {

    func roomDidConnect(room: Room) {
        print("🍀 Did connect to Room")

        if let localParticipant = room.localParticipant {
            print("🍀 Local identity \(localParticipant.identity)")

            // Set the delegate of the local particiant to receive callbacks
            localParticipant.delegate = self
        }

        // Connected participants already in the room
        print("🍀 Number of connected Participants \(room.remoteParticipants.count)")

        // Set the delegate of the remote participants to receive callbacks
        for remoteParticipant in room.remoteParticipants {
            remoteParticipant.delegate = self
        }
    }

    func roomDidDisconnect(room: Room, error: Error?) {
        print("🍀 Disconnected from room \(room.name), error = \(String(describing: error))")

        self.cleanupRemoteParticipant()
        self.room = nil
    }

    // ROOM RECONNECTION
    // Error will be either TwilioVideoSDK.Error.signalingConnectionError or TwilioVideoSDK.Error.mediaConnectionError
    func roomIsReconnecting(room: Room, error: Error) {
        print("Reconnecting to room \(room.name), error = \(String(describing: error))")
    }

    func roomDidReconnect(room: Room) {
        print("Reconnected to room \(room.name)")
    }
}

extension VideoCallViewController: LocalParticipantDelegate {

}

// Lastly, we can subscribe to important events on the VideoView
extension VideoCallViewController: VideoViewDelegate {
    func videoViewDimensionsDidChange(view: VideoView, dimensions: CMVideoDimensions) {
        print("The dimensions of the video track changed to: \(dimensions.width)x\(dimensions.height)")
        self.view.setNeedsLayout()
    }
}

extension VideoCallViewController: CameraSourceDelegate {

}

// MARK: - Setup local & room
extension VideoCallViewController {

    func connectToARoom() {
        // Prepare local media which we will share with Room Participants.
        self.prepareLocalMedia()

        // Preparing the connect options with the access token that we fetched (or hardcoded).
        let connectOptions = ConnectOptions(token: TwilioVideoManager.shared.accessToken) { [weak self] (builder) in

            // Use the local media that we prepared earlier.
            builder.audioTracks = TwilioVideoManager.shared.localAudioTrack != nil ? [TwilioVideoManager.shared.localAudioTrack!] : [LocalAudioTrack]()
            builder.videoTracks = TwilioVideoManager.shared.localVideoTrack != nil ? [TwilioVideoManager.shared.localVideoTrack!] : [LocalVideoTrack]()

            // Use the preferred audio codec
            if let preferredAudioCodec = Settings.shared.audioCodec {
                builder.preferredAudioCodecs = [preferredAudioCodec]
            }

            // Use the preferred video codec
            if let preferredVideoCodec = Settings.shared.videoCodec {
                builder.preferredVideoCodecs = [preferredVideoCodec]
            }

            // Use the preferred encoding parameters
            if let encodingParameters = Settings.shared.getEncodingParameters() {
                builder.encodingParameters = encodingParameters
            }

            // Use the preferred signaling region
            if let signalingRegion = Settings.shared.signalingRegion {
                builder.region = signalingRegion
            }

            // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
            // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
            builder.roomName = TwilioVideoManager.shared.roomName

        }

        // Connect to the Room using the options we provided.
        room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)
        roomNameLabel.text = TwilioVideoManager.shared.roomName

        print("💛 Attempting to connect to room \(room)")
    }

    func disconnectFromRoom() {
        room?.disconnect()
    }

    private func prepareLocalMedia() {

        // We will share local audio and video when we connect to the Room.

        // Create an audio track.
        if (TwilioVideoManager.shared.localAudioTrack == nil) {
            TwilioVideoManager.shared.localAudioTrack = LocalAudioTrack(options: nil, enabled: true, name: "Microphone")

            if (TwilioVideoManager.shared.localAudioTrack == nil) {
                print("🧨 Failed to create audio track")
            }
        }

        // Create a video track which captures from the camera.
        if (TwilioVideoManager.shared.localVideoTrack == nil) {
            self.startPreview()
        }
    }

    private func startPreview() {
        if PlatformUtils.isSimulator {
            return
        }

        let frontCamera = CameraSource.captureDevice(position: .front)
        let backCamera = CameraSource.captureDevice(position: .back)

        if (frontCamera != nil || backCamera != nil) {

            let options = CameraSourceOptions { (builder) in
                if #available(iOS 13.0, *) {
                    // Track UIWindowScene events for the key window's scene.
                    // The example app disables multi-window support in the .plist (see UIApplicationSceneManifestKey).
//                    builder.orientationTracker = UserInterfaceTracker(scene: UIApplication.shared.keyWindow!.window!)
                }
            }
            // Preview our local camera track in the local video preview view.
            TwilioVideoManager.shared.cameraSource = CameraSource(options: options, delegate: self)
            TwilioVideoManager.shared.localVideoTrack = LocalVideoTrack(source: TwilioVideoManager.shared.cameraSource!, enabled: true, name: "Camera")

            // Add renderer to video track for local preview
            TwilioVideoManager.shared.localVideoTrack!.addRenderer(myView)
            print("💛 Video track created")

            TwilioVideoManager.shared.cameraSource!.startCapture(device: frontCamera != nil ? frontCamera! : backCamera!) { (captureDevice, videoFormat, error) in
                if let error = error {
                    print("🧨 Capture failed with error.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                } else {
                    self.myView.shouldMirror = (captureDevice.position == .front)
                }
            }
        }
        else {
            print("🧨 No front or back capture device found!")
        }
    }

    private func flipCamera() {
        let frontCamera = CameraSource.captureDevice(position: .front)
        let backCamera = CameraSource.captureDevice(position: .back)
        guard frontCamera != nil && backCamera != nil else {
            print("🧨 An error occured with camera (font & back)")
            return
        }

        var newDevice: AVCaptureDevice?

        if let camera = TwilioVideoManager.shared.cameraSource, let captureDevice = camera.device {
            if captureDevice.position == .front {
                newDevice = backCamera//CameraSource.captureDevice(position: .back)
            } else {
                newDevice = frontCamera//CameraSource.captureDevice(position: .front)
            }

            if let newDevice = newDevice {
                camera.selectCaptureDevice(newDevice) { [weak self] (captureDevice, videoFormat, error) in
                    if let error = error {
                        print("🧨 Error selecting capture device.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                    } else {
                        self?.myView.shouldMirror = captureDevice.position == .front
                    }
                }
            }
        }
    }

    private func toggleMic() {
        let localAudioTrack = TwilioVideoManager.shared.localAudioTrack
        if (localAudioTrack != nil) {
            localAudioTrack?.isEnabled = !(localAudioTrack?.isEnabled)!

            // Update the button title
            if (localAudioTrack?.isEnabled == true) {
                microphoneButton.setTitle("Mute", for: .normal)
            } else {
                microphoneButton.setTitle("Unmute", for: .normal)
            }
        }
    }

    private func toggleCamera() {
        let localVideoTrack = TwilioVideoManager.shared.localVideoTrack

        if (localVideoTrack != nil) {
            localVideoTrack?.isEnabled = !(localVideoTrack?.isEnabled)!

            // Update the button title
            if (localVideoTrack?.isEnabled == true) {
                videoButton.setTitle("Off Camera", for: .normal)
            } else {
                videoButton.setTitle("On Camera", for: .normal)
            }
        }
    }
}

// MARK: - Setup remote
extension VideoCallViewController {
    private func setupRemoteView() {
        remoteView.contentMode = .scaleAspectFit
    }

    func renderRemoteParticipant(participant : RemoteParticipant) -> Bool {
        // This example renders the first subscribed RemoteVideoTrack from the RemoteParticipant.
        let videoPublications = participant.remoteVideoTracks
        for publication in videoPublications {
            if let subscribedVideoTrack = publication.remoteTrack,
                publication.isTrackSubscribed {
                setupRemoteView()
                subscribedVideoTrack.addRenderer(self.remoteView!)
                self.remoteParticipant = participant
                return true
            }
        }
        return false
    }

    func renderRemoteParticipants(participants : Array<RemoteParticipant>) {
        for participant in participants {
            // Find the first renderable track.
            if participant.remoteVideoTracks.count > 0,
                renderRemoteParticipant(participant: participant) {
                break
            }
        }
    }

    func cleanupRemoteParticipant() {
        if self.remoteParticipant != nil {
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
            self.remoteParticipant = nil
        }
    }
}

extension VideoCallViewController {

    // MARK: Camera & Video permission
    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { isAllowed in
            print("🍀 \(#function)  \(isAllowed)")
        }
    }

    private func requestAudioAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { isAllowed in
            print("🍀 \(#function)  \(isAllowed)")
        }
    }
}

extension VideoCallViewController: RemoteParticipantDelegate {

    // First, we set a Participant Delegate when a Participant first connects:
    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        print("🍀 Participant \(participant.identity) has joined Room \(room.name)")

        // Set the delegate of the remote participant to receive callbacks
        participant.delegate = self
    }

    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        print("🍀 Participant \(participant.identity) has left Room \(room.name)")
    }

    func remoteParticipantDidPublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has offered to share the video Track.

        print("🍀 \(#function) Participant \(participant.identity) published \(publication.trackName) video track")
    }

    func remoteParticipantDidUnpublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has stopped sharing the video Track.

        print("🍀 \(#function) Participant \(participant.identity) unpublished \(publication.trackName) video track")
    }

    func remoteParticipantDidPublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has offered to share the audio Track.

        print("🍀 \(#function) Participant \(participant.identity) published \(publication.trackName) audio track")
    }

    func remoteParticipantDidUnpublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has stopped sharing the audio Track.

        print("🍀 \(#function) Participant \(participant.identity) unpublished \(publication.trackName) audio track")
    }

    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // The LocalParticipant is subscribed to the RemoteParticipant's video Track. Frames will begin to arrive now.

        print("🍀 \(#function) Subscribed to \(publication.trackName) video track for Participant \(participant.identity)")

        if (self.remoteParticipant == nil) {
            _ = renderRemoteParticipant(participant: participant)
        }
    }

    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.

        print("🍀 \(#function) Unsubscribed from \(publication.trackName) video track for Participant \(participant.identity)")

        if self.remoteParticipant == participant {
            cleanupRemoteParticipant()

            // Find another Participant video to render, if possible.
            if var remainingParticipants = room?.remoteParticipants,
                let index = remainingParticipants.firstIndex(of: participant) {
                remainingParticipants.remove(at: index)
                renderRemoteParticipants(participants: remainingParticipants)
            }
        }
    }

    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's audio now.

        print("🍀 \(#function) Subscribed to \(publication.trackName) audio track for Participant \(participant.identity)")
    }

    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
        // remote Participant's audio.

        print("🍀 \(#function) Unsubscribed from \(publication.trackName) audio track for Participant \(participant.identity)")
    }

    func remoteParticipantDidEnableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        print("🍀 \(#function) Participant \(participant.identity) enabled \(publication.trackName) video track")
    }

    func remoteParticipantDidDisableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        print("🍀 \(#function) Participant \(participant.identity) disabled \(publication.trackName) video track")
    }

    func remoteParticipantDidEnableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        print("🍀 \(#function) Participant \(participant.identity) enabled \(publication.trackName) audio track")
    }

    func remoteParticipantDidDisableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        print("🍀 \(#function) Participant \(participant.identity) disabled \(publication.trackName) audio track")
    }

    func didFailToSubscribeToAudioTrack(publication: RemoteAudioTrackPublication, error: Error, participant: RemoteParticipant) {
        print("🍀 \(#function) FailedToSubscribe \(publication.trackName) audio track, error = \(String(describing: error))")
    }

    func didFailToSubscribeToVideoTrack(publication: RemoteVideoTrackPublication, error: Error, participant: RemoteParticipant) {
        print("🍀 \(#function) FailedToSubscribe \(publication.trackName) video track, error = \(String(describing: error))")
    }
}
