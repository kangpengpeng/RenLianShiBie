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
//        self.view.addSubview(imgView)
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
            self.device = device
        }
        
        // input
        do {
            try input = AVCaptureDeviceInput(device: device)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
        if (session?.canAddInput(input))! {
            session?.addInput(input)
        }
        
        // output // 人脸识别
        output = AVCaptureMetadataOutput()
        output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        if (session?.canAddOutput(output))! {
            session?.addOutput(output)
        }
        output?.metadataObjectTypes = [AVMetadataObjectTypeFace]

        // preview
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview?.frame = CGRect(x: (self.view.frame.width-200)/2.0, y: 150, width: 200, height: 200)
        preview?.cornerRadius = 100
        preview?.borderColor = UIColor.gray.cgColor
        preview?.borderWidth = 3
//        preview?.frame = self.view.bounds
        self.view.layer.insertSublayer(preview!, at: 0)
    
        session?.startRunning()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        
        setupCamera()
    }
    

    
    
    
    
//    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
//        
//        if(self.isStartGetImage)
//        {
//            let resultImage = sampleBufferToImage(sampleBuffer: sampleBuffer)
//            
//            let context = CIContext(options:[kCIContextUseSoftwareRenderer:true])
//            let detecotr = CIDetector(ofType:CIDetectorTypeFace,  context:context, options:[CIDetectorAccuracy: CIDetectorAccuracyHigh])
//            
//            
//            
//            
//            let ciImage = CIImage(image: resultImage)
//            
//            let results:NSArray = detecotr!.featuresInImage(ciImage,options: ["CIDetectorImageOrientation" : 6])
//            
//            for r in results {
//                let face:CIFaceFeature = r as! CIFaceFeature;
//                let faceImage = UIImage(CGImage: context.createCGImage(ciImage!, fromRect: face.bounds),scale: 1.0, orientation: .Right)
//                
//                NSLog("Face found at (%f,%f) of dimensions %fx%f", face.bounds.origin.x, face.bounds.origin.y,pickUIImager.frame.origin.x, pickUIImager.frame.origin.y)
//                
//                DispatchQueue.main.async() {
//                    if (self.isStartGetImage)
//                    {
//                        self.dismiss(animated: true, completion: nil)
//                        self.didReceiveMemoryWarning()
//                        
//                        self.callBack!(face: faceImage!)
//                    }
//                    self.isStartGetImage = false
//                }
//            }
//        }
//    }
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
//        var bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
//        
//        
//        let newContext = CGBitmapContextCreate(baseAddress, width, height, bitsPerCompornent, bytesPerRow, colorSpace, bitmapInfo.rawValue) as CGContext
//        
//        let imageRef: CGImage = CGBitmapContextCreateImage(newContext)
//        let resultImage = UIImage(CGImage: imageRef, scale: 1.0, orientation: UIImageOrientation.Right)!
//        
//        return resultImage
//    }
    
    func capturePhoto() {
        isComplete = true
        let connection = cameraOutput.connection(withMediaType: AVMediaTypeVideo)
        if (connection != nil) {
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                 kCVPixelBufferWidthKey as String: 160,
                                 kCVPixelBufferHeightKey as String: 160]
            settings.previewPhotoFormat = previewFormat
            cameraOutput.capturePhoto(with: settings, delegate: self)
            session?.addOutput(cameraOutput)
        }

    }

    // MARK: - AVCapturePhotoCaptureDelegate
//    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
//        print("识别出人脸")
//
//        if let error = error {
//            print(error.localizedDescription)
//        }
//
//        if  let sampleBuffer = photoSampleBuffer,
//            let previewBuffer = previewPhotoSampleBuffer,
//            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
//            print(UIImage(data: dataImage)?.size as Any)
//            
//            let dataProvider = CGDataProvider(data: dataImage as CFData)
//            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
//            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
//            
//            self.capturedImgView.image = image
//        } else {
//            print("some error here")
//        }
//        
//    }
    
//    func capturePhoto() {
//        let connection = cameraOutput.connection(withMediaType: AVMediaTypeVideo)
//        let settings = AVCapturePhotoSettings()
//        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
//        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
//                             kCVPixelBufferWidthKey as String: 160,
//                             kCVPixelBufferHeightKey as String: 160,
//                             ]
//        settings.previewPhotoFormat = previewFormat
//        self.cameraOutput.capturePhoto(with: settings, delegate: self)
//        
//    }
    
    
//    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
//        print("来到这了")
//        if let error = error {
//            print(error.localizedDescription)
//        }
//        
//        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
////            print(image: UIImage(data: dataImage)?.size)
//        } else {
//            
//        }
//        
//    }



    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
//        print("*****************")
//        print(metadataObjects)
//        print("*****************")
        
//        if isComplete {
//            return
//        }
        for item in metadataObjects {
            if (item as! AVMetadataObject).type == AVMetadataObjectTypeFace {
                let transform: AVMetadataObject = (preview?.transformedMetadataObject(for: item as? AVMetadataObject))!
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.showFaceImage(withFrame: transform.bounds)
                        self.capturePhoto()
                    }
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
    
    

}

