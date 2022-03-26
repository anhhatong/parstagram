//
//  FeedViewController.swift
//  parstagram
//
//  Created by Maddie Tong on 3/20/22.
//

import UIKit
import Parse
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    var posts = [PFObject]()
    let commentBar = MessageInputBar() // user library input bar
    var showCommentBar = false
    var selectedPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        commentBar.inputTextView.placeholder = "Add a comment..." // customize placeholder
        commentBar.sendButton.title = "Post" // customize button text
        commentBar.delegate = self // when user fires event (pressing send), need to delegate
        
        let center = NotificationCenter.default
        // When keyboard is hidden, which is detected by UIResponder, call our own function keyboardWillBeHidden
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(noti:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillBeHidden(noti: Notification) {
        commentBar.inputTextView.text = nil // clear input bar
        showCommentBar = false
        becomeFirstResponder()
    }
    
    @IBAction func onLogout(_ sender: Any) {
        PFUser.logOut()
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        // Get the window scene before getting access to it in SceneDelegate
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else { return }
        delegate.window?.rootViewController = loginViewController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let query = PFQuery(className: "Posts")
        // convert references to actual value
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20 // the last 20 posts
        
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts = posts! // store data
                self.tableView.reloadData() // rerender table
            }
        }
    }
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showCommentBar
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // Create comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost // a foreign key to Post table
        comment["author"] = PFUser.current() // a foreign key to User table
        
        selectedPost.add(comment, forKey: "comments") // add reference to Comment table
        selectedPost.saveInBackground { (success, error) in
            if success {
                self.tableView.reloadData()
            } else {
                print("Error saving comment")
            }
        }
        
        // Hide bar
        showCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        // Empty array if there are no comments
        let comments = (post["comments"] as? [PFObject]) ?? []
        return comments.count + 2 // 1 post picture + n comments rows + 1 add comment
    }
    
    // Every post is a section with different number of rows since comments are displayed
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section] // section index, not row index
        let comments = (post["comments"] as? [PFObject]) ?? [] // get comments from post
        
        // First row must be the post, and the rest will be comments
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            cell.captionLabel.text = (post["caption"] as! String)
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            cell.photoView.af_setImage(withURL: url) // AlamoImage funtion
            
            return cell
        } else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as! CommentTableViewCell
            let comment = comments[indexPath.row - 1] // -1 because the first row is the post
            cell.commentText.text = comment["text"] as? String
            
            // because comment has user reference, we must get username by getting to the referenced username
            let user = comment["author"] as! PFUser
            cell.author.text = user.username
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        // Add comment field selected
        if (indexPath.row == comments.count + 1) {
            showCommentBar = true
            becomeFirstResponder() // canBecomeFirstResponder is called to update
            commentBar.inputTextView.becomeFirstResponder() // actually raise the keyboard
            selectedPost = post
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
