//
//  MicVC.swift
//  Bytes2
//

import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseAuth

class MicVC: UIViewController, AVAudioRecorderDelegate {

    var timer: Timer?
    var isPressed = false
    var currentProgress: Float = 0.0
    var startTime: TimeInterval = 0.0
    var remainingTime: TimeInterval = 30.0

    var isRecording = false
    var audioRecorder: AVAudioRecorder?
    var audioURL: URL?
    let storageRef = Storage.storage().reference()
    var progressBarTransform: CGAffineTransform?
    
    let questions = [
        "What did you learn yesterday?",
        "What are your goals for today?",
        "What are you grateful for today?"
    ]
    
    var startDate: Date?
    @IBOutlet weak var dailyQuestion: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let startDate = startDate else {
            return // The start date is not set, do nothing
        }
        
        let calendar = Calendar.current
        let now = Date()

        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
        let questionIndex = daysSinceStart % questions.count
        dailyQuestion.text = questions[questionIndex]
        dailyQuestion.numberOfLines = 0
        
        // setting up progress bar
        progressBar.progress = 0.0
        let progressBarWidth: CGFloat = 250.0
        let progressBarHeight: CGFloat = 50.0
        progressBar.frame = CGRect(x: (view.bounds.width - progressBarWidth) / 2, y: (view.bounds.height - progressBarHeight) / 2, width: progressBarWidth, height: progressBarHeight)
        progressBar.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)

        timerLabel.text = "00:30"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        startDate = dateFormatter.date(from: "2023-05-04") // Set the start date
        
        let progressBarWidth: CGFloat = 235.0
        let progressBarHeight: CGFloat = 50.0
        progressBar.frame = CGRect(x: (view.bounds.width - progressBarWidth) / 2, y: (view.bounds.height - progressBarHeight) / 2, width: progressBarWidth, height: progressBarHeight)
        progressBar.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
            
        // Reload the question for the new start date
        viewDidLoad()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    
    func pickRandomQuestion() {
        // Pick a random question from the array and update the text outlet
        let randomIndex = Int.random(in: 0..<questions.count)
        dailyQuestion.text = questions[randomIndex]
    }
    
    @IBAction func restartRecording(_ sender: Any) {
        // Stop the audio recording if it's in progress
        if isRecording {
            audioRecorder?.stop()
            isRecording = false
        }

        // Reset the progress bar and timer
        progressBar.progress = 0.0
        timerLabel.text = "00:30"

        // Reset the remaining time
        remainingTime = 30.0

        // Invalidate the timer
        timer?.invalidate()

        // Clear the audio URL
        audioURL = nil
    }

    @IBAction func buttonReleased(_ sender: UIButton) {
        isPressed = false
        sender.isEnabled = true
        audioRecorder?.pause()
        
        remainingTime = max(0, 30.0 - (Date().timeIntervalSince1970 - startTime))
        timer?.invalidate()
    }
    
    @IBAction func startProgress(_ sender: UIButton) {
        isPressed = !isPressed
        sender.isEnabled = false

        guard let userid = Auth.auth().currentUser?.uid else {
            return
        }

        // Format the date for the filename on Firebase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let date = dateFormatter.string(from: Date())

        // Filename will be the user's id + the date
        let filename = "\(userid)_\(date).m4a"

        let audioFilename = getDocumentsDirectory().appendingPathComponent(filename)

        if isPressed {
            startTime = Date().timeIntervalSince1970 - (30.0 - remainingTime)

            if audioRecorder == nil {
                // Start recording the audio using AVFoundation
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
                    try audioSession.setActive(true)

                    let settings = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                    audioRecorder?.delegate = self
                    audioRecorder?.record()
                    isRecording = true
                } catch {
                    print("Error starting audio recording: \(error.localizedDescription)")
                }
            } else {
                // Resume the audio recording
                audioRecorder?.record()
                isRecording = true
                isRecording = true
            }
        } else {
            // Pause the audio recording
            audioRecorder?.pause()
            isRecording = false
        }

        let maxRecordingDuration = 30.0

        // Set the timer to update the progress bar and check recording duration
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if self.isPressed {
                let elapsed = Date().timeIntervalSince1970 - self.startTime
                let progress = Float(elapsed / maxRecordingDuration)

                if elapsed >= maxRecordingDuration {
                    // Stop the audio recording
                    self.audioRecorder?.stop()
                    self.isRecording = false

                    timer.invalidate()
                    self.isPressed = false
                    sender.isEnabled = true

                    // Get a reference to the Firebase Storage bucket
                    let storage = Storage.storage()
                    let storageRef = storage.reference()

                    // Get a reference to the audio file
                    let fileURL = audioFilename
                    let audioRef = storageRef.child("personal_recordings/\(date)/\(filename)")

                    // Upload the file to Firebase Storage
                    audioRef.putFile(from: URL(fileURLWithPath: fileURL.path), metadata: nil) { metadata, error in
                        if let error = error {
                            print("Error uploading recording to Firebase: \(error.localizedDescription)")
                        } else {
                            print("Recording uploaded successfully!")
                        }
                    }
                } else {
                    // Update progress bar
                    self.progressBar.progress = progress

                    // Update the timer label with the remaining time
                    let remainingTime = maxRecordingDuration - elapsed
                    let minutes = Int(remainingTime / 60)
                    let seconds = Int(remainingTime) % 60
                    self.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
                }
            } else {
                timer.invalidate()
                self.progressBar.progress = self.currentProgress
                sender.isEnabled = true
            }
        }
    }


    // Gets the current directory for file storage
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
