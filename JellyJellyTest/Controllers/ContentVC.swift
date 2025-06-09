//
//  CreateContentVC.swift
//


import UIKit
import AVFoundation

class ContentVC: UIViewController {

    // MARK: - UI Elements - Properties
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var captureButton: UIButton!
    @IBOutlet private var captureRingView: UIView!
    @IBOutlet private var flipButton: UIButton!
    @IBOutlet private var flipLabel: UILabel!
    @IBOutlet private var speedButton: UIButton!
    @IBOutlet private var speedLabel: UILabel!
    @IBOutlet private var beautyButton: UIButton!
    @IBOutlet private var beautyLabel: UILabel!
    @IBOutlet private var timerButton: UIButton!
    @IBOutlet private var timerLabel: UILabel!
    @IBOutlet private var flashButton: UIButton!
    @IBOutlet private var flashLabel: UILabel!
    @IBOutlet private var galleryButton: UIButton!
    @IBOutlet private var effectsButton: UIButton!
    @IBOutlet private var soundsView: UIView!
    @IBOutlet private var filtersButton: UIButton!
    @IBOutlet private var filtersLabel: UILabel!
    @IBOutlet private var timeCounterLabel: UILabel!
    @IBOutlet private var saveButton: UIButton!
    @IBOutlet private var discardButton: UIButton!
    @IBOutlet private var effectsLabel: UILabel!

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let photoOutput = AVCapturePhotoOutput()
    private let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var activeInput : AVCaptureDeviceInput!
    private var outputUrl : URL?
    private var currentCamDevice : AVCaptureDevice?
    private var thumbnailImage : UIImage?
    private var recordClips = [Videos]()
    private var isRecording = false

    private var videoDurOfLastClip = 0
    private var recordingTimer: Timer?

    private var totalRecTimeInSecs = 0
    private var totalRecTimeInMins = 0

    var currentMaxRecDur: Int = 15 {
        didSet {
            timeCounterLabel.text = "\(currentMaxRecDur)s"
        }
    }

    lazy var segmentProView = ProgressView(width: view.frame.width - 17.5)

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        if setupCaptureSession(){
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideTabBarAndNavigationBar()

        if let preview = videoPreviewLayer, preview.superlayer == nil {
            preview.frame = view.bounds
            view.layer.insertSublayer(preview, at: 0)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showTabBarAndNavigationBar()

    }

    // MARK: - Button Actions

    @IBAction func captureButtonTapped(_ sender: UIButton) {
        didTapRecord()
    }

    @IBAction func discardButton(_ sender: UIButton) {
        showDiscardAlert()
    }

    @IBAction func saveButton(_ sender: UIButton) {
        saveRecording()
    }

    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera()
    }

    @IBAction func dismissButton(_ sender: UIButton) {

        resetSessionToInitialState()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        tabBarController?.selectedIndex = 0
    }

    // MARK: - Camera Setup

    private func setupCaptureSession() -> Bool{
        captureSession.sessionPreset = AVCaptureSession.Preset.high

        //INPUTS
        if let captureVideoDevice = AVCaptureDevice.default(for: AVMediaType.video),
           let captureAudioDevice = AVCaptureDevice.default(for: AVMediaType.audio) {
            do {
                let inputVideo = try AVCaptureDeviceInput(device: captureVideoDevice)
                let inputAudio = try AVCaptureDeviceInput(device: captureAudioDevice)

                if captureSession.canAddInput(inputVideo) {
                    captureSession.addInput(inputVideo)
                    activeInput = inputVideo
                }
                if captureSession.canAddInput(inputAudio) {
                    captureSession.addInput(inputAudio)
                }

                if captureSession.canAddOutput(movieOutput){
                    captureSession.addOutput(movieOutput)
                }

            } catch let error {
                print("ERROR - SESSİON", error)
                return false

            }
        }
        //OUTPUTS
        if captureSession.canAddOutput(photoOutput){
            captureSession.addOutput(photoOutput)
        }
        //Previews
        let preLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        preLayer.frame = view.frame
        preLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(preLayer, at: 0)
        videoPreviewLayer = preLayer
        return true
    }

    // MARK: - Recording Management
    private func startRecording(){
        if movieOutput.isRecording == false {
            guard let connection = movieOutput.connection(with: .video) else {return}
            if connection.isVideoOrientationSupported {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
                let device = activeInput.device
                if device.isSmoothAutoFocusEnabled {
                    do {
                        try device.lockForConfiguration()
                        device.isSmoothAutoFocusEnabled = false
                        device.unlockForConfiguration()
                    } catch {
                        print("CONFIG ERROR: \(error)")
                    }
                }
                outputUrl = tempUrl()
                if let outputUrl = outputUrl {
                    print("OUTPUT URL: \(outputUrl)")
                    movieOutput.startRecording(to: outputUrl, recordingDelegate: self)

                }
                animatedRecordButton()
            }
        }

    }

    private func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            animatedRecordButton()
            stopTimer()
            segmentProView.pauseProgress()
            print("STOP COUNT")
        }

        // After a short delay, merge all clips
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mergeVideos(videoURLs: self.recordClips.map { $0.videoUrl }) { mergedUrl in
                if let finalUrl = mergedUrl {
                    print("Final merged video at: \(finalUrl)")
                    // Play it, push PreviewVC, or save to photo library as you wish
                }
            }
        }
    }

    private func saveRecording(){
        let previewVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(identifier: "PreviewVC") { coder -> PreviewVC? in
            PreviewVC(coder: coder, recordedClips: self.recordClips)
        }
        previewVC.viewWillDenitRestartVideo = { [weak self] in
            guard let self = self else {return}

            DispatchQueue.global(qos: .background).async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
            }
        }
        navigationController?.pushViewController(previewVC, animated: true)
    }


    private func didTapRecord() {
        let maxDuration = currentMaxRecDur * 10 // multiplied by 10 because timer ticks every 0.1s

        if isRecording {
            stopRecording()
        } else {
            if totalRecTimeInSecs >= maxDuration {
                showMaxDurationAlert()
                return
            }
            startRecording()
        }
    }

    private func showMaxDurationAlert() {
        let alert = UIAlertController(title: "Recording Limit Reached",
                                      message: "You have reached the maximum recording time of \(currentMaxRecDur) seconds.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }

    private func discardLastRecord(){
        print("Discarded")
        outputUrl = nil
        thumbnailImage = nil
        recordClips.removeLast()
        resetAllVisibilitytoId()
        setNewOutputUrlThumImage()
        segmentProView.removeLastSegment()


        if recordClips.isEmpty == true {
            resetTimersAndProgressToZero()
        } else if recordClips.isEmpty == false {
            calculateDurLeft()
        }

    }

    private func setNewOutputUrlThumImage(){
        outputUrl = recordClips.last?.videoUrl
        let currentUrl: URL? = outputUrl
        guard let currentUrlUnwrapped = currentUrl else {return}
        guard let generatedThumbImage = genVideoThum(withfile: currentUrlUnwrapped) else {return}
        if currentCamDevice?.position == .front {

            thumbnailImage = didGetPicture(generatedThumbImage, to: .upMirrored)

        }else {
            thumbnailImage = generatedThumbImage
        }
    }

    //MARK: Time Methods

    private func startTimer(){
        videoDurOfLastClip = 0
        stopTimer()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            self?.timerTick()

        })
    }

    private func timerTick(){
        totalRecTimeInSecs += 1
        videoDurOfLastClip += 1


        let timeLim = currentMaxRecDur * 10
        if totalRecTimeInSecs == timeLim {

            didTapRecord()
        }
        let startTime = 0
        let trimmedTime : Int = Int(currentMaxRecDur) - startTime
        let positiveOrZero = max(totalRecTimeInSecs, 0)
        let progress = Float(positiveOrZero) / Float(trimmedTime) / 10
        segmentProView.setProgress(CGFloat(progress))

        let countDowmSec: Int = max(0, Int(currentMaxRecDur) - totalRecTimeInSecs / 10)
        timeCounterLabel.text = "\(countDowmSec)s"
    }

    private func stopTimer(){
        recordingTimer?.invalidate()
    }

    private func calculateDurLeft(){
        let timeToDiscard = videoDurOfLastClip
        let currentCombTime = totalRecTimeInSecs
        let newVideoDur = currentCombTime - timeToDiscard
        totalRecTimeInSecs = newVideoDur
        let countDownSec: Int = Int(currentMaxRecDur) - totalRecTimeInSecs / 10
        timeCounterLabel.text = "\(countDownSec)"
    }

    private func resetTimersAndProgressToZero(){
        totalRecTimeInSecs = 0
        totalRecTimeInMins = 0
        videoDurOfLastClip = 0
        stopTimer()
        segmentProView.setProgress(0)
        timeCounterLabel.text = "\(currentMaxRecDur)"
    }

    //MARK: Camera Actions
    private func flipCamera() {
        let wasRecording = isRecording
        if wasRecording { stopRecording() }

        captureSession.beginConfiguration()

        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        let newCamDevice = currentInput.device.position == .back ? getDeviceFront(position: .front) : getDeviceBack(position: .back)

        guard let newVideoInput = try? AVCaptureDeviceInput(device: newCamDevice!) else { return }

        // Remove existing inputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        if captureSession.canAddInput(newVideoInput) {
            captureSession.addInput(newVideoInput)
            activeInput = newVideoInput
            currentCamDevice = newCamDevice
        }

        // Re-add mic input
        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           captureSession.canAddInput(micInput) {
            captureSession.addInput(micInput)
        }

        captureSession.commitConfiguration()

        if wasRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.startRecording()
            }
        }
    }

    private func mergeVideos(videoURLs: [URL], completion: @escaping (URL?) -> Void) {
        let mixComposition = AVMutableComposition()
        var insertTime = CMTime.zero

        let outputURL = tempUrl()!
        let mainInstruction = AVMutableVideoCompositionInstruction()
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []

        for (index, videoURL) in videoURLs.enumerated() {
            let asset = AVAsset(url: videoURL)
            guard let videoTrack = asset.tracks(withMediaType: .video).first else { continue }
            let timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)

            guard let compTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { continue }
            try? compTrack.insertTimeRange(timeRange, of: videoTrack, at: insertTime)

            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)

            let transform = videoTrack.preferredTransform

            // Detect if it's a front camera clip
            let isFrontCamera = recordClips[index].cameraPosition == .front

            if isFrontCamera {
                // Apply horizontal flip for front camera
                let videoSize = videoTrack.naturalSize
                let flipTransform = transform.concatenating(CGAffineTransform(scaleX: -1, y: 1))
                    .concatenating(CGAffineTransform(translationX: videoSize.width, y: 0))
                instruction.setTransform(flipTransform, at: insertTime)
            } else {
                instruction.setTransform(transform, at: insertTime)
            }

            layerInstructions.append(instruction)

            // Add audio
            if let audioTrack = asset.tracks(withMediaType: .audio).first,
               let compAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try? compAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: insertTime)
            }

            insertTime = CMTimeAdd(insertTime, asset.duration)
        }

        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: insertTime)
        mainInstruction.layerInstructions = layerInstructions

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: 1080, height: 1920)

        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = outputURL
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = videoComposition

        exporter?.exportAsynchronously {
            if exporter?.status == .completed {
                DispatchQueue.main.async {
                    completion(outputURL)
                }
            } else {
                print("Merge failed:", exporter?.error ?? "Unknown error")
                completion(nil)
            }
        }
    }


    private func getDeviceFront(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }
    private func getDeviceBack(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    // MARK: - Helper Methods
    private func showDiscardAlert(){
        let alertVC = UIAlertController(title: "Discard Last Clip ?", message: nil, preferredStyle: .alert)
        let discardAction = UIAlertAction(title: "Discard", style: .default) { [weak self] (_) in
            self!.discardLastRecord()

        }
        let keepAction = UIAlertAction(title: "Keep!", style: .cancel) { (_) in


        }
        alertVC.addAction(discardAction)
        alertVC.addAction(keepAction)
        present(alertVC, animated: true)
    }



    private func tempUrl() -> URL? {
        let directory = NSTemporaryDirectory() as NSString

        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }


    private func animatedRecordButton(){
        isRecording = !isRecording

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: { [weak self] in
            guard let self = self else { return }
            if self.isRecording {
                self.captureButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.captureButton.layer.cornerRadius = 5
                self.captureRingView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)

                self.saveButton.alpha = 0
                self.discardButton.alpha = 0

                [self.galleryButton, self.soundsView].forEach { subView in
                    subView?.isHidden = true
                }
            } else {
                self.captureButton.transform = CGAffineTransform.identity
                self.captureButton.layer.cornerRadius = 68/2
                self.captureRingView.transform = CGAffineTransform.identity

                self.resetAllVisibilitytoId()
            }
        })
    }

    private func resetAllVisibilitytoId(){

        if recordClips.isEmpty == true {
            [self.galleryButton, self.soundsView].forEach { subView in
                subView?.isHidden = false
            }
            saveButton.alpha = 0
            discardButton.alpha = 0
            print("THERE IS NO RECORD")
        } else {
            [self.galleryButton, self.soundsView].forEach { subView in
                subView?.isHidden = true
            }
            saveButton.alpha = 1
            discardButton.alpha = 1
            print("THERE IS A RECORD")
        }
    }


    private func resetSessionToInitialState() {
        stopRecording()
        stopTimer()
        segmentProView.setProgress(0)
        segmentProView.removeAllSegments()

        recordClips.removeAll()
        outputUrl = nil
        thumbnailImage = nil
        totalRecTimeInSecs = 0
        totalRecTimeInMins = 0
        videoDurOfLastClip = 0
        isRecording = false

        DispatchQueue.main.async {
            self.resetAllVisibilitytoId()
            self.timeCounterLabel.text = "\(self.currentMaxRecDur)"
        }

        // Optional: restart camera session if stopped
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }

}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension ContentVC: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            print("RECORDİNG ERROR: \(error?.localizedDescription ?? "")")
        }else {
            guard let urlVideoRec = outputUrl else {return}

            guard let generatedThumbImage = genVideoThum(withfile: urlVideoRec) else {return}

            if currentCamDevice?.position == .front {
                thumbnailImage = didGetPicture(generatedThumbImage, to: .upMirrored)
            }else{
                thumbnailImage = generatedThumbImage
            }
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        let newRecClip = Videos(videoUrl: fileURL, cameraPosition: currentCamDevice?.position)
        recordClips.append(newRecClip)
        print("MOVIE RECORD",recordClips.count)
        startTimer()
    }

    func didGetPicture(_ picture: UIImage, to orientation: UIImage.Orientation) -> UIImage {
        let flippedImage = UIImage(cgImage: picture.cgImage!, scale: picture.scale, orientation: orientation)
        return flippedImage
    }
    func genVideoThum(withfile videoUrl: URL) -> UIImage? {
        let asset = AVAsset(url: videoUrl)

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do{
            let cmTime = CMTimeMake(value: 1, timescale: 60)
            let thumbnailCgImage = try imageGenerator.copyCGImage(at: cmTime, actualTime: nil)
            return UIImage(cgImage: thumbnailCgImage)
        }catch let error{
            print(error)

        }
        return nil
    }

}

//MARK: View Constraints
extension ContentVC {

    func setupView() {
        overrideUserInterfaceStyle = .light

        captureButton.backgroundColor = UIColor(red: 254/255, green: 44/255, blue: 85/255, alpha: 1.0)
        captureButton.layer.cornerRadius = 68/2
        captureRingView.layer.borderColor = UIColor(red: 254/255, green: 44/255, blue: 85/255, alpha: 1.0).cgColor
        captureRingView.layer.borderWidth = 6
        captureRingView.layer.cornerRadius = 85/2


        timeCounterLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        timeCounterLabel.layer.cornerRadius = 15
        timeCounterLabel.layer.borderColor = UIColor.white.cgColor
        timeCounterLabel.layer.borderWidth = 1.8
        timeCounterLabel.clipsToBounds = true

        soundsView.layer.cornerRadius = 12
        saveButton.layer.cornerRadius = 17
        saveButton.backgroundColor =  UIColor(red: 254/255, green: 44/255, blue: 85/255, alpha: 1.0)
        saveButton.alpha = 0
        discardButton.alpha = 0


        view.addSubview(segmentProView)
        segmentProView.topAnchor.constraint(equalTo: view.topAnchor, constant: 55).isActive = true
        segmentProView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        segmentProView.widthAnchor.constraint(equalToConstant: view.frame.width - 17.5).isActive = true
        segmentProView.heightAnchor.constraint(equalToConstant: 4).isActive = true
        segmentProView.translatesAutoresizingMaskIntoConstraints = false


        [self.captureButton, self.captureRingView, self.cancelButton, self.flipButton, self.flipLabel, self.speedLabel, self.speedButton, self.beautyLabel, self.beautyButton, self.filtersLabel, self.filtersButton, self.timerLabel, self.timerButton, self.galleryButton, self.effectsButton, self.soundsView, self.timeCounterLabel, self.flashLabel, self.flashButton, self.saveButton, self.effectsLabel, self.discardButton].forEach { subView in
            subView?.layer.zPosition = 1
        }
    }
}
