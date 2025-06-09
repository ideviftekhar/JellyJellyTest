//
//  VideoPlayerView.swift
//

import UIKit
import AVFoundation

class VideoPlayerView: UIView {
    
    enum PlayState: Equatable {
        case none
        case loading
        case playing
        case paused(forced: Bool)
        case stopped
    }
    
    private static let allObjects: NSHashTable<VideoPlayerView> = .weakObjects()
    
    private let playingIndicatorView = UIActivityIndicatorView()
    static let playIcon = UIImage(named: "play-solid-24")?.withRenderingMode(.alwaysTemplate)
    static let pauseIcon = UIImage(named: "pause-filled-24")?.withRenderingMode(.alwaysTemplate)
    static let refreshIcon = UIImage(named: "btnRefresh--white")?.withRenderingMode(.alwaysTemplate)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let playButton: UIButton = UIButton()
    private let videoSlider = UISlider()
    private var lastUpdateTime: Date?
    private var startTime: Date?
    private var isUpdatingSlider: Bool = false
    
    private var state: PlayState = .none {
        didSet {
            switch state {
            case .none:
                loadingIndicator.stopAnimating()
                playButton.setImage(Self.playIcon, for: .normal)
                playingIndicatorView.stopAnimating()
            case .paused:
                loadingIndicator.stopAnimating()
                playButton.setImage(Self.playIcon, for: .normal)
                playingIndicatorView.stopAnimating()
            case .playing:
                loadingIndicator.stopAnimating()
                playButton.setImage(nil, for: .normal)
                playingIndicatorView.stopAnimating()
            case .loading:
                loadingIndicator.startAnimating()
                playButton.setImage(nil, for: .normal)
                playingIndicatorView.stopAnimating()
            case .stopped:
                loadingIndicator.stopAnimating()
                playButton.setImage(Self.refreshIcon, for: .normal)
                playingIndicatorView.stopAnimating()
            }
        }
    }
    var mediaPlayer: AVPlayer? {
        willSet {
            removePlayerNotificationObserver()
        }
        didSet {
            playerLayer.player = mediaPlayer
            if let mediaPlayer = mediaPlayer {
                addPlayerNotificationObserver(player: mediaPlayer)
            }
        }
    }
    
    var playerControlStatusObserver: NSKeyValueObservation?
    var playerRateObserver: NSKeyValueObservation?
    var itemStatusObserver: NSKeyValueObservation?
    var itemDidPlayToEndObserver: NSObjectProtocol?
    private var timeObserverToken: Any?
    
    deinit {
        removeTimeObserver()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupPlayingIndicator()
        setupPlayButton()
        setupLoadingIndicator()
        setupVideoSlider()
        Self.allObjects.add(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil {
            reconnectPlayer()
        }
    }
    
    private func addTimeObserver() {
        guard timeObserverToken == nil, let player = mediaPlayer else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentTime = time.seconds
            self.updateSliderValue(currentTime: currentTime)
        }
    }
    
    private func removeTimeObserver() {
        if let timeObserverToken = timeObserverToken, let player = mediaPlayer {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    
    func reconnectPlayer() {
        if playerLayer.player != mediaPlayer {
            playerLayer.player = mediaPlayer
        }
    }
    
    override public static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            playerLayer.videoGravity = videoGravity
        }
    }
    
    var media: Post? {
        didSet {
            
            guard oldValue?.postId != media?.postId else {
                return
            }
            
            if let item = mediaPlayer?.currentItem {
                removePlayerItemNotificationObserver(item: item)
            }
            
            startTime = nil
            isUpdatingSlider = false
            updateSliderValue(currentTime: 0.0)
            if let duration = media?.duration, duration.isFinite {
                videoSlider.maximumValue = Float(duration)
                videoSlider.value = 0.0
                videoSlider.isEnabled = true
                print("Debug: Slider set - maxValue: \(duration), value: 0.0")
            } else {
                videoSlider.isEnabled = false
                videoSlider.value = 0.0
                print("Debug: Slider disabled - invalid duration")
            }
            
            if let player = PlayerManager.shared.player(for: media) {
                self.mediaPlayer = player
                if let currentItem = player.currentItem {
                    addPlayerItemNotificationObserver(item: currentItem)
                }
                
                if player.rate != 0.0 {
                    self.state = .playing
                } else if let currentItemDuration = player.currentItem?.duration,
                          CMTimeCompare(currentItemDuration, player.currentTime()) == 0 {
                    self.state = .stopped
                } else {
                    switch player.timeControlStatus {
                    case .paused:
                        
                        if player.currentTime().seconds.isZero {
                            self.state = .none
                        } else {
                            self.state = .paused(forced: false)
                        }
                    case .waitingToPlayAtSpecifiedRate:
                        self.state = .loading
                    case .playing:
                        self.state = .playing
                    @unknown default:
                        self.state = .none
                    }
                }
            } else {
                self.state = .none
            }
            lastUpdateTime = nil
            
        }
        
    }
    
    private func setupVideoSlider() {
        videoSlider.translatesAutoresizingMaskIntoConstraints = false
        videoSlider.minimumValue = 0.0
        videoSlider.maximumValue = Float(media?.duration ?? 0.0)
        videoSlider.isContinuous = true
        videoSlider.minimumTrackTintColor = .white
        videoSlider.maximumTrackTintColor = .lightGray.withAlphaComponent(0.5)
        videoSlider.setThumbImage(transparentImage(), for: .normal)
        videoSlider.setThumbImage(transparentImage(), for: .highlighted)
        
        videoSlider.layer.shadowColor = UIColor.black.cgColor
        videoSlider.layer.shadowOffset = CGSize(width: 1, height: 1)
        videoSlider.layer.shadowRadius = 3
        videoSlider.layer.shadowOpacity = 0.3
        videoSlider.layer.masksToBounds = false
        
        addSubview(videoSlider)
        NSLayoutConstraint.activate([
            videoSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            videoSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            videoSlider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            videoSlider.heightAnchor.constraint(equalToConstant: 20)
        ])
        videoSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        print("Debug: Slider setup completed")
    }
    
    private func transparentImage(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard let player = mediaPlayer, let duration = media?.duration, duration.isFinite else {
            print("Debug: Seek failed - Player or duration invalid")
            return
        }
        let newTime = CMTime(seconds: Double(sender.value), preferredTimescale: 600)
        player.seek(to: newTime, completionHandler: { [weak self] _ in
            self?.play(forced: true)
            print("Debug: Seeked to \(newTime.seconds) seconds")
        })
    }
    
    func updateSliderValue(currentTime: Double) {
        guard let duration = media?.duration, duration.isFinite else {
            print("Debug: Duration invalid in updateSliderValue")
            return
        }
        let clampedTime = min(max(currentTime, 0.0), duration)
        videoSlider.value = Float(clampedTime)
        print("Debug: Slider updated to \(clampedTime) / \(duration)")
    }
    
}

extension VideoPlayerView {
    private func setupPlayingIndicator() {
        
        do {
            playingIndicatorView.hidesWhenStopped = true
            playingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(playingIndicatorView)
            
            NSLayoutConstraint.activate([
                playingIndicatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                playingIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
                playingIndicatorView.widthAnchor.constraint(equalToConstant: 20),
                playingIndicatorView.heightAnchor.constraint(equalToConstant: 20),
            ])
        }
    }
    
    private func setupPlayButton() {
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.isUserInteractionEnabled = true
        playButton.setImage(Self.playIcon, for: .normal)
        
        playButton.tintColor = UIColor.white
        playButton.alpha = 0.9
        playButton.layer.shadowColor = UIColor.black.cgColor
        playButton.layer.shadowOffset = .zero
        playButton.layer.shadowRadius = 5
        playButton.layer.shadowOpacity = 1.0
        
        addSubview(playButton)
        
        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            playButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            playButton.topAnchor.constraint(equalTo: topAnchor),
            playButton.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        playButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = UIColor.white
        loadingIndicator.layer.shadowColor = UIColor.black.cgColor
        loadingIndicator.layer.shadowOffset = .zero
        loadingIndicator.layer.shadowRadius = 5
        loadingIndicator.layer.shadowOpacity = 0.2
        addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

extension VideoPlayerView {
    
    @objc private func playButtonTapped(_ sender: UIButton) {
        if state == .playing || state == .loading {
            pause(forced: true)
        } else {
            play(forced: true)
        }
    }
    
    func play(forced: Bool) {
        
        func internalPlay() {
            do{
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                if let currentItemDuration = mediaPlayer?.currentItem?.duration,
                   let currentTime = mediaPlayer?.currentTime(),
                   CMTimeCompare(currentItemDuration, currentTime) == 0 {
                    mediaPlayer?.seek(to: .zero)
                    updateSliderValue(currentTime: 0.0)
                } else if state == .stopped {
                    mediaPlayer?.seek(to: .zero)
                    updateSliderValue(currentTime: 0.0)
                }
                
                mediaPlayer?.play()
                state = .playing
                isUpdatingSlider = true
                addTimeObserver()
            } catch { }
        }
        
        Self.pauseAll(except: self)
        
        switch state {
        case .none:
            internalPlay()
        case .paused(forced: let forcedPause):
            if forced {
                internalPlay()
            } else if !forcedPause {
                internalPlay()
            }
        case .stopped:
            if forced {
                internalPlay()
            }
        case .loading, .playing:
            break
        }
        
    }
    func pause(forced: Bool) {
        guard state == .playing || state == .loading else {
            return
        }
        
        mediaPlayer?.pause()
        state = .paused(forced: forced)
        isUpdatingSlider = false
        startTime = nil
        lastUpdateTime = nil
        removeTimeObserver()
    }
    
    static func pauseAll(except: VideoPlayerView? = nil) {
        for object in allObjects.allObjects {
            if object != except {
                object.pause(forced: false)
            }
        }
    }
    
    func stop() {
        guard state != .stopped else {
            return
        }
        
        mediaPlayer?.pause()
        mediaPlayer?.seek(to: .zero)
        state = .stopped
        isUpdatingSlider = false
        startTime = nil
        updateSliderValue(currentTime: 0.0)
        lastUpdateTime = nil
        removeTimeObserver()
    }
    
    func aa(currentTime: CMTime) {
        mediaPlayer?.seek(to: currentTime)
    }
    
    private func updateSliderManually() {
        guard let player = mediaPlayer, state == .playing, isUpdatingSlider,
              let duration = media?.duration, duration.isFinite else {
            print("Debug: Slider update skipped - invalid state or duration")
            isUpdatingSlider = false
            return
        }
        
        let currentDate = Date()
        guard let start = startTime else {
            startTime = currentDate
            updateSliderValue(currentTime: 0.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if self?.state == .playing, self?.isUpdatingSlider == true {
                    self?.updateSliderManually()
                }
            }
            return
        }
        
        let elapsedTime = currentDate.timeIntervalSince(start)
        var currentTime = elapsedTime
        if currentTime >= duration {
            currentTime = 0.0
            player.seek(to: .zero)
            player.play()
            startTime = currentDate
            updateSliderValue(currentTime: 0.0)
            print("Debug: Video looped, slider reset")
        } else {
            updateSliderValue(currentTime: currentTime)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if self?.state == .playing, self?.isUpdatingSlider == true {
                self?.updateSliderManually()
            }
        }
    }
    
}
extension VideoPlayerView {
    private func removePlayerNotificationObserver() {
        self.playerControlStatusObserver?.invalidate()
        self.playerRateObserver?.invalidate()
        self.playerControlStatusObserver = nil
        self.playerRateObserver = nil
    }
    private func addPlayerNotificationObserver(player: AVPlayer) {
        
        self.playerControlStatusObserver = player.observe(\.timeControlStatus, options: [.new, .old], changeHandler: { [self] (player, _) in
            
            switch player.timeControlStatus {
            case .paused:
                if self.state != .stopped && self.state != .none {
                    self.state = .paused(forced: false)
                }
            case .playing:
                self.state = .playing
            case .waitingToPlayAtSpecifiedRate:
                self.state = .loading
            @unknown default:
                break
            }
        })
        
        self.playerRateObserver = player.observe(\.rate, options: [.new, .old], changeHandler: { [self] (_, change) in
            
            if let newValue = change.newValue, newValue != 0.0 {
                self.state = .playing
            } else {
                if self.state == .playing {
                    self.state = .paused(forced: false)
                }
            }
        })
    }
}
extension VideoPlayerView {
    private func removePlayerItemNotificationObserver(item: AVPlayerItem) {
        self.itemStatusObserver?.invalidate()
        if let itemDidPlayToEndObserver = itemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(itemDidPlayToEndObserver, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        }
        self.itemStatusObserver = nil
        itemDidPlayToEndObserver = nil
    }
    
    private func addPlayerItemNotificationObserver(item: AVPlayerItem) {
        
        self.itemStatusObserver = item.observe(\.status, options: [.new, .old], changeHandler: { [self] (_, change) in
            
            if let newValue = change.newValue {
                switch newValue {
                case .unknown, .readyToPlay:
                    break
                case .failed:
                    pause(forced: false)
                    if let error = item.error {
                        print(error)
                    }
                @unknown default:
                    break
                }
            }
        })
        
        itemDidPlayToEndObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item, queue: nil, using: { [self] _ in
            mediaPlayer?.seek(to: .zero)
            mediaPlayer?.play()
            state = .playing
        })
    }
}
