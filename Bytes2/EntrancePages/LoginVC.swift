//
//  LoginVC.swift
//  Bytes2
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class LoginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the attributedPlaceholder to the text field
        userEmail.attributedPlaceholder = emailAttributedPlaceholder
        userPassword.attributedPlaceholder = passwordAttributedPlaceholder
        
        // Allows user to tap outside of text inputs to exit
        let loginTap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(loginTap)
        userEmail.isUserInteractionEnabled = true
        userPassword.isUserInteractionEnabled = true
        
        // Disables login button until users provide an email and password
        signInButton.isEnabled = false
        signInButton.alpha = 0.5
        userEmail.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        userPassword.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    // Changes the color of the login button based on if user provided all info
    @objc func textFieldDidChange(_ textField: UITextField) {
        if userEmail.text?.isEmpty == true || userPassword.text?.isEmpty == true {
            signInButton.isEnabled = false
            signInButton.alpha = 0.5
        } else {
            signInButton.isEnabled = true
            signInButton.alpha = 1.0
        }
    }

    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    
    @IBAction func signInPressed(_ sender: Any) {
        print("signInPressed")
        // Get email and password from text fields
        guard let email = userEmail.text, let password = userPassword.text else {
            return
        }

        // Sign out previous user
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }

        // Sign in with email and password
        Auth.auth().signIn(withEmail: email, password: password, completion: { (authResult, error) in
            if let error = error {
                // Handle sign-in error
                print("Error signing in: \(error.localizedDescription)")

                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Sign In Error", message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    print("presenting alert")
                    self.present(alertController, animated: true)
                }
            } else {
                if authResult != nil {
                    // User signed in successfully
                    print("User signed in successfully")
                    self.continueToHomePage()
                } else {
                    print("Error signing in: Auth result is nil")
                }
            }
        })
    }
    
    // Brings user to the homepage
    func continueToHomePage() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let tabController = storyboard.instantiateViewController(withIdentifier: "TabController") as? UITabBarController {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let sceneDelegate = windowScene.delegate as? SceneDelegate {
                    sceneDelegate.window?.rootViewController = tabController
                }
            }
        }
    }

    // Bring user to register page
    @IBAction func registerOnLogPressed(_ sender: Any) {
        performSegue(withIdentifier: "LoginToRegister", sender: nil)
    }
}

