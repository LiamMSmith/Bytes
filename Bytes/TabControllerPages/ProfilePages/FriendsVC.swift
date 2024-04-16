//
//  FriendsVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var friendTable: UITableView!
    var friends: [Friend] = []
    struct Friend {
        let username: String
        let userid: String
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        friendTable.backgroundColor = .white
        friendTable.register(UITableViewCell.self, forCellReuseIdentifier: "FriendCell")

        friendTable.delegate = self
        friendTable.dataSource = self
        
        friendTable.backgroundColor = bytesBeige
        friendTable.separatorStyle = .singleLine
        friendTable.separatorColor = bytesPurple

        loadFriends()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the previously selected row
        if let indexPath = friendTable.indexPathForSelectedRow {
            friendTable.deselectRow(at: indexPath, animated: true)
        }
        
        // Reload the table data
        friendTable.reloadData()
    }


    func loadFriends() {
        let db = Firestore.firestore()
        guard let userid = Auth.auth().currentUser?.uid else {
            return
        }
        let userRef = db.collection("Users").document(userid)
        
        // Get user's username and friend counts
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let userFriends = data?["friends"] as? [String] ?? []
                // Clear the previous friends array
                self.friends.removeAll()
                // Iterate over the documents and extract the friend IDs
                for user in userFriends {
                    // Get reference to the friend's document
                    let friendRef = db.collection("Users").document(user)

                    // Fetch the friend's document
                    friendRef.getDocument(completion: { (document, error) in
                        if let document = document, document.exists {
                            let data = document.data()
                            
                            // Extract the necessary information (e.g., username)
                            let friendUsername = data?["username"] as? String ?? ""
                            let friendUserid = data?["userID"] as? String ?? ""

                            // Create a friend object with the extracted information
                            let friend = Friend(username: friendUsername, userid: friendUserid)

                            // Store the friend object in the friends array
                            self.friends.append(friend)

                            // Reload the table view with the new data
                            self.friendTable.reloadData()
                        } else {
                            print("Error retrieving friend document: \(error?.localizedDescription ?? "unknown error")")
                        }
                    })
                }
            } else {
                print("Error retrieving user document: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return friends.count
        }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = friendTable.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath)
        let friend = friends[indexPath.row]
        cell.textLabel?.text = friend.username
        cell.textLabel?.textColor = bytesPurple
        cell.backgroundColor = bytesBeige
        
        let selectedView = UIView()
        selectedView.backgroundColor = bytesGold
        cell.selectedBackgroundView = selectedView
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friend = friends[indexPath.row]
        let selectedUser = friend.userid
        
        performSegue(withIdentifier: "toDisplayUser", sender: selectedUser)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDisplayUser",
           let selectedUserID = sender as? String,
           let destinationVC = segue.destination as? DisplayUserVC {
            destinationVC.selectedUser = selectedUserID
        }
    }
}







