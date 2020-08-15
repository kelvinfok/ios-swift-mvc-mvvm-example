//
//  ViewController.swift
//  mvvm-version
//
//  Created by Kelvin Fok on 2/8/20.
//  Copyright © 2020 Kelvin Fok. All rights reserved.
//

import UIKit
import Combine

class UsersViewModel {

    // Dependency Injection
    private let apiManager: APIManagerService
    private let endpoint: Endpoint
    
    var usersSubject = PassthroughSubject<[User], Error>()
    
    init(apiManager: APIManagerService, endpoint: Endpoint) {
        self.apiManager = apiManager
        self.endpoint = endpoint
    }
    
    func fetchUser() {
        let url = URL(string: endpoint.urlString)!
        apiManager.fetchItems(url: url) { [weak self] (result: Result<[User], Error>) in
            switch result {
            case .success(let users):
                self?.usersSubject.send(users)
            case .failure(let error):
                self?.usersSubject.send(completion: .failure(error))
            }
        }
    }
    
}

class UsersTableViewController: UITableViewController {
    
    var viewModel: UsersViewModel!
    
    var users: [User] = []
    
    private let apiManager = APIManager()
    private var subscriber: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        fetchUsers()
        observeViewModel()
    }
    
    private func setupViewModel() {
        viewModel = UsersViewModel(apiManager: apiManager,
                                   endpoint: .usersFetch)
    }
    
    private func fetchUsers() {
        viewModel.fetchUser()
    }
    
    private func observeViewModel() {
        subscriber = viewModel.usersSubject.sink(receiveCompletion: { (resultCompletion) in
            switch resultCompletion {
            case .failure(let error):
                print(error.localizedDescription)
            default: break
            }
        }) { (users) in
            DispatchQueue.main.async {
                self.users = users
                self.tableView.reloadData()
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

    @IBAction func reloadButtonTapped(_ sender: Any) {
        viewModel.fetchUser()
    }
    
}

protocol APIManagerService {
    func fetchItems<T: Decodable>(url: URL, completion: @escaping (Result<[T], Error>) -> Void)
}

class APIManager: APIManagerService {

    private var subscribers = Set<AnyCancellable>()
    
    func fetchItems<T: Decodable>(url: URL, completion: @escaping (Result<[T], Error>) -> Void) {
        URLSession.shared.dataTaskPublisher(for: url)
            .map{ $0.data }
            .decode(type: [T].self, decoder: JSONDecoder())
            .sink(receiveCompletion: { (resultCompletion) in
                switch resultCompletion {
                case .failure(let error):
                    completion(.failure(error))
                case .finished: break
                }
            }, receiveValue: { (resultArray) in
                completion(.success(resultArray))
            }).store(in: &subscribers)
    }
}

struct User: Decodable {
    let id: Int
    let name: String
    let email: String
}

enum Endpoint {
    case usersFetch
    case commentsFetch
    var urlString: String {
        switch self {
        case .usersFetch:
            return "https://jsonplaceholder.typicode.com/users"
        case .commentsFetch:
            return "https://jsonplaceholder.typicode.com/comments"
        }
    }
}
