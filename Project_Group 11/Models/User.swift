//
//  User.swift
//  Project_Group 11
//
//  Created by Yuk Fai Hsu on 2022-05-21.
//

import Foundation
import FirebaseFirestoreSwift

struct User:Codable{
    @DocumentID var id:String?
    var username:String
    var password:String
    var mobile:String
}
