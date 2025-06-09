//
//  HomeVC.swift
//

import UIKit

class HomeVC: UIViewController {
    
    //MARK: Properties/Outlets
    @IBOutlet private var collectionView: UICollectionView!
    
    private var posts = [Post]()
    private var users = [User]()

    private var user = [User]()


    @objc dynamic var currentIndex = 0
    private var oldAndNewIndices = (0,0)

    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadPosts()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTappedOutside(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let videoCells = collectionView.visibleCells.compactMap { $0 as? HomeCollectionViewCell } as? [HomeCollectionViewCell] ?? []

        var playBounds = collectionView.bounds
        playBounds.origin.y += playBounds.height / 3
        playBounds.size.height -= playBounds.height * 2.0 / 3.0

        if let centerCell = videoCells.first(where: {
            let videoRect = $0.postVideo.convert($0.postVideo.bounds, to: collectionView)
            return videoRect.intersects(playBounds)
        }) {
            centerCell.play(forced: false)
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let videoCells = collectionView.visibleCells.compactMap { $0 as? HomeCollectionViewCell } as? [HomeCollectionViewCell] ?? []

        var playBounds = collectionView.bounds
        playBounds.origin.y += playBounds.height / 3
        playBounds.size.height -= playBounds.height * 2.0 / 3.0

        if let centerCell = videoCells.first(where: {
            let videoRect = $0.postVideo.convert($0.postVideo.bounds, to: collectionView)
            return videoRect.intersects(playBounds)
        }) {
            centerCell.pause(forced: false)
        }

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Force `scrollViewDidScroll` call to initialize player state
        scrollViewDidScroll(collectionView)
    }

    //MARK: Actions
    
    @objc func viewTappedOutside(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self.view)
        if let tappedView = self.view.hitTest(tapLocation, with: nil), tappedView.isDescendant(of: collectionView) {
        }
    }
    
    
    // MARK: - Setup Methods
    func setupCollectionView(){
        
        collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = createFlowLayout()
        collectionView.backgroundColor = .black
        
        tabBarController?.tabBar.barTintColor = .black
        tabBarController?.tabBar.tintColor = .black

    }
    
    
    // MARK: - DATA & SERVICE
    
    func loadPosts(){

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {

            let post1 = Post()
            post1.postId = 1
            post1.uid = "user_123"
            post1.imageUrl = "https://example.com/image1.jpg"
            post1.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4"
            post1.description = "This is the first sample video post."
            post1.likes = 120
            post1.views = 300
            post1.commentCount = 5
            post1.creationDate = Date(timeIntervalSinceNow: -3600) // 1 hour ago
            post1.duration = 15.0

            let post2 = Post()
            post2.postId = 2
            post2.uid = "user_456"
            post2.imageUrl = "https://example.com/image2.jpg"
            post2.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4"
            post2.description = "Another cool video post!"
            post2.likes = 200
            post2.views = 450
            post2.commentCount = 12
            post2.creationDate = Date(timeIntervalSinceNow: -7200) // 2 hours ago
            post2.duration = 15.0

            let post3 = Post()
            post3.postId = 3
            post3.uid = "user_789"
            post3.imageUrl = "https://example.com/image3.jpg"
            post3.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
            post3.description = "Yet another post with a video."
            post3.likes = 75
            post3.views = 190
            post3.commentCount = 2
            post3.creationDate = Date(timeIntervalSinceNow: -1800) // 30 mins ago
            post3.duration = 60.0

            let post4 = Post()
            post4.postId = 4
            post4.uid = "user_457"
            post4.imageUrl = "https://example.com/image2.jpg"
            post4.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
            post4.description = "Another cool video post!"
            post4.likes = 200
            post4.views = 450
            post4.commentCount = 12
            post4.creationDate = Date(timeIntervalSinceNow: -7200) // 2 hours ago
            post4.duration = 15.0

            let post5 = Post()
            post5.postId = 5
            post5.uid = "user_780"
            post5.imageUrl = "https://example.com/image3.jpg"
            post5.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
            post5.description = "Yet another post with a video."
            post5.likes = 75
            post5.views = 190
            post5.commentCount = 2
            post5.creationDate = Date(timeIntervalSinceNow: -1800) // 30 mins ago
            post5.duration = 15.0
            
            // Assigning the hardcoded posts
            self.posts = [post1, post2, post3, post4, post5]


            let user1 = User()
            user1.uid = "user_123"
            user1.username = "azim"
            user1.email = "azim@example.com"
            user1.profileImageUrl = "https://i.pravatar.cc/150?img=1"
            user1.status = "Active"

            let user2 = User()
            user2.uid = "user_456"
            user2.username = "john"
            user2.email = "john@example.com"
            user2.profileImageUrl = "https://i.pravatar.cc/150?img=2"
            user2.status = "Busy"

            let user3 = User()
            user3.uid = "user_789"
            user3.username = "emily"
            user3.email = "emily@example.com"
            user3.profileImageUrl = "https://i.pravatar.cc/150?img=3"
            user3.status = "Away"

            let user4 = User()
            user4.uid = "user_457"
            user4.username = "noah"
            user4.email = "noah@example.com"
            user4.profileImageUrl = "https://i.pravatar.cc/150?img=4"
            user4.status = "Offline"

            let user5 = User()
            user5.uid = "user_780"
            user5.username = "sophia"
            user5.email = "sophia@example.com"
            user5.profileImageUrl = "https://i.pravatar.cc/150?img=5"
            user5.status = "Online"

            self.users = [user1, user2, user3, user4, user5]

            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

}

// MARK: - Cell Playback Control, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension HomeVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "homeCell", for: indexPath) as! HomeCollectionViewCell
        let post = posts[indexPath.item]
        let user = users[indexPath.item]
        cell.post = post
        cell.user = user
        cell.backgroundColor = UIColor.black
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = collectionView.frame.size
        return CGSize(width: size.width, height: size.height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets{
        
        return  UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    //Flow Layout
    
    private func createFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        return layout
    }
}

// MARK: - UIScrollViewDelegate


extension HomeVC: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let videoCells = collectionView.visibleCells.compactMap { $0 as? HomeCollectionViewCell } as? [HomeCollectionViewCell] ?? []

        var playBounds = scrollView.bounds
        playBounds.origin.y += playBounds.height / 3
        playBounds.size.height -= playBounds.height * 2.0 / 3.0

        if let centerCell = videoCells.first(where: {
            let videoRect = $0.postVideo.convert($0.postVideo.bounds, to: scrollView)
            return videoRect.intersects(playBounds)
        }) {
            centerCell.play(forced: false)
        } else {
            VideoPlayerView.pauseAll()
        }

    }

}
