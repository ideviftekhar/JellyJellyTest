//
//  UIImageView+Extension.swift
//

import UIKit

extension UIImageView {
    func loadImage(_ urlString: String?, onSuc: ((UIImage) -> Void)? = nil) {
        self.image = UIImage()
        guard let string = urlString else {return}

        guard let url = URL(string: string) else {return}

        self.sd_setImage(with: url) { image, error, type, url in
            if onSuc != nil, error == nil {
                onSuc!(image!)
            }
        }
    }
}
