//
//  DisplayUserVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class DisplayUserVC: UIViewController {
    
    var selectedUser: String!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var userPic: UIImageView!
    @IBOutlet weak var friendsCount: UILabel!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var bytesCount: UILabel!
    @IBOutlet weak var friendLabel: UIButton!
    @IBOutlet weak var joinDate: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkRequest()
        loadRequestProfile()
        friendLabel.isUserInteractionEnabled = false
        friendLabel.alpha = 1.0
    }
    
    func checkRequest() {
        guard let userid = Auth.auth().currentUser?.uid else {
            return
        }
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userid)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let requestsSent = data?["requestsSent"] as? [String] ?? []
                if requestsSent.contains(self.selectedUser) {
                    self.requestButton.setTitle("Requested", for: .normal)
                    self.requestButton.isUserInteractionEnabled = false
                }
                
                let friends = data?["friends"] as? [String] ?? []
                if friends.contains(self.selectedUser) {
                    self.requestButton.setTitle("Request Accepted", for: .normal)
                    self.requestButton.isUserInteractionEnabled = false
                }
            } else {
                print("Error retrieving user document: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    func loadRequestProfile() {
        guard let userid = self.selectedUser else {
            print("No selected user")
            return
        }
        
        // Get a reference to the Firebase storage service
        let storage = Storage.storage()
        
        // Get a reference to the user's profile image in Firebase storage
        let profileImageRef = storage.reference().child("profile_images/\(self.selectedUser ?? "").png")
        
        // Download the user's profile image from Firebase storage
        profileImageRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let profileImage = UIImage(data: data) else {
                print("Error creating profile image from data.")
                return
            }
            
            // Set the profile image
            self.userPic.image = profileImage
        }
        
        // Get access to user's db
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userid)
        
        // Get user's username and follower/following counts
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let username = data?["username"] as? String ?? ""
                self.username.text = username
                self.username.adjustsFontSizeToFitWidth = true
                self.username.minimumScaleFactor = 0.5
                self.username.numberOfLines = 1
                let friends = data?["friends"] as? [String] ?? []
                self.friendsCount.text = String(friends.count)
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
    
    @IBAction func requestPressed(_ sender: Any) {
        guard let userid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        
        // Update the requestsReceived arrays for the requester
        let requestedUserRef = db.collection("Users").document(self.selectedUser!)
        requestedUserRef.updateData([
            "requestsReceived": FieldValue.arrayUnion([userid])
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
            } else {
                print("User info updated successfully")
            }
        }

        // Update the requestsSent array for the current user
        let userRef = db.collection("Users").document(userid)
        userRef.updateData([
            "requestsSent": FieldValue.arrayUnion([self.selectedUser!]),
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
            } else {
                print("User info updated successfully")
                self.requestButton.setTitle("Requested", for: .normal)
                self.requestButton.isUserInteractionEnabled = false
            }
        }
    }
}
