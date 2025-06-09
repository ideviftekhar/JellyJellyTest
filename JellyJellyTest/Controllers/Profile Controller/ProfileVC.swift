//
//  ProfileVC.swift
//

import UIKit
import SDWebImage

class ProfileVC: UIViewController {

    //MARK: Properties/Outlets
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var lodingIndicator: UIActivityIndicatorView!

    private var user: User?
    private var posts = [Post]()

    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        collectionView.isHidden = true
        lodingIndicator.hidesWhenStopped = true
        lodingIndicator.startAnimating()
        fetchAllPosts()
        vcSettings()

    }

    //MARK: Setup Methods
    func setupCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        navigationController?.navigationBar.tintColor = .black
    }

    //MARK: DATA

    func fetchAllPosts() {

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {

            let post1 = Post()
            post1.postId = 1
            post1.uid = "user_123"
            post1.imageUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg"
            post1.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
            post1.description = "This is the first sample video post."
            post1.likes = 120
            post1.views = 300
            post1.commentCount = 5
            post1.creationDate = Date(timeIntervalSinceNow: -3600) // 1 hour ago

            let post2 = Post()
            post2.postId = 2
            post2.uid = "user_456"
            post2.imageUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg"
            post2.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
            post2.description = "Another cool video post!"
            post2.likes = 200
            post2.views = 450
            post2.commentCount = 12
            post2.creationDate = Date(timeIntervalSinceNow: -7200) // 2 hours ago

            let post3 = Post()
            post3.postId = 3
            post3.uid = "user_789"
            post3.imageUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg"
            post3.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
            post3.description = "Yet another post with a video."
            post3.likes = 75
            post3.views = 190
            post3.commentCount = 2
            post3.creationDate = Date(timeIntervalSinceNow: -1800) // 30 mins ago

            let post4 = Post()
            post4.postId = 4
            post4.uid = "user_457"
            post4.imageUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg"
            post4.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
            post4.description = "Fourth video post example."
            post4.likes = 180
            post4.views = 400
            post4.commentCount = 7
            post4.creationDate = Date(timeIntervalSinceNow: -5400) // 1.5 hours ago

            let post5 = Post()
            post5.postId = 5
            post5.uid = "user_780"
            post5.imageUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerJoyrides.jpg"
            post5.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4"
            post5.description = "Fifth sample video post."
            post5.likes = 95
            post5.views = 220
            post5.commentCount = 3
            post5.creationDate = Date(timeIntervalSinceNow: -900) // 15 mins ago

            // Assign all posts to your data source array
            self.posts = [post1, post2, post3, post4, post5]

            DispatchQueue.main.async {
                self.lodingIndicator.stopAnimating()   // Stop loader
                self.collectionView.isHidden = false
                self.collectionView.reloadData()

            }
        }
    }

    //MARK: Actions
    @IBAction func editProfileButton(_ sender: UIButton) {
    }

}
// MARK: - Collection View Data Source/Delegate, and FlowLayout

extension ProfileVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //FlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let size = collectionView.frame.size


        return CGSize(width: size.width / 3 - 2, height: size.height / 3)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }

    //Data Source/Delegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostProfileCVC", for: indexPath) as! PostProfileCVC
        let post = posts[indexPath.item]
        cell.post = post
        return cell
    }



    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerCiewCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ProfileHeaderCRV", for: indexPath) as! ProfileHeaderCRV
            headerCiewCell.setupView()
            if let user = self.user {
                headerCiewCell.user = user

            }
            return headerCiewCell

        }
        return UICollectionReusableView()
    }


}
// MARK: - Extension for Image Loading

extension UIImageView {
    func loadImage(_ urlString: String?) {
        guard let string = urlString, let url = URL(string: string) else {
            self.image = nil
            return
        }

        self.sd_setImage(with: url, placeholderImage: UIImage(named: "Space"))
    }
}
