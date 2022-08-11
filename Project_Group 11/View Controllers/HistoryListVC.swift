//
//  historyListVC.swift
//  Project_Group 11
//
//  Created by KA CHUN on 2022-05-23.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class HistoryListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tvHistoryList: UITableView!
    
    let db = Firestore.firestore()
    let defaults:UserDefaults = UserDefaults.standard
    var currentUser:String = ""
    var historyList: [Problem] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.currentUser = self.defaults.string(forKey: "USERNAME_KEY") ?? ""
        self.tvHistoryList.delegate = self
        self.tvHistoryList.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        refresh()
    }
    
    //refresh the screen based on the data from Firestore
    private func refresh() {
        
        db.collection("solvedProblems").getDocuments {
            (queryResults, error) in
            
            if let error = error {
                print(#function, "Unable to fetch data from Firestore, \(error)")
                return
            }
            
            var resHistoryList: [Problem] = []
            
            for doc in queryResults!.documents {
                do {
                    let pbFromFS = try doc.data(as: Problem.self)
                    //filter out the problems that related to current user
                    if (pbFromFS.solverName ==  self.currentUser || pbFromFS.username ==  self.currentUser) {
                        resHistoryList.append(pbFromFS)
                    }
                }
                catch let error {
                    print(#function, "Error fetching problems, \(error)")
                }
            }
            self.historyList = resHistoryList
            self.tvHistoryList.reloadData()
        }
    }
    @IBAction func btnRefreshPress(_ sender: Any) {
        
        refresh()
    }
    
    //MARK: - table view set up
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return historyList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tvHistoryList.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)

        var str = ""
        if (self.historyList[indexPath.row].solverName == self.currentUser) {
           str = " [Solver]"
        }
        cell.textLabel?.text = self.historyList[indexPath.row].title
        cell.detailTextLabel?.text = "\(self.historyList[indexPath.row].date)\(str)"
        return cell
        }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let nextScreen = storyboard?.instantiateViewController(identifier: "problemDetail") as?
        ProblemDetailVC else {
            print("Cannot find next screen")
            return
        }

        nextScreen.problemToBeShown = historyList[indexPath.row]
        nextScreen.comeFrom = "HistoryList"
        self.navigationController?.pushViewController(nextScreen, animated: true)
    }
}
