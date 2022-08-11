//
//  ProblemPostingVC.swift
//  Project_Group 11
//
//  Created by Yuk Fai Hsu on 2022-05-21.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseFirestoreSwift

class ProblemPostingVC: UIViewController {
    
    
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtDetails: UITextField!
    @IBOutlet weak var txtRemuneration: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblMapError: UILabel!
    @IBOutlet weak var lblError: UILabel!
    
    
    let geocoder = CLGeocoder()
    let db = Firestore.firestore()
    let defaults:UserDefaults = UserDefaults.standard
    var coordinates:[String:Double] = [:]
    var currentUSer:String = ""
    var mobile:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: Set the minimum date of the datePicker to current date
        datePicker.minimumDate = Date()
        
        // MARK: Get the current user from User Defaults
        self.currentUSer = self.defaults.string(forKey: "USERNAME_KEY") ?? ""
        
        // MARK: Get the phone number of current user from Firestore
        self.db.collection("users").getDocuments{
            (queryResults, error) in
            if let error = error{
                print(#function, "Error fetching data from Firestore, \(error)")
                return
            }
            for doc in queryResults!.documents{
                do{
                    let userFromFirestore = try doc.data(as: User.self)
                    if userFromFirestore != nil{
                        if userFromFirestore.username == self.currentUSer{
                            self.mobile = userFromFirestore.mobile
                            print(#function, "Mobile Of User: \(self.mobile)")
                        }
                    }
                    else{
                        print(#function, "Problem from Firestore was null")
                    }
                }catch{
                    print(#function, "Error converting to a Problem object")
                }
            }
        }
    }
    
    // MARK: A button to show the address entered by the user in a mapView
    @IBAction func showMapPressed(_ sender: Any) {
        
        // MARK: Check whether the address field is empty or not
        guard let address = txtAddress.text, address.isEmpty == false else{
            print(#function, "Address must be entered beofre generating the map")
            lblMapError.text = "Address must be entered before generating the map"
            return
        }
        print(#function, "Attempting to find coordinates for \(address)")
        
        // MARK: Forward geocoding to get the coordinates of the address
        self.geocoder.geocodeAddressString(address){
            (resultsList, error) in
            if let error = error{
                print(#function, "Error getting coordinates \(error)")
                self.lblMapError.text = "Cannot generate the map, but you need to keep the Address Field filled in"
                return
            }
            let addressResult:CLPlacemark = resultsList!.first!
            let latFromResult = addressResult.location?.coordinate.latitude
            let lngFromResult = addressResult.location?.coordinate.longitude
            
            guard let lat = latFromResult, let lng = lngFromResult else{
                print(#function, "The coordinates are null")
                self.lblMapError.text = "Cannot generate the map, but you can keep the Address Field for solver to find you"
                return
            }
            
            // MARK: Show the location in a mapView
            let centerOfMapCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let zoomLevel = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let visibleRegion = MKCoordinateRegion(center: centerOfMapCoordinate, span: zoomLevel)
            self.mapView.setRegion(visibleRegion, animated: true)
            
            let mapMarker = MKPointAnnotation()
            mapMarker.coordinate = centerOfMapCoordinate
            mapMarker.title = address
            self.mapView.addAnnotation(mapMarker)
            
            self.lblMapError.text = ""
            self.coordinates["latitude"] = lat
            self.coordinates["longitude"] = lng
        }
        
    }
    
    // MARK: A button to save the Problem object into the Firestore
    @IBAction func postProblemPressed(_ sender: Any) {
        guard let title = txtTitle.text, let details = txtDetails.text, let remuneration = txtRemuneration.text, let address = txtAddress.text else{
            return
        }
        
        // MARK: Check any empty form fields and validity of the infomation
        if title.isEmpty || details.isEmpty || remuneration.isEmpty || address.isEmpty{
            print(#function, "You must fill in all form fields")
            lblError.text = "You must fill in all form fields"
            return
        }
        guard let remuneration = Double(remuneration), remuneration > 0 else{
            print(#function, "Remuneration must be a postive number")
            lblError.text = "Remuneration must be a postive number"
            return
        }
        
        // MARK: Obtain the date from  the datePicker
        let dateToFinish = self.datePicker.date.formatted(date: .abbreviated, time: .omitted)
        print(dateToFinish)
        
        // MARK: Create an instance of Problem struct
        let newProblem = Problem(username: self.currentUSer, userMobile: self.mobile, title: title, details: details, remuneration: remuneration, date: "\(dateToFinish)", address: address, coordinate: self.coordinates)
        
        // MARK: Save the instance into the Firestore
        do{
            try db.collection("problems").addDocument(from: newProblem)
            print(#function, "Document saved")
            txtTitle.text = ""
            txtDetails.text = ""
            txtRemuneration.text = ""
            txtAddress.text = ""
            lblError.text = ""
            lblMapError.text = ""
            self.datePicker.date = Date()
            let mapMarkers = self.mapView.annotations
            self.mapView.removeAnnotations(mapMarkers)
            
            // MARK: Show an alert if the problem is saved successfully
            let alert = UIAlertController(title: "Problem is posted successfully", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }catch{
            print(#function, "Error when adding document")
        }
    }
    

}

