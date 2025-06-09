//
//  ProfileHeaderCRV.swift
//

import UIKit

class ProfileHeaderCRV: UICollectionReusableView {
    
    //MARK: @IBOutlets
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var profileImage: UIImageView!
    @IBOutlet private var editButton: UIButton!
    @IBOutlet private var collectButton: UIButton!

    var user: User?{
        didSet{
            updateView()
        }
    }

    func setupView(){
        profileImage.layer.cornerRadius = 50
        profileImage.layer.borderWidth = 0.8
        profileImage.layer.borderColor = UIColor.lightGray.cgColor
        editButton.layer.borderColor = UIColor.lightGray.cgColor
        editButton.layer.borderWidth = 0.8
        editButton.layer.cornerRadius = 5
        collectButton.layer.borderColor = UIColor.lightGray.cgColor
        collectButton.layer.borderWidth = 0.8
        collectButton.layer.cornerRadius = 5
    }

    private func updateView(){
        self.usernameLabel.text = user!.username!
        guard let profileImageUrl = user!.profileImageUrl else {return}
        self.profileImage.loadImage(profileImageUrl)
        
    }
}
