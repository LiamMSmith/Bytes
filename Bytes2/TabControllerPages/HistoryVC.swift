//
//  HistoryVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import AVFoundation
import AVFAudio

class HistoryVC: UIViewController {
    
    var selectedDate: String?
    let audioEngine = AVAudioEngine()
    let audioPlayer = AVAudioPlayerNode()
    var player: AVPlayer?
    @IBOutlet weak var podcastDateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setPodcastDate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudioPlayback()
    }
    
    func setPodcastDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"

        guard let selectedDate = dateFormatter.date(from: selectedDate!) else {
                print("Error parsing the selected date.")
                return
        }
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let formattedDate = dateFormatter.string(from: selectedDate)
        podcastDateLabel.text = "Podcast from " + formattedDate
    }
    
    @IBAction func playPressed(_ sender: Any) {
        guard let selectedDate = self.selectedDate else {
            print("No selected date")
            return
        }
        self.play(selectedDate: selectedDate)
    }

    func play (selectedDate: String) {
        // Get the current user's ID
        guard let userid = Auth.auth().currentUser?.uid else {
            print("No user ID")
            return
        }
        
        // Get a reference to the Firestore database
        let db = Firestore.firestore()
        
        // Fetch the URLs for the current user and date from Firebase
        let docRef = db.collection("user_calendars").document(userid)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                
                if let urlStringArray = data?[selectedDate] as? [String] {
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
                    print("No audio URLs found for the selected date")
                }
            } else {
                print("Error retrieving user document: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    // Function to stop the audio playback
    func stopAudioPlayback() {
        player?.pause()
        player = nil
    }
    
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var podcastUserPic: UIImageView!
    
    // Play the audio files sequentially
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
