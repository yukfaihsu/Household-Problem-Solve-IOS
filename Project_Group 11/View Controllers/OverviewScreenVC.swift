//
//  OverViewScreen.swift
//  Project_Group 11
//
//  Created by KA CHUN on 2022-05-22.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

class OverviewScreen: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tvToDoList: UITableView!
    @IBOutlet weak var tvProcessingList: UITableView!
    
    let db = Firestore.firestore()
    let defaults: UserDefaults = UserDefaults.standard
    var currentUser: String = ""
    var toDoList: [Problem] = []
    var processingList: [Problem] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tvToDoList.delegate = self
        self.tvToDoList.dataSource = self
        self.tvProcessingList.delegate = self
        self.tvProcessingList.dataSource = self
        
        self.currentUser = self.defaults.string(forKey: "USERNAME_KEY") ?? ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        refresh()
    }
    
    @IBAction func btnRefreshPressed(_ sender: Any) {
        
        refresh()
    }
    
    //Obtain the problems document from firestore and refresh the screen
    private func refresh() {
        
        db.collection("problems").getDocuments {
            (queryResults, error) in
            
            if let error = error {
                print(#function, "Unable to fetch data from Firestore, \(error)")
                return
            }
            
            var resToDoList: [Problem] = []
            var resProcessList: [Problem] = []
            
            for doc in queryResults!.documents {
                do {
                    //filter out the problems that related to current user
                    //and then store to specific list for display
                    let problemFromFS = try doc.data(as: Problem.self)
                    if (problemFromFS.solverName ==  self.currentUser) {
                        resToDoList.append(problemFromFS)
                    }
                    if (problemFromFS.username ==  self.currentUser) {
                        resProcessList.append(problemFromFS)
                    }
                }
                catch let error {
                    print(#function, "Error fetching problems, \(error)")
                }
            }
            //update the datalist for display
            self.toDoList = resToDoList
            self.processingList = resProcessList
            self.tvProcessingList.reloadData()
            self.tvToDoList.reloadData()
        }
    }
    
    //MARK: - table views set up
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let nextScreen = storyboard?.instantiateViewController(identifier: "problemDetail") as?
        ProblemDetailVC else {
            print("Cannot find next screen")
            return
        }
        
        let dataList = (tableView == tvToDoList) ? toDoList : processingList
        let currList = (tableView == tvToDoList) ? "ToDoList" : "ProcessingList"

        nextScreen.problemToBeShown = dataList[indexPath.row]
        nextScreen.comeFrom = currList

        self.navigationController?.pushViewController(nextScreen, animated: true)
        print(currList)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableView == tvToDoList ? toDoList.count : processingList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let dataList = (tableView == tvToDoList) ? toDoList : processingList
        let cellName = (tableView == tvToDoList) ? "toDoCell" : "processingCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
        cell.textLabel?.text = dataList[indexPath.row].title
        cell.detailTextLabel?.text = dataList[indexPath.row].date
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
}
