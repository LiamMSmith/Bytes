//
//  ExploreVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class Query: NSObject, UISearchBarDelegate {
    private var db: Firestore
    private let searchBar: UISearchBar
    weak var searchResultsDelegate: SearchResultsDelegate?

    init(searchBar: UISearchBar) {
        db = Firestore.firestore()
        self.searchBar = searchBar
        super.init()
        self.searchBar.delegate = self
    }

    func searchUsers(withQuery query: String) {
        db.collection("Users").whereField("username", isEqualTo: query).getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }

            if let error = error {
                self.searchResultsDelegate?.didFailWithError(error)
                return
            }

            var matchingUsers: [User] = []

            for document in snapshot!.documents {
                if let user = self.decodeUser(from: document.data()) {
                    matchingUsers.append(user)
                }
            }
            self.searchResultsDelegate?.didReceiveSearchResults(matchingUsers)
        }
    }

    private func decodeUser(from data: [String: Any]) -> User? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            return try JSONDecoder().decode(User.self, from: jsonData)
        } catch {
            print("Error decoding user: \(error.localizedDescription)")
            return nil
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else {
            return
        }

        searchUsers(withQuery: query)
        searchBar.resignFirstResponder()
    }
}

protocol SearchResultsDelegate: AnyObject {
    func didReceiveSearchResults(_ results: [User])
    func didFailWithError(_ error: Error)
}

class ExploreVC: UIViewController, UITableViewDataSource, SearchResultsDelegate, UITableViewDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var exploreTableView: UITableView!
    var selectedUserID: String?

    var query: Query!
    var searchResults: [User] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the previously selected row
        if let indexPath = exploreTableView.indexPathForSelectedRow {
            exploreTableView.deselectRow(at: indexPath, animated: true)
        }
        
        // Reload the table data
        exploreTableView.reloadData()
        
        // Reset selectedUserID
        selectedUserID = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        query = Query(searchBar: searchBar)
        query.searchResultsDelegate = self

        exploreTableView.delegate = self
        exploreTableView.dataSource = self
        exploreTableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        exploreTableView.backgroundColor = bytesBeige
        exploreTableView.separatorStyle = .singleLine
        exploreTableView.separatorColor = bytesPurple
        
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = bytesBeige
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            searchField.backgroundColor = bytesGold
            searchField.textColor = bytesPurple
            if let searchIconView = searchField.leftView as? UIImageView {
                searchIconView.tintColor = bytesPurple
            }
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: bytesPurple!,
            ]
            let attributedPlaceholder = NSAttributedString(string: "Search", attributes: placeholderAttributes)
            searchField.attributedPlaceholder = attributedPlaceholder
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        searchBar.isUserInteractionEnabled = true
    }
    
    @objc func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }

    func didReceiveSearchResults(_ results: [User]) {
        searchResults = results
        exploreTableView.reloadData()
    }

    func didFailWithError(_ error: Error) {
        print("Error searching users: \(error.localizedDescription)")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let selectedUserID = selectedUserID {
            return searchResults.filter { $0.userID != selectedUserID }.count
        }
        return searchResults.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        var user: User
        if let selectedUserID = selectedUserID {
            user = searchResults.filter { $0.userID != selectedUserID }[indexPath.row]
        } else {
            user = searchResults[indexPath.row]
        }
        cell.textLabel?.text = user.username
        cell.backgroundColor = bytesBeige
        let selectedView = UIView()
        selectedView.backgroundColor = bytesGold
        cell.selectedBackgroundView = selectedView
        cell.textLabel?.textColor = bytesPurple
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = searchResults[indexPath.row]
        selectedUserID = selectedUser.userID
        
        performSegue(withIdentifier: "toDisplayUser", sender: selectedUserID)
        
        exploreTableView.reloadData()
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDisplayUser",
            let selectedUserID = sender as? String,
            let destinationVC = segue.destination as? DisplayUserVC {
            destinationVC.selectedUser = selectedUserID
        }
    }
}
