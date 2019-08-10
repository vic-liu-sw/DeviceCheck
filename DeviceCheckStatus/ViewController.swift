//
//  ViewController.swift
//  DeviceCheckStatus
//
//  Created by vic_liu on 2019/8/6.
//  Copyright © 2019 ios-class. All rights reserved.
//

import UIKit
import Alamofire
import DeviceCheck

class ViewController: UIViewController {

    @IBOutlet var StatusLabel: UILabel!

    @IBOutlet var QueryButton: UIButton!

    @IBOutlet var UpdateButton: UIButton!

    let p8 = """
-----BEGIN PRIVATE KEY-----

-----END PRIVATE KEY-----
"""
    let keyID = "" //你的KEY ID
    let teamID = "" //你的Developer Team ID

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }

//    fileprivate func requestToken() {
//        DCDevice.current.generateToken { (data, error) in
//            guard data != nil else {
//                return
//            }
//            let deviceToken = data?.base64EncodedString()
//            let timestamp = self.currentTimeInMilliSeconds()
//            let uuid = UUID().uuidString
//            let url = "https://api.devicecheck.apple.com/v1/query_two_bits"
//
//            let params:[String : Any] = ["deviceToken": deviceToken, "transaction_id": uuid, "timestamp": timestamp ] as [String : Any]
//                        AF.request(url, method: .post, parameters: params).responseString { (request) in
//                            print("---------request = \(request.value)")
//                        }
//        }
//    }

    @IBAction func queryBtn(_ sender: Any) {
        DCDevice.current.generateToken { dataOrNil, errorOrNil in
            guard let data = dataOrNil else { return }

            let deviceToken = data.base64EncodedString()

            let jwt = JWT(keyID: self.keyID, teamID: self.teamID, issueDate: Date(), expireDuration: 60 * 60)

            do {
                let token = try jwt.sign(with: self.p8)
                print("Generated_query JWT: \(token)")
                var request = URLRequest(url: URL(string: "https://api.devicecheck.apple.com/v1/query_two_bits")!)
                request.httpMethod = "POST"
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let json:[String : Any] = ["device_token":deviceToken,"transaction_id":UUID().uuidString,"timestamp":Int(Date().timeIntervalSince1970.rounded()) * 1000]
                print("query-json = \(json)")
                request.httpBody = try? JSONSerialization.data(withJSONObject: json)

                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    guard let data = data,let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any],let stauts = json["bit0"] as? Int else {
                        return
                    }
                    print("stauts_bit0= \(json)")

                    if stauts == 1 {
                        DispatchQueue.main.async {
                            self.UpdateButton.isHidden = true
                           self.StatusLabel.text = "已領過"
                        }
                    }
                }
                task.resume()
            } catch {
                print(error)
                // Handle error
            }

        }


    }

    @IBAction func updateBtn(_ sender: Any) {
        DCDevice.current.generateToken { dataOrNil, errorOrNil in
            guard let data = dataOrNil else { return }

            let deviceToken = data.base64EncodedString()
            print("update_deviceToken = \(deviceToken)")


            let jwt = JWT(keyID: self.keyID, teamID: self.teamID, issueDate: Date(), expireDuration: 60 * 60)
            print("jwt_update = \(jwt)")

            do {
                let token = try jwt.sign(with: self.p8)
                //                    var request = URLRequest(url: URL(string: "https://api.development.devicecheck.apple.com/v1/update_two_bits")!)
                var request = URLRequest(url: URL(string: "https://api.devicecheck.apple.com/v1/update_two_bits")!)
                request.httpMethod = "POST"
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let json:[String : Any] = ["device_token":deviceToken,"transaction_id":UUID().uuidString,"timestamp":Int(Date().timeIntervalSince1970.rounded()) * 1000,"bit0":true,"bit1":false]
                print("update_json = \(json)")
                request.httpBody = try? JSONSerialization.data(withJSONObject: json)

                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    guard let data = data else {
                        return
                    }
                    print(String(data:data, encoding: String.Encoding.utf8))
                    DispatchQueue.main.async {
                        self.UpdateButton.isHidden = true
                        self.StatusLabel.isHighlighted = true
                        self.StatusLabel.text = "機會沒有了"
                    }
                }
                task.resume()
            } catch {
                print(error)
                // Handle error
            }


        }




    }

    func currentTimeInMilliSeconds()-> Int
    {
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        return Int(since1970 * 1000)
    }


}

