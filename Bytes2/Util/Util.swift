//
//  User.swift
//  Bytes2
//

import UIKit

struct User: Codable {
    var userID: String
    var username: String
    var userPic: String
    var friends: [String]
    var requestsReceived: [String]
    var requestsSent: [String]
    var joinDate: String
    
    func dictionaryRepresentation() -> [String: Any] {
            return [
                "userID": userID,
                "username": username,
                "userPic": userPic,
                "friends": friends,
                "requestsReceived": requestsReceived,
                "requestsSent": requestsSent,
                "joinDate": joinDate
            ]
        }
}

let bytesGold = UIColor(named: "bytesGold")
let bytesBeige = UIColor(named: "bytesBeige")
let bytesPurple = UIColor(named: "bytesPurple")

let attributes: [NSAttributedString.Key: Any] = [
    .foregroundColor: bytesPurple!,
    .font: UIFont.boldSystemFont(ofSize: 14) 
]

let emailAttributedPlaceholder = NSAttributedString(string: "Email", attributes: attributes)

let passwordAttributedPlaceholder = NSAttributedString(string: "Password", attributes: attributes)

let usernameAttributedPlaceholder = NSAttributedString(string: "Username", attributes: attributes)

class RequestTableViewCell: UITableViewCell {
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    let acceptButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "checkmark.circle.fill")
        button.setImage(image, for: .normal)
        button.tintColor = bytesPurple
        return button
    }()
    
    let denyButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "xmark.circle.fill")
        button.setImage(image, for: .normal)
        button.tintColor = bytesGold
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(usernameLabel)
        contentView.addSubview(acceptButton)
        contentView.addSubview(denyButton)
        
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        denyButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            usernameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            usernameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            denyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            denyButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            acceptButton.trailingAnchor.constraint(equalTo: denyButton.leadingAnchor, constant: -8),
            acceptButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        let buttonImageSize: CGFloat = 35
        let configuration = UIImage.SymbolConfiguration(pointSize: buttonImageSize)
        let acceptButtonImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)
        acceptButton.setImage(acceptButtonImage, for: .normal)
        acceptButton.widthAnchor.constraint(equalToConstant: buttonImageSize).isActive = true
        acceptButton.heightAnchor.constraint(equalToConstant: buttonImageSize).isActive = true
        let denyButtonImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration)
        denyButton.setImage(denyButtonImage, for: .normal)
        denyButton.widthAnchor.constraint(equalToConstant: buttonImageSize).isActive = true
        denyButton.heightAnchor.constraint(equalToConstant: buttonImageSize).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}






