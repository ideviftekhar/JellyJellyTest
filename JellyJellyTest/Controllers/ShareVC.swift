//
//  ShareVC.swift
//

import UIKit
import Foundation
import AVFoundation


class ShareVC: UIViewController, UITextViewDelegate {

    @IBOutlet private var textView: UITextView!
    @IBOutlet private var thumbImageView: UIImageView!
    @IBOutlet private var selectLabel: UILabel!

    @IBOutlet private var postBut: UIButton!
    @IBOutlet private var draftsBut: UIButton!

    @IBOutlet private var backButton: UIBarButtonItem!
    @IBOutlet private var toWhatsapp: UIButton!
    @IBOutlet private var toSnapchat: UIButton!
    @IBOutlet private var toInstagram: UIButton!

    private let placeholder = "Write your explanation about the content."

    private let originalVideoUrl: URL
    private var encodedVideoURL: URL?
    var selectedPhoto : UIImage?

    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupView()
        hideKeyboard()
        loadThumb()
        saveToServer()

        overrideUserInterfaceStyle = .light
        view.backgroundColor = .white

    }


    init?(coder: NSCoder, videoUrl: URL) {
        self.originalVideoUrl = videoUrl
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideTabBarAndNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showTabBarAndNavigationBar()
    }

    //MARK: Setup Methods

    private func setupView(){
        draftsBut.layer.borderColor = UIColor.lightGray.cgColor
        draftsBut.layer.borderWidth = 0.3
        draftsBut.layer.cornerRadius = 15

        postBut.layer.cornerRadius = 15

        toWhatsapp.contentMode = .scaleAspectFit

        backButton.target = self
        backButton.action = #selector(backToPreviewVC)

    }


    private func setupTextView(){
        textView.delegate = self
        textView.text = placeholder
        textView.textColor = .lightGray
    }


    private func loadThumb(){
        if let thumbnailImage = self.thumbnailImageForFileUrl(originalVideoUrl) {
            self.selectedPhoto = thumbnailImage.imageRotated(by: Double.pi/2)
            thumbImageView.image = thumbnailImage.imageRotated(by: Double.pi/2)
        }
    }

    // MARK: - Thumbnail Generator


    func thumbnailImageForFileUrl(_ fileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 7, timescale: 1), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        } catch {
            print(error)
        }
        return nil
    }

    // MARK: - Button Actions

    @IBAction func backToPreviewVC() {



        if let navController = navigationController {
            navController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    private func resetToRootAndSwitchTab(_ tabBarController: CustomTabBarController) {
        // Loop through each nav controller and pop to root
        tabBarController.viewControllers?.forEach {
            if let navVC = $0 as? UINavigationController {
                navVC.popToRootViewController(animated: false)
            }
        }

        // Switch to Home tab (replace 2 with your desired index)
        tabBarController.selectedIndex = 2
    }
    @IBAction func postButton(_ sender: UIButton) {

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let tabBarController = window.rootViewController as? CustomTabBarController else {
            return
        }

        tabBarController.selectedIndex = 2

        // Dismiss any presented VC from tab bar
        if let presentedVC = tabBarController.presentedViewController {
            presentedVC.dismiss(animated: false) {
                self.resetToRootAndSwitchTab(tabBarController)
            }
        } else {
            self.resetToRootAndSwitchTab(tabBarController)
        }
    }

    // MARK: - Save Video to Server

    func saveToServer(){
        saveVideoToServer(sourceURL: originalVideoUrl) {[weak self] (outputURL) in
            self?.encodedVideoURL = outputURL
        }
    }
}

// MARK: - UITextViewDelegate

extension ShareVC{

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeholder
            textView.textColor = .lightGray
        }
    }

}
