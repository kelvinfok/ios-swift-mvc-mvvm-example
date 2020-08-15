//
//  ViewController.swift
//  mvc-mvvm-demo-app
//
//  Created by Kelvin Fok on 2/8/20.
//  Copyright © 2020 Kelvin Fok. All rights reserved.
//

import UIKit

class UsersTableViewController: UITableViewController {
    
    var users: [User] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUsers()
    }
    
    private func fetchUsers() {
        APIManager.shared.fetchUsers { (result) in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.users = users
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let user = users[indexPath.item]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

}

class APIManager {
    
    static let shared = APIManager()
    private init() {}
    
    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        let urlString = "https://jsonplaceholder.typicode.com/users"
        let url = URL(string: urlString)!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                fatalError("Data cannot be found")
            }
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                completion(.success(users))
            } catch(let error) {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct User: Decodable {
    let id: Int
    let name: String
    let email: String
}
