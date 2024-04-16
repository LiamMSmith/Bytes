//
//  RegisterVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import TOCropViewController

class RegisterVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TOCropViewControllerDelegate {
    
    var hasSelectedImage = false
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userEmail.attributedPlaceholder = emailAttributedPlaceholder
        userPassword.attributedPlaceholder = passwordAttributedPlaceholder
        username.attributedPlaceholder = usernameAttributedPlaceholder
    
        // Allows user to tap outside of text inputs to exit
        let regTap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(regTap)
        userEmail.isUserInteractionEnabled = true
        userPassword.isUserInteractionEnabled = true
        username.isUserInteractionEnabled = true
        
        // Disables login button until users provide an email and password
        registerButton.isEnabled = false
        registerButton.alpha = 0.5
        userEmail.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        userPassword.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        username.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // Set the default profile picture if the user has not selected an image
        if !hasSelectedImage {
            let defaultProfilePic = UIImage(named: "logoProfilePic")
            profilePic.image = defaultProfilePic
        }
        
        // Set up the activity indicator
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = bytesGold
        activityIndicator.hidesWhenStopped = true
        profilePic.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: profilePic.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: profilePic.centerYAnchor)
        ])
    }
    
    // Changes the color of the reg button based on if user provided all info
    @objc func textFieldDidChange(_ textField: UITextField) {
        if userEmail.text?.isEmpty == true || userPassword.text?.isEmpty == true || username.text?.isEmpty == true {
            registerButton.isEnabled = false
            registerButton.alpha = 0.5
        } else {
            registerButton.isEnabled = true
            registerButton.alpha = 1.0
        }
    }
    

    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    
    @IBAction func registerPressed(_ sender: Any) {
        guard let email = userEmail.text,
              let password = userPassword.text,
              let username = username.text,
              let image = profilePic.image else {
            print("Error: Please fill in all required fields")
            return
        }

        // Register user with Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")

            } else {
                print("User created successfully!")
                
                // Get a reference to the Firebase Storage
                let storage = Storage.storage()
                
                // Create a reference to the user's profile picture file in Firebase Storage
                let imageRef = storage.reference().child("profile_images/\(authResult!.user.uid).png")
                
                // Compress the image
                guard let compressedImage = image.compressImage() else {
                    print("Error compressing image.")
                    return
                }
                
                // Convert the compressed image to PNG data
                guard let imageData = compressedImage.pngData() else {
                    print("Error converting image to PNG data.")
                    return
                }
                
                // Upload the compressed profile picture data to Firebase Storage
                imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                    if let error = error {
                        print("Error uploading profile image: \(error.localizedDescription)")
                        return
                    }
                    
                    // Get the download URL of the uploaded profile picture file
                    imageRef.downloadURL { (url, error) in
                        if let error = error {
                            print("Error getting profile image download URL: \(error.localizedDescription)")
                            return
                        }
                        
                        // Get the date the user joined bytes
                        let currentDate = Date()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MMMM d, yyyy"
                        let joinDate = dateFormatter.string(from: currentDate)
                        
                        // Create a User object with the download URL of the user's profile picture
                        let user = User(userID: authResult?.user.uid ?? "", username: username, userPic: url?.absoluteString ?? "", friends: [], requestsReceived: [], requestsSent: [], joinDate: joinDate)
                        
                        // Get a reference to the Firestore database
                        let db = Firestore.firestore()
                        
                        // Store the user object in the "Users" collection with the user's id as the document ID
                        db.collection("Users").document(authResult?.user.uid ?? "").setData(user.dictionaryRepresentation()) { error in
                            if let error = error {
                                print("Error storing user object: \(error.localizedDescription)")
                            } else {
                                print("User object stored successfully")
                                self.performSegue(withIdentifier: "RegisterToTabController", sender: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Check for when segue happens
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RegisterToTabController" {
            print("RegisterToTabController segue hit")
        }
    }
    
    // Bring user back to login page
    @IBAction func loginOnRegPressed(_ sender: Any) {
        performSegue(withIdentifier: "RegisterToLogin", sender: nil)
    }
    
    // Allows user to choose their profile picture
    @IBAction func editPressed(_ sender: Any) {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.sourceType = .photoLibrary
        imagePickerVC.delegate = self
        present(imagePickerVC, animated: true) {
            self.activityIndicator.stopAnimating()
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        if let image = info[.originalImage] as? UIImage {
            let cropViewController = TOCropViewController(croppingStyle: .circular, image: image)
            cropViewController.delegate = self
            cropViewController.aspectRatioPreset = .presetSquare
            present(cropViewController, animated: true, completion: nil)
            
            hasSelectedImage = true
        }
    }

    func cropViewController(_ cropViewController: TOCropViewController, didCropToCircularImage image: UIImage, with cropRect: CGRect, angle: Int) {
        profilePic.image = image
        cropViewController.dismiss(animated: true, completion: nil)
    }

    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

extension UIImage {
    func compressImage() -> UIImage? {
        let maxWidth: CGFloat = 1024.0
        let maxHeight: CGFloat = 1024.0
        
        var size = self.size
        var scale: CGFloat = 0.7
        
        if size.width > maxWidth || size.height > maxHeight {
            if size.width > size.height {
                scale = maxWidth / size.width
            } else {
                scale = maxHeight / size.height
            }
            
            let newWidth = size.width * scale
            let newHeight = size.height * scale
            size = CGSize(width: newWidth, height: newHeight)
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: size))
        
        guard let compressedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        return compressedImage
    }
}

