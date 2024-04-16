//
//  HomeVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import AVFoundation
import AVFAudio

class HomeVC: UIViewController {

    let audioEngine = AVAudioEngine()
    let audioPlayer = AVAudioPlayerNode()
    var player: AVPlayer?
    
    @IBOutlet weak var recordAlert: UILabel!
    @IBOutlet weak var playPodcastButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the userIDLabel initially
        userIDLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Homepage loaded")
        checkPersonalPodcast()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudioPlayback()
    }

    func checkPersonalPodcast() {
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "dd-MM-yyyy"
           let date = dateFormatter.string(from: Date())
           
           guard let userid = Auth.auth().currentUser?.uid else {
               print("No userid")
               return
           }
           
           let db = Firestore.firestore()
           
           // Check if the user has a file in personal_recordings for the specific day
           let personalRecordingURL = "personal_recordings/\(date)/\(userid)_\(date).m4a"
           let storageRef = Storage.storage().reference().child(personalRecordingURL)

           storageRef.downloadURL { (url, error) in
               if let _ = error {
                   print("User \(userid) hasn't recorded for \(date) yet")
                   self.recordAlert.text = "Record your daily byte!"
                   self.recordAlert.numberOfLines = 0 // enable multiline
                   self.disableButton()
               } else {
                   // Check if the user's podcast has been created already
                   let userCalendarRef = db.collection("user_calendars").document(userid)
                   userCalendarRef.getDocument(completion: { (document, error) in
                       if let document = document, document.exists {
                           let data = document.data()
                           if let _ = data?[date] as? [String] {
                               print("Podcast exists for \(date) and user \(userid)")
                           } else {
                               print("Podcast does not exist for \(date) and user \(userid)")
                           }
                       }
                       self.loadFollowingList(date: date, userid: userid)
                   })
               }
           }
       }

    func loadFollowingList(date: String, userid: String) {
           let db = Firestore.firestore()

           // Retrieve the user's following list
           let friendRef = db.collection("Users").document(userid)
           var friends: [String] = []
           friendRef.getDocument { (document, error) in
               if let document = document, document.exists {
                   let data = document.data()
                   friends = data?["friends"] as? [String] ?? []
                   self.loadURLsAndUpload(date: date, userid: userid, friends: friends)
               } else {
                   print("Error retrieving user document: \(error?.localizedDescription ?? "unknown error")")
               }
           }
       }


       func loadURLsAndUpload(date: String, userid: String, friends: [String]) {
           let group = DispatchGroup()
           var audioURLs: [URL] = []

           for friendID in friends {
               let personalRecordingURL = "personal_recordings/\(date)/\(friendID)_\(date).m4a"
               let storageRef = Storage.storage().reference().child(personalRecordingURL)

               group.enter()
               storageRef.downloadURL { (url, error) in
                   defer {
                       group.leave()
                   }

                   if error != nil {
                       print("User \(friendID) has not recorded")
                       // Skip this user and continue to the next one
                       return
                   } else if let downloadURL = url {
                       audioURLs.append(downloadURL)
                   }
               }
           }

           group.notify(queue: .main) {
               print("URLs to upload: \(audioURLs)")
               self.uploadURLsToFirebase(urls: audioURLs, userid: userid, date: date)
           }
       }

    func uploadURLsToFirebase(urls: [URL], userid: String, date: String) {
        if !urls.isEmpty {
            let urlStringArray = urls.map { $0.absoluteString }
            let db = Firestore.firestore()

            let userCalendarRef = db.collection("user_calendars").document(userid)

            userCalendarRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    var data = document.data() ?? [:]
                    data[date] = urlStringArray
                    userCalendarRef.setData(data) { error in
                        if let error = error {
                            print("Error storing user object: \(error.localizedDescription)")
                        } else {
                            print("User object stored successfully")
                        }
                    }
                } else {
                    // User calendar document doesn't exist, create a new document
                    let data: [String: Any] = [date: urlStringArray]
                    userCalendarRef.setData(data) { error in
                        if let error = error {
                            print("Error storing user object: \(error.localizedDescription)")
                        } else {
                            print("User object stored successfully")
                        }
                    }
                }
            }
            self.recordAlert.text = "Play your podcast!"
            self.allowButton()
        } else {
            self.recordAlert.text = "Waiting for your friends to record their bytes!"
            self.recordAlert.numberOfLines = 0 // Enable multiline
            self.disableButton()
        }
    }
    
    func allowButton() {
        self.playPodcastButton.isUserInteractionEnabled = true
    }

    func disableButton() {
        self.playPodcastButton.isUserInteractionEnabled = false
    }
    
    @IBAction func playPodcastButtonPressed(_ sender: Any) {
        // Get today's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let date = dateFormatter.string(from: Date())
        
        // Get the current user's ID
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID")
            return
        }
        
        // Get a reference to the Firestore database
        let db = Firestore.firestore()
        
        // Fetch the URLs for the current user and date from Firebase
        let docRef = db.collection("user_calendars").document(userId)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                
                if let urlStringArray = data?[date] as? [String] {
                    // Create an empty array to hold the URLs
                    var urls: [URL] = []
                    
                    // Convert the string URLs to actual URL objects
                    for urlString in urlStringArray {
                        if let url = URL(string: urlString) {
                            urls.append(url)
                        }
                    }
                    
                    // Call the function to play the audio files sequentially
                    self.playAudioFiles(urls: urls)
                } else {
                    print("No audio URLs found for the current user and date")
                }
            } else {
                print("Error retrieving user document: \(error?.localizedDescription ?? "unknown error")")
            }
        }
        // Show the userIDLabel
        userIDLabel.isHidden = false
    }
    
    // Function to stop the audio playback
    func stopAudioPlayback() {
        player?.pause()
        player = nil
    }
    
    @IBOutlet weak var podcastUserPic: UIImageView!
    @IBOutlet weak var userIDLabel: UILabel!
    func playAudioFiles(urls: [URL]) {
        var currentIndex = 0

        func playNextAudio() {
            guard currentIndex < urls.count else {
                stopAudioPlayback()
                return
            }

            let url = urls[currentIndex]
            let playerItem = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: playerItem)

            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil) { _ in
                // Audio playback finished, play the next audio file
                currentIndex += 1
                playNextAudio()
            }

            // Extract userID from the URL
            let userID = extractUserID(from: url)

            retrieveUserData(for: userID ?? "") { username, imageURL in
                DispatchQueue.main.async {
                    // Set the label with the username
                    self.userIDLabel.text = "\(username ?? "")"
                    
                    // Set the user's image
                    if let imageURL = imageURL {
                        // Load the image asynchronously
                        URLSession.shared.dataTask(with: imageURL) { data, _, error in
                            if let error = error {
                                print("Error loading image: \(error.localizedDescription)")
                                return
                            }
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    // Set the image on the UI
                                    self.podcastUserPic.image = image
                                }
                            }
                        }.resume()
                    }
                }
            }

            self.player?.play()
            print("Playing: \(url)")
        }

        // Start playing the first audio file
        playNextAudio()
    }
    
    // Extract the userID from the URL
    func extractUserID(from url: URL) -> String? {
        guard let urlString = url.absoluteString.removingPercentEncoding else {
            return nil
        }
        
        // Extract the userID from the URL using a regular expression
        let pattern = #"/([^/]+)_\d{2}-\d{2}-\d{4}"#
        if let range = urlString.range(of: pattern, options: .regularExpression) {
            let matchedString = urlString[range]
            
            // Extract the date from the matched string using a regular expression
            let datePattern = #"\d{2}-\d{2}-\d{4}"#
            if let dateRange = matchedString.range(of: datePattern, options: .regularExpression) {
                let date = matchedString[dateRange]
                
                // Remove the date portion from the matched string
                let userid = matchedString.replacingOccurrences(of: "\(date)", with: "").replacingOccurrences(of: "/", with: "").replacingOccurrences(of: "_", with: "")
                
                return userid
            }
        }
        
        return nil
    }

    
    // Retrieve the username and image associated with the userID
    func retrieveUserData(for userid: String, completion: @escaping (String?, URL?) -> Void) {
        let db = Firestore.firestore()
        print(userid)
        let userRef = db.collection("Users").document(userid)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let retrievedUsername = data?["username"] as? String,
                   let imageURLString = data?["userPic"] as? String,
                   let imageURL = URL(string: imageURLString) {
                    completion(retrievedUsername, imageURL)
                } else {
                    completion(nil, nil)
                }
            } else {
                print("Error retrieving user profile document: \(error?.localizedDescription ?? "unknown error")")
                completion(nil, nil)
            }
        }
    }
}
