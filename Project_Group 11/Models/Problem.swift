//
//  Problem.swift
//  Project_Group 11
//
//  Created by Yuk Fai Hsu on 2022-05-21.
//

import Foundation
import FirebaseFirestoreSwift

struct Problem:Codable{
    @DocumentID var id:String?
    let username:String
    var userMobile:String
    var title:String
    var details:String
    var remuneration:Double
    var date:String
    var address:String
    var coordinate:[String:Double]?
    var solverName:String?
    var reviewFromCustomer: String?

}

