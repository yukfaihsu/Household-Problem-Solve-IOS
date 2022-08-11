//
//  ProblemListVC.swift
//  Project_Group 11
//
//  Created by Yuk Fai Hsu on 2022-05-21.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class ProblemListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableViewProblemList: UITableView!
    
    let db = Firestore.firestore()
    let defaults:UserDefaults = UserDefaults.standard
    var currentUser:String = ""
    var problemsList:[Problem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableViewProblemList.delegate = self
        self.tableViewProblemList.dataSource = self
        
        // MARK: Get the current user from User Defaults
        self.currentUser = self.defaults.string(forKey: "USERNAME_KEY") ?? ""
    }
    
    // MARK: refresh the tableView when going to the current screen
    override func viewWillAppear(_ animated: Bool) {
        self.refreshScreen()
    }
    
    // MARK: Construct the tableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return problemsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableViewProblemList.dequeueReusableCell(withIdentifier: "ProblemListCell", for: indexPath)
        
        let currProblem = self.problemsList[indexPath.row]
        
        cell.textLabel?.text = currProblem.title
        cell.detailTextLabel?.text = "Expect to finish before \(currProblem.date)"
        
        return cell
    }
    
    // MARK: A button to refresh the tableView
    @IBAction func refreshPressed(_ sender: Any) {
        self.refreshScreen()
    }
    
    // MARK: Function to refresh the tableView
    func refreshScreen(){
        self.problemsList.removeAll()
        
        db.collection("problems").getDocuments{
            (queryResults, error) in
            if let error = error{
                print(#function, "Error fetching data from Firestore, \(error)")
                return
            }
            
            // MARK: Get the data from Firestore
            for doc in queryResults!.documents{
                do{
                    let problemFromFirestore = try doc.data(as: Problem.self)
                    if problemFromFirestore != nil{
                        
                        // MARK: If the problem is taken by a solver or is posted by the current user, it will not appear in the tableView
                        if problemFromFirestore.solverName == nil && problemFromFirestore.username != self.currentUser {
                            self.problemsList.append(problemFromFirestore)
                            print(#function, "Problem: \(problemFromFirestore.title) is added to the list")
                        }
                    }
                    else{
                        print(#function, "Problem from Firestore was null")
                    }
                }catch{
                    print(#function, "Error converting to a Problem object")
                }
            }
            print(#function, "Problem Count: \(self.problemsList.count)")
            self.tableViewProblemList.reloadData()
        }

    }
    
    // MARK: Logout and clear the functionality of "Remember Me"
    @IBAction func logoutPressed(_ sender: Any) {
        self.defaults.set(false, forKey: "REMEMBER_ME")
        guard let nextScreen = self.storyboard?.instantiateViewController(withIdentifier: "login") as? LoginVC else{
            print(#function, "Cannot find next screen")
            return
        }
        
        // MARK: Change the root view controller to navigation controller in Login screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginNavigationController = storyboard.instantiateViewController(identifier: "loginNavigationController")

        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(viewController: loginNavigationController)
        
        self.navigationController?.pushViewController(nextScreen, animated: true)
    }
    
    //MARK: Transit to ProblemDetail Screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let nextScreen = storyboard?.instantiateViewController(identifier: "problemDetail") as?
        ProblemDetailVC else {
            print("Cannot find next screen")
            return
        }

        nextScreen.problemToBeShown = problemsList[indexPath.row]
        nextScreen.comeFrom = "ProblemList"
        self.navigationController?.pushViewController(nextScreen, animated: true)

    }
    
    
    
}

