//
//  FrameExtractor.swift
//  FrameExtraction
//
//  Created by admin on 2020. 10. 08..
//  Copyright © 2020. admin. All rights reserved.
//

import UIKit
import AVFoundation

protocol FrameExtractorDelegate: class {
    func captured(image: UIImage)
}

class FrameExtractor : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    weak var delegate: FrameExtractorDelegate?
    
    private let context = CIContext()
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var permissionGranted = false
    
    private let position = AVCaptureDevice.Position.front
    private let qualityHD = AVCaptureSession.Preset.hd1280x720
    private let qualityHigh = AVCaptureSession.Preset.high
    private let qualityMedium = AVCaptureSession.Preset.medium
    private let qualityLow = AVCaptureSession.Preset.low
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
        
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func configureSession() {
        guard permissionGranted else { return }
        
        // checking which quality can be set
        if(captureSession.canSetSessionPreset(qualityHD)){
            captureSession.sessionPreset = qualityHD
        } else if(captureSession.canSetSessionPreset(qualityHigh)){
            captureSession.sessionPreset = qualityHigh
        } else if(captureSession.canSetSessionPreset(qualityMedium)){
            captureSession.sessionPreset = qualityMedium
        } else if(captureSession.canSetSessionPreset(qualityLow)){
            captureSession.sessionPreset = qualityLow
        }
        
        guard let captureDevice = selectCaptureDevice() else { return }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        // fix camera orientation
        guard let connection = videoOutput.connection(with: AVFoundation.AVMediaType.video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
        
        
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        
        /*
        return AVCaptureDevice.devices().filter {
            ($0 as AnyObject).hasMediaType(AVMediaType.video) &&
            ($0 as AnyObject).position == position
        }.first as? AVCaptureDevice
        */
        
        let deviceSession = AVCaptureDevice.DiscoverySession(deviceTypes:[AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position)
        
        for device in deviceSession.devices {
            if device.position == position {
                return device
            }
        }

        return nil
    }
    
    func captureOutput(_ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection){
        print("Got a frame!")
        
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(image: uiImage)
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
}
