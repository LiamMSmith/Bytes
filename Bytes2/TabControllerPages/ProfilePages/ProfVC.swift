//
//  ProfVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class ProfVC: UIViewController {

    @IBOutlet weak var userProfilePic: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var friendsCount: UILabel!
    @IBOutlet weak var requestsCount: UILabel!
    @IBOutlet weak var requestsButton: UIButton!
    @IBOutlet weak var requestsStack: UIStackView!
    @IBOutlet weak var friendsStack: UIStackView!
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var bytesRecordedStack: UIStackView!
    @IBOutlet weak var bytesCount: UILabel!
    @IBOutlet weak var joinDate: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserProfile()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func loadUserProfile() {
        // Get the current user's ID
        guard let userid = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get a reference to the Firebase storage service
        let storage = Storage.storage()
        
        // Get a reference to the user's profile image in Firebase storage
        let profileImageRef = storage.reference().child("profile_images/\(userid).png")
        
        // Download the user's profile image from Firebase storage
        profileImageRef.getData(maxSize: 3 * 1024 * 1024) { (data, error) in
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")
                // Set a default image
                self.userProfilePic.image = UIImage(systemName: "logoProfilePic")?.withTintColor(bytesGold!)
                return
            }
            
            guard let data = data, let profileImage = UIImage(data: data) else {
                print("Error creating profile image from data.")
                // Set a default image
                self.userProfilePic.image = UIImage(systemName: "person.circle.fill")?.withTintColor(bytesGold!)
                return
            }
            
            // Set the profile image
            self.userProfilePic.image = profileImage
        }
        
        // Get access to user's db
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userid)
        
        // Get user's username and friends/requests counts
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let username = data?["username"] as? String ?? ""
                self.username.text = username
                self.username.adjustsFontSizeToFitWidth = true
                self.username.minimumScaleFactor = 0.5
                self.username.numberOfLines = 1
                let friends = data?["friends"] as? [String] ?? []
                let requests = data?["requestsReceived"] as? [String] ?? []
                self.friendsCount.text = String(friends.count)
                self.requestsCount.text = String(requests.count)
                let joinDate = data?["joinDate"] as? String ?? ""
                self.joinDate.text = joinDate
            } else {
                print("Error retrieving user document: \(error?.localizedDescription ?? "unknown error")")
            }
        }
        
        // Get user's bytes count
        let userCalendarRef = db.collection("user_calendars").document(userid)
        userCalendarRef.getDocument(completion: { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                
                if let dateKeys = data?.keys {
                    let count = dateKeys.count
                    self.bytesCount.text = "\(count)"
                }
            }
        })
    }
}


