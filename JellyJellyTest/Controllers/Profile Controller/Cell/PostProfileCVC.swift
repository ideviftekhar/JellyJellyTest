//
//  PostProfileCVC.swift
//

import UIKit

class PostProfileCVC: UICollectionViewCell {

    @IBOutlet private var imageView: UIImageView!

    var post: Post? {
        didSet{
            updateView()
        }
    }

    private func updateView(){
        guard let postThumbımage = post?.imageUrl else {return}

        self.imageView.loadImage(postThumbımage)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

    }

}
