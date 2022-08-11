//
//  LoginVC.swift
//  Project_Group 11
//
//  Created by Yuk Fai Hsu on 2022-05-22.
//


import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class LoginVC: UIViewController {
    
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var lblError: UILabel!
    @IBOutlet weak var switchRememberMe: UISwitch!
    
    let db = Firestore.firestore()
    let defaults:UserDefaults = UserDefaults.standard
    var rememberMe:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // MARK: REMEMBER ME checking
        // Check whether "Remember Me" is On during last Login.
        // If last time, the user logged out, "Remember Me" will also be Off.
        // If "Remember Me" is On, the app will log in automatically.
        self.rememberMe = self.defaults.bool(forKey: "REMEMBER_ME")
        if self.rememberMe{
            guard let nextScreen = self.storyboard?.instantiateViewController(withIdentifier: "problemList") as? ProblemListVC else{
                print(#function, "Cannot find next screen")
                return
            }
            
            // MARK: Change the root view controller to tab bar controller in next screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let problemTabBarController = storyboard.instantiateViewController(identifier: "problemTabBarController")

            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(viewController: problemTabBarController)
            
            self.navigationController?.pushViewController(nextScreen, animated: true)
        }
        txtUsername.text = ""
        txtPassword.text = ""
        lblError.text = ""
    }

    
    // MARK: Function to login
    @IBAction func loginPressed(_ sender: Any) {
        
        guard let usernameInput = txtUsername.text, let passwordInput = txtPassword.text else{
            return
        }
        
        // MARK: Check any empty form fields
        if usernameInput.isEmpty || passwordInput.isEmpty{
            print(#function, "You must enter all form fields")
            lblError.text = "You must enter all form fields"
            return
        }
        
        db.collection("users").getDocuments{
            (queryResults, error) in
            if let error = error {
                print(#function, "Unable to fetch data from Firestore, \(error)")
                return
            }
            
            // MARK: use ForEach Loop to check whether the user enter correct credentials
            for doc in queryResults!.documents{
                do{
                    let userFromFirestore = try doc.data(as: User.self)
                    if usernameInput == userFromFirestore.username{
                        if passwordInput == userFromFirestore.password{
                            guard let nextScreen = self.storyboard?.instantiateViewController(withIdentifier: "problemList") as? ProblemListVC else{
                                print(#function, "Cannot find next screen")
                                return
                            }
                            if self.switchRememberMe.isOn{
                                self.defaults.set(true, forKey: "REMEMBER_ME")
                            }
                            self.defaults.set(usernameInput, forKey: "USERNAME_KEY")
                            
                            // MARK: Change the root view controller to tab bar controller in next screen
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let problemTabBarController = storyboard.instantiateViewController(identifier: "problemTabBarController")

                            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(viewController: problemTabBarController)
                            
                         
                            self.navigationController?.pushViewController(nextScreen, animated: true)
                            self.lblError.text = ""
                            self.txtUsername.text = ""
                            self.txtPassword.text = ""
                            return
                        }
                    }
                    print(#function, "Invalid username or password")
                    self.lblError.text = "Invalid username or password"
                    self.txtUsername.text = ""
                    self.txtPassword.text = ""
                    
                }catch let error{
                    print(#function, "Error fetching user, \(error)")
                }
            }
        }
    }
    
    // MARK: Go to Sign Up Screen
    @IBAction func signUpPressed(_ sender: Any) {
        guard let nextScreen = self.storyboard?.instantiateViewController(withIdentifier: "signUp") as? SignUpVC else{
            print(#function, "Cannot find next screen")
            return
        }
        self.navigationController?.pushViewController(nextScreen, animated: true)
    }
}
