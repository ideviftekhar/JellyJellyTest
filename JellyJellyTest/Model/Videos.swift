//
//  Videos.swift
//

import UIKit
import AVKit


struct Videos: Equatable {
    let videoUrl : URL
    let cameraPosition: AVCaptureDevice.Position
    
    init(videoUrl: URL, cameraPosition: AVCaptureDevice.Position?){
        self.videoUrl = videoUrl
        self.cameraPosition = cameraPosition ?? .back
    }
    static func == (lhs: Videos, rhs: Videos) -> Bool {
        return lhs.videoUrl == rhs.videoUrl && lhs.cameraPosition == rhs.cameraPosition
    }
}
