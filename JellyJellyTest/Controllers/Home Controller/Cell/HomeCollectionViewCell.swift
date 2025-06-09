//
//  HomeCollectionViewCell.swift
//

import UIKit
import AVFoundation

class HomeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private var avatar: UIImageView!
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private var likeButton: UIButton!
    @IBOutlet private var favouriteButton: UIButton!
    @IBOutlet private var commentNumberLabel: UILabel!
    @IBOutlet private var commentButton: UIButton!
    @IBOutlet private var likeNumberLabel: UILabel!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var musicLabel: UILabel!
    @IBOutlet private var musicImage: UIImageView!
    @IBOutlet var postVideo: UIImageView!

    private let playerView = VideoPlayerView(frame: .zero)

    var post : Post? {
        didSet {
            if let id = post?.postId {
                playerView.media = post
            }
        }
    }

    var user: User? {
        didSet {
            setupUser()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatar.layer.cornerRadius = 55/2

        styleButton(likeButton)
        styleButton(favouriteButton)
        styleButton(commentButton)
        styleButton(shareButton)

        styleLabel(usernameLabel)
        styleLabel(musicLabel)
        styleLabel(descriptionLabel)

        numberLabel(commentNumberLabel)
        numberLabel(likeNumberLabel)

        styleImageView(musicImage)

        setupPlayerView()

    }

    private func setupUser(){
        usernameLabel.text = user?.username
        
        guard let profileImageUrl = user?.profileImageUrl else {return}
        avatar.loadImage(profileImageUrl)
    }

    private func setupPlayerView() {

        playerView.videoGravity = .resizeAspectFill
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.clipsToBounds = true
        postVideo.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: postVideo.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: postVideo.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: postVideo.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: postVideo.bottomAnchor),
        ])
    }

    @IBAction func likeButtonTapped(_ sender: UIButton) {
            let currentImage = likeButton.image(for: .normal)
            let isFilled = currentImage == UIImage(systemName: "heart.fill")
            let newImage = isFilled ? UIImage(systemName: "heart") : UIImage(systemName: "heart.fill")
            let newTintColor = isFilled ? UIColor.white : UIColor.red
            likeButton.setImage(newImage, for: .normal)
            likeButton.tintColor = newTintColor
        }

    @IBAction func favouriteButtonTapped(_ sender: UIButton) {
        let currentImage = favouriteButton.image(for: .normal)
        let newImage = currentImage == UIImage(systemName: "bookmark") ? UIImage(systemName: "bookmark.fill") : UIImage(systemName: "bookmark")
        favouriteButton.setImage(newImage, for: .normal)
    }

    private func styleLabel(_ label: UILabel) {
        label.textColor = .white
        label.alpha = 1.0
        label.font = UIFont.boldSystemFont(ofSize: label.font.pointSize + 1) // Slightly bolder and bigger
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 1, height: 1)
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.9
        label.layer.masksToBounds = false
    }

    private func styleButton(_ button: UIButton) {
        button.tintColor = .white
        button.alpha = 1.0
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 1, height: 1)
        button.layer.shadowRadius = 3
        button.layer.shadowOpacity = 0.3
        button.layer.masksToBounds = false
    }

    private func numberLabel(_ label: UILabel) {
        label.textColor = .white
        label.alpha = 1.0
        label.font = UIFont.boldSystemFont(ofSize: label.font.pointSize + 1) // Slightly bolder and bigger
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 1, height: 1)
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.4
        label.layer.masksToBounds = false
    }

    private func styleImageView(_ imageView: UIImageView) {
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowOpacity = 0.9
        imageView.layer.masksToBounds = false
    }

}

extension HomeCollectionViewCell {

    func reconnectPlayer() {
        playerView.reconnectPlayer()
    }

    func play(forced: Bool) {
        playerView.play(forced: forced)
    }
    func pause(forced: Bool) {
        playerView.pause(forced: forced)
    }

}
