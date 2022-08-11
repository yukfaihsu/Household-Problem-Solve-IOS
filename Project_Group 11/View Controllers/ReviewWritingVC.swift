//
//  ReviewWritingVC.swift
//  Project_Group 11
//
//  Created by KA CHUN on 2022-05-23.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class ReviewWritingVC: UIViewController {

    var problemIDToBeWrite: String? = nil
    let db = Firestore.firestore()

    @IBOutlet weak var txtReview: UITextView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        txtReview.text = ""
    }
    
    @IBAction func btnSubmitPressed(_ sender: Any) {

        db.collection("solvedProblems").document(problemIDToBeWrite!).updateData(["reviewFromCustomer" : txtReview.text!])
        self.navigationController?.popToRootViewController(animated: true)
    }
}
