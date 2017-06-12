//
//  ViewController.swift
//  自定义相机——人脸识别
//
//  Created by 康鹏鹏 on 2017/6/9.
//  Copyright © 2017年 dhcc. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    var session: AVCaptureSession?
    
    var device: AVCaptureDevice?
    
    var input: AVCaptureDeviceInput?
    
    var output: AVCaptureMetadataOutput?
    
    var preview: AVCaptureVideoPreviewLayer?
    
    /// 面部轮廓视图
    lazy var faceBoxView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "face")
        // self.view.addSubview(imgView)
        self.preview?.addSublayer(imgView.layer)
        return imgView
    }()
    
    
    
    /// 开始面部识别，显示面部位置时需要标记，否则动画效果不能出来
    var isStartFaceRecognition: Bool = true
    
    /// 是否识别完成
    var isComplete: Bool = false
    
    /// 识别出的人像
    @IBOutlet weak var capturedImgView: UIImageView!
    
    var isStartGetImage: Bool = true
    
    /// 图像输出
    var cameraOutput: AVCapturePhotoOutput = {
        let capImg = AVCapturePhotoOutput()
        return capImg
    }()
    
    var stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    
    func setupCamera() {
        
        //session
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSessionPresetPhoto
        session?.sessionPreset = AVCaptureSessionPreset1280x720
        
        // device 
        device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

        // 设置为前置摄像头
        let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.front)
        for device in (devices?.devices)! {
            // 自动白平衡
            if device.isWhiteBalanceModeSupported(.autoWhiteBalance) {
                device.isWhiteBalanceModeSupported(.autoWhiteBalance)
            }
            // 自动曝光
            device.isWhiteBalanceModeSupported(.autoWhiteBalance)
            self.device = device
        }
        
        
        // input
        do {
            try input = AVCaptureDeviceInput(device: device)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }

        // output // 人脸识别
        output = AVCaptureMetadataOutput()
        output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // preview
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview?.frame = CGRect(x: (self.view.frame.width-200)/2.0, y: 50, width: 200, height: 200)
        preview?.cornerRadius = 100
        preview?.borderColor = UIColor.gray.cgColor
        preview?.borderWidth = 3
        // preview?.frame = self.view.bounds
        self.view.layer.insertSublayer(preview!, at: 0)
        
        session?.beginConfiguration()
        if (session?.canAddInput(input))! {
            session?.addInput(input)
        }
        if (session?.canAddOutput(output))! {
            session?.addOutput(output)
            output?.metadataObjectTypes = [AVMetadataObjectTypeFace]
        }
        session?.commitConfiguration()
        
        session?.startRunning()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        
        setupCamera()
        

    }
    
//    func capturePhotoHHH() {
//        isComplete = true
//
//        session?.addOutput(cameraOutput)
//        
//        let connection = cameraOutput.connection(withMediaType: AVMediaTypeVideo)
//        connection?.videoOrientation = AVCaptureVideoOrientation.portrait
//
//        
//        stillImageOutput.captureStillImageAsynchronously(from: connection) { (imageDataSampleBuffer, error) in
//
//            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
//            let image = UIImage(data: imageData!)
//            
//            self.capturedImgView.image = image
//            self.isComplete = true
//            self.session?.stopRunning()
//        }
//    }
    
    func capturePhoto() {
        isComplete = true
        
        session?.addOutput(cameraOutput)
        
        if let connection = cameraOutput.connection(withMediaType: AVMediaTypeVideo) {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                kCVPixelBufferWidthKey as String: 200,
                kCVPixelBufferHeightKey as String: 200
            ]
            settings.previewPhotoFormat = previewFormat
            cameraOutput.capturePhoto(with: settings, delegate: self)
        }
        session?.stopRunning()
    }
    
    
    

    

    
    

    // MARK: - AVCapturePhotoCaptureDelegate
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        print("识别出人脸")

        if let error = error {
            print(error.localizedDescription)
        }

        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            print(UIImage(data: dataImage)?.size as Any)
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
            
            self.capturedImgView.image = image
        } else {
            print("some error here")
        }
        
    }
    

    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if isComplete == true {
            return
        }
        for item in metadataObjects {
            if (item as! AVMetadataObject).type == AVMetadataObjectTypeFace {
                let transform: AVMetadataObject = (preview?.transformedMetadataObject(for: item as? AVMetadataObject))!
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.showFaceImage(withFrame: transform.bounds)
                    }
                    self.capturePhoto()
                }
            }
        }
        
    }
    
    
    
    /// 显示人脸位置视图
    func showFaceImage(withFrame rect: CGRect) {
        if isStartFaceRecognition {
            isStartFaceRecognition = false
            faceBoxView.frame = rect
            self.faceBoxView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5);
            UIView.animate(withDuration: 0.3, animations: {
                [weak self] in
                self?.faceBoxView.alpha = 1.0
                self?.faceBoxView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0);
            }) { (finished: Bool) in
                UIView.animate(withDuration: 0.2, animations: {
                    [weak self] in
                    self?.faceBoxView.alpha = 0.0
                    }, completion: { (finished: Bool) in
                        self.isStartFaceRecognition = true
                })
            }
        }

    }
    
    private func sampleBufferToImage(sampleBuffer: CMSampleBuffer!) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        
        
        let newContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerCompornent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        let imageRef: CGImage = newContext.makeImage()!
        //        let resultImage = UIImage(CGImage: imageRef, scale: 1.0, orientation: UIImageOrientation.Right)!
        
        let image = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
        
        return image
    }
    func image(fromSampleBuffer sampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow: size_t = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: size_t = CVPixelBufferGetWidth(imageBuffer)
        let height: size_t = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        
        let context: CGContext = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        let imageRef: CGImage = context.makeImage()!
        
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let image: UIImage = UIImage(cgImage: imageRef)
        
        return image
    }
    
    
    func captureOutput(_ fromcaptureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        print("开不了")
    }

    
    
    //    private func sampleBufferToImage(sampleBuffer: CMSampleBuffer!) -> UIImage {
    //        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    //        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
    //        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
    //
    //        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
    //        let width = CVPixelBufferGetWidth(imageBuffer)
    //        let height = CVPixelBufferGetHeight(imageBuffer)
    //
    //        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    //
    //        let bitsPerCompornent = 8
    //        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
    //
    //
    //        let newContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerCompornent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
    //
    //        let imageRef: CGImage = newContext.makeImage()!
    //        
    //        let resultImg = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
    //        
    //        return resultImg
    //    }

}

