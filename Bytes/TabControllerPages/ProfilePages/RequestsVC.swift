//
//  RequestsVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class RequestsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var requestsTable: UITableView!
    var requesting: [Request] = []
    struct Request {
        let username: String
        let userid: String
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the previously selected row
        if let indexPath = requestsTable.indexPathForSelectedRow {
            requestsTable.deselectRow(at: indexPath, animated: true)
        }
        
        requestsTable.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        requestsTable.register(RequestTableViewCell.self, forCellReuseIdentifier: "RequestCell")

        requestsTable.delegate = self
        requestsTable.dataSource = self
        
        requestsTable.backgroundColor = bytesBeige
        requestsTable.separatorStyle = .singleLine
        requestsTable.separatorColor = bytesPurple

        loadRequesters()
    }

    func loadRequesters() {
        let db = Firestore.firestore()
        guard let userid = Auth.auth().currentUser?.uid else {
            return
        }
        let userRef = db.collection("Users").document(userid)
        
        // Get user's username and requester/requesting counts
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let userRequesting = data?["requestsReceived"] as? [String] ?? []
                // Clear the previous requesters array
                self.requesting.removeAll()
                // Iterate over the documents and extract the requester IDs
                for user in userRequesting {
                    // Get reference to the requester's document
                    let requestRef = db.collection("Users").document(user)

                    // Fetch the requester's document
                    requestRef.getDocument(completion: { (document, error) in
                        if let document = document, document.exists {
                            let data = document.data()
                            
                            // Extract the necessary information (e.g., username)
                            let requestUsername = data?["username"] as? String ?? ""
                            let requestUserid = data?["userID"] as? String ?? ""

                            // Create a requester object with the extracted information
                            let request = Request(username: requestUsername, userid: requestUserid)

                            // Store the requester object in the requesters array
                            self.requesting.append(request)

                            // Reload the table view with the new data
                            self.requestsTable.reloadData()
                        } else {
                            print("Error retrieving requester document: \(error?.localizedDescription ?? "unknown error")")
                        }
                    })
                }
            } else {
                print("Error retrieving user document: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requesting.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! RequestTableViewCell
        let request = requesting[indexPath.row]
        cell.usernameLabel.text = request.username
        cell.acceptButton.tag = indexPath.row
        cell.denyButton.tag = indexPath.row
        cell.acceptButton.addTarget(self, action: #selector(acceptButtonTapped(_:)), for: .touchUpInside)
        cell.denyButton.addTarget(self, action: #selector(denyButtonTapped(_:)), for: .touchUpInside)
        cell.backgroundColor = bytesBeige
        let selectedView = UIView()
        selectedView.backgroundColor = bytesGold
        cell.selectedBackgroundView = selectedView
        cell.textLabel?.textColor = bytesPurple
        return cell
    }

    @objc func acceptButtonTapped(_ sender: UIButton) {
        let request = requesting[sender.tag]
        let acceptedUserID = request.userid
        
        let db = Firestore.firestore()
        guard let userid = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Update the friends and requestsSent arrays for the requester
        let acceptedUserRef = db.collection("Users").document(acceptedUserID)
        acceptedUserRef.updateData([
            "friends": FieldValue.arrayUnion([userid]),
            "requestsSent": FieldValue.arrayRemove([userid])
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
            } else {
                print("User info updated successfully")
            }
        }

        // Update the requestsReceived and friends arrays for the current user
        let userRef = db.collection("Users").document(userid)
        userRef.updateData([
            "requestsReceived": FieldValue.arrayRemove([acceptedUserID]),
            "friends": FieldValue.arrayUnion([acceptedUserID])
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
            } else {
                print("User info updated successfully")
                self.requesting.remove(at: sender.tag)
                self.requestsTable.deleteRows(at: [IndexPath(row: sender.tag, section: 0)], with: .automatic)
            }
        }
    }
    
    @objc func denyButtonTapped(_ sender: UIButton) {
        let request = requesting[sender.tag]
        let deniedUserID = request.userid
        
        let db = Firestore.firestore()
        guard let userid = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Update the requestsSent array for the requester
        let deniedUserRef = db.collection("Users").document(deniedUserID)
        deniedUserRef.updateData([
            "requestsSent": FieldValue.arrayRemove([userid])
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
            } else {
                print("User info updated successfully")
            }
        }
        
        // Update the requestsReceived array for the current user
        let userRef = db.collection("Users").document(userid)
        userRef.updateData([
            "requestsReceived": FieldValue.arrayRemove([deniedUserID])
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
            } else {
                print("User info updated successfully")
                self.requesting.remove(at: sender.tag)
                self.requestsTable.deleteRows(at: [IndexPath(row: sender.tag, section: 0)], with: .automatic)
            }
        }
    }
}
