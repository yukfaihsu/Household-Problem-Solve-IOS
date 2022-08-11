//
//  SignUpVC.swift
//  Project_Group 11
//
//  Created by Yuk Fai Hsu on 2022-05-22.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class SignUpVC: UIViewController {
    
    
    @IBOutlet weak var txtNewUsername: UITextField!
    @IBOutlet weak var txtNewPassword: UITextField!
    @IBOutlet weak var txtMobileNumber: UITextField!
    @IBOutlet weak var lblError: UILabel!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        lblError.text = ""
    }
    
    @IBAction func createAccountPressed(_ sender: Any) {
        guard let newUsername = txtNewUsername.text, let newPassword = txtNewPassword.text, let mobile = txtMobileNumber.text else{
            return
        }
        
        // MARK: Check any empty form fields
        if newUsername.isEmpty || newPassword.isEmpty || mobile.isEmpty{
            print(#function, "You must enter all form fields")
            lblError.text = "You must enter all form fields"
            return
        }
        
        // MARK: Check whether the phone number is valid
        guard let mobileNumber = Int(mobile), mobile.count == 10 else{
            print(#function, "You must enter a valid phone number")
            lblError.text = "You must enter a valid phone number"
            return
        }
        
        self.db.collection("users").getDocuments{
            (queryResults, error) in
            if let error = error{
                print(#function, "Error getting data from Firestore, \(error)")
                return
            }
            var userExist = false
            for doc in queryResults!.documents{
                do{
                    let userFromFirestore = try doc.data(as: User.self)
                    if newUsername == userFromFirestore.username{
                        userExist = true
                    }
                }catch let error{
                    print(#function, "Error fetching user, \(error)")
                }
            }
            
            // MARK: Check whether the username is already existed or not
            if userExist{
                print(#function, "User already exists")
                self.lblError.text = "User already exists"
            }
            else{
                
                // MARK: Add newly created User object into the Firestore
                let newUser = User(username: newUsername, password: newPassword, mobile: mobile)
                do{
                    try self.db.collection("users").addDocument(from: newUser)
                    print(#function, "Document saved")
                    self.txtNewUsername.text = ""
                    self.txtNewPassword.text = ""
                    self.txtMobileNumber.text = ""
                    self.lblError.text = "Account creates successfully"
                }catch{
                    print("Error when adding document")
                }
            }
        }
        
    }
    
}
