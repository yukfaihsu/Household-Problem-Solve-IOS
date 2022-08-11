//
//  ProblemDetailVC.swift
//  Project_Group 11
//
//  Created by KA CHUN on 2022-05-23.
//

import UIKit
import MapKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class ProblemDetailVC: UIViewController {

    let db = Firestore.firestore()
    let defaults: UserDefaults = UserDefaults.standard
    var problemToBeShown: Problem? = nil
    var comeFrom: String? = nil
    var currentUser: String = ""
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblCustomName: UILabel!
    @IBOutlet weak var lblCustomPhone: UILabel!
    @IBOutlet weak var lblRemuneration: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblReview: UILabel!
    @IBOutlet weak var lblReviewPrompt: UILabel!
    @IBOutlet weak var lblSolver: UILabel!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    @IBOutlet weak var btnComplete: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.currentUser = self.defaults.string(forKey: "USERNAME_KEY") ?? ""
        
        guard let comeFrom = comeFrom else {
            
            print("UnKnown")
            return
        }
        
        guard let problemToBeShown = problemToBeShown else {
            
            print("Cannot find problem to show")
            return
        }
        
        lblTitle.text = problemToBeShown.title
        lblDate.text = problemToBeShown.date
        lblDescription.text = problemToBeShown.details
        lblCustomName.text = problemToBeShown.username
        lblCustomPhone.text = problemToBeShown.userMobile
        lblRemuneration.text = "CAD \(problemToBeShown.remuneration)"
        lblAddress.text = problemToBeShown.address
        lblReview.text = problemToBeShown.reviewFromCustomer
        lblSolver.text = problemToBeShown.solverName ?? "Not Confirm Yet"
        
        //This switch is used to set different version of screen for different situation
        switch comeFrom {
        case "ProblemList":
            lblReviewPrompt.isHidden = true
            lblReview.isHidden = true
            btnCancel.isHidden = true
            btnComplete.isHidden = true
            btnConfirm.isHidden = problemToBeShown.username == currentUser ? true : false
            mapView.isHidden = false
        case "ToDoList":
            lblReviewPrompt.isHidden = true
            lblReview.isHidden = true
            btnCancel.isHidden = true
            btnComplete.isHidden = true
            btnConfirm.isHidden = true
            mapView.isHidden = false
        case "HistoryList":
            lblReviewPrompt.isHidden = false
            lblReview.isHidden = false
            btnCancel.isHidden = true
            btnComplete.isHidden = true
            btnConfirm.isHidden = true
            mapView.isHidden = true
        case "ProcessingList":
            lblReviewPrompt.isHidden = true
            lblReview.isHidden = true
            btnCancel.isHidden = problemToBeShown.solverName == nil ? false : true
            btnComplete.isHidden = problemToBeShown.solverName == nil ? true : false
            btnConfirm.isHidden = true
            mapView.isHidden = false
        default:
            print("Unknown")
        }
        
        guard let lat = problemToBeShown.coordinate!["latitude"], let lng = problemToBeShown.coordinate!["longitude"] else {
            
            print(#function, "The coordinates are null")
            return
        }
        
        let centerOfMapCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let zoomLevel = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let visibleRegion = MKCoordinateRegion(center: centerOfMapCoordinate, span: zoomLevel)
        self.mapView.setRegion(visibleRegion, animated: true)
        
        let mapMarker = MKPointAnnotation()
        mapMarker.coordinate = centerOfMapCoordinate
        mapMarker.title = problemToBeShown.address
        self.mapView.addAnnotation(mapMarker)
    }
    
    @IBAction func btnCancelPressed(_ sender: Any) {
        
        //check if the problem is confirmed by others or not and then proceed to cancel
        db.collection("problems").document((problemToBeShown?.id)!).getDocument { [self] (document, error) in
            if let document = document, document.exists {
                let problem = document.data()
                let solver = problem!["solverName"] ?? "N/A"
                if (solver as! String == "N/A") {
                    self.db.collection("problems").document((self.problemToBeShown?.id)!).delete()
                    self.navigationController?.popViewController(animated: true)
                } else {
                    let box = UIAlertController(title: "Could not cancel", message: "Someone has confirmed your order", preferredStyle: .actionSheet)
                    box.addAction(UIAlertAction(title: "OK", style: .destructive, handler: {
                        action in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(box, animated: true)
                }
            } else { print("Document does not exist") }
        }
    }
    
    @IBAction func btnConfirmPressed(_ sender: Any) {
        
        //check if the problem is confirmed by others or not and then proceed to confirm
        db.collection("problems").document((problemToBeShown?.id)!).getDocument { (document, error) in
            if let document = document, document.exists {
                let problem = document.data()
                let solver = problem!["solverName"] ?? "N/A"
                if (solver as! String == "N/A") {
                    self.db.collection("problems").document((self.problemToBeShown?.id)!).updateData(["solverName" : self.currentUser])
                    self.navigationController?.popViewController(animated: true)
                } else {
                    let box = UIAlertController(title: "Could not confirm", message: "This problem might be confirmed by someone", preferredStyle: .actionSheet)
                    box.addAction(UIAlertAction(title: "OK", style: .destructive, handler: {
                        action in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(box, animated: true)
                }
            } else { print("Document does not exist") }
        }
    }

    @IBAction func btnCompletePress(_ sender: Any) {
        
        //delete the problem from firestore
        db.collection("problems").document((problemToBeShown?.id)!).delete()
        
        //used to store the new document id when the problems are saved to another collection called "solvedProblems"
        var newDocID: String = ""
        
        do {
            let msg = try db.collection("solvedProblems").addDocument(from: problemToBeShown)
            newDocID = msg.documentID
        } catch { print("Unable to add document") }
        
        let box = UIAlertController(title: "Problem Solved!", message: "Would you like to write a review?", preferredStyle: .actionSheet)
        
        box.addAction(UIAlertAction(title: "Yes", style: .default, handler: {
            action in
            
            guard let nextScreen = self.storyboard?.instantiateViewController(identifier: "writeReview") as?
            ReviewWritingVC else {
                print("Cannot find next screen")
                return
            }

            nextScreen.problemIDToBeWrite = newDocID
            self.navigationController?.pushViewController(nextScreen, animated: true)
        }))
        
        box.addAction(UIAlertAction(title: "Skip", style: .cancel, handler: {
            action in
            
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(box, animated: true)
    }
}
