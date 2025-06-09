//
//  Post.swift
//

import Foundation

class Post {
    var uid: String?
    var postId: Int?
    var videoUrl: String?
    var imageUrl: String?
    var description: String?
    var creationDate: Date?
    var likes :Int?
    var views: Int?
    var commentCount: Int?
    var duration: Double?

    static func transformPostVideo(dict: Dictionary<String, Any>, key: String) -> Post {
        let post = Post()
        if let postIdInt = Int(key) {
            post.postId = postIdInt
        } else if let postIdFromDict = dict["postId"] as? Int {
            post.postId = postIdFromDict
        } else if let postIdString = dict["postId"] as? String, let postIdInt = Int(postIdString) {
            post.postId = postIdInt
        } else {
            post.postId = nil  // Could not parse, keep it nil
        }
        post.uid = dict["uid"] as? String
        post.imageUrl = dict["imageUrl"] as? String
        post.videoUrl = dict["videoUrl"] as? String
        post.description = dict["description"] as? String
        post.likes = dict["likes"] as? Int
        post.views = dict["views"] as? Int
        post.commentCount = dict["commentCount"] as? Int
        post.duration = dict["duration"] as? Double

        let creationDouble = dict["creationDate"] as? Double ?? 0
        post.creationDate = Date(timeIntervalSince1970: creationDouble)
        
        return post
    }
}
