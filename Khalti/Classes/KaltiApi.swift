//
//  KaltiApi.swift
//  Alamofire
//
//  Created by Rajendra Karki on 2/19/18.
//  Copyright (c) 2018 khalti. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

enum KhaltiAPIUrl: String {
    case ebankList = "https://khalti.com/api/bank/?has_ebanking=true&page_size=200"
    case cardBankList = "https://khalti.com/api/bank/?has_cardpayment=true&page_size=200"
    case paymentInitiate = "https://khalti.com/api/payment/initiate/"
    case paymentConfirm = "https://khalti.com/api/payment/confirm/"
    case bankInitiate = "https://khalti.com/ebanking/initiate/"
}

enum ErrorMessage:String {
    case server = "Kahlti Server Error"
    case noAccess = "Access is denied"
    case badRequest = "Invalid data request"
    case tryAgain = "Something went wrong.Please try again later"
    case timeOut = "Request time out."
    case noConnection = "No internet Connection."
}

class KhaltiAPI {
    
    static let shared = KhaltiAPI()
    
    func getBankList(banking: Bool = true, onCompletion: @escaping (([List])->()), onError: @escaping ((String)->())) {
        let url = banking ? KhaltiAPIUrl.ebankList.rawValue : KhaltiAPIUrl.cardBankList.rawValue
        var headers = Alamofire.SessionManager.defaultHTTPHeaders
        headers["checkout-version"] = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        headers["checkout-source"] = "iOS"
        headers["checkout-device-model"] = UIDevice.current.model
        headers["checkout-device-id"] = UIDevice.current.identifierForVendor?.uuidString ?? ""
        headers["checkout-ios-version"] = UIDevice.current.systemVersion
        
        let request = Alamofire.request(url, method: HTTPMethod.get, parameters: nil, encoding: URLEncoding.default, headers: headers)
        
        print("Request: \(url))")
        request.responseJSON { (responseJSON) in
            print("Response: \(url)")
            print(responseJSON)
            
            switch responseJSON.result {
            case .success(let value):
                var banks: [List] = []
                
                if let dict = value as? [String:Any], let records =  dict["records"] as? [[String:Any]]  {
                    for data in records {
                        if let bank = List(json: data) {
                            banks.append(bank)
                        }
                    }
                }
                
                if banks.count == 0 {
                    onError("No banks found")
                } else {
                    onCompletion(banks)
                }
            case .failure(let error):
                onError(error.localizedDescription)
                break
            }
        }
    }
    
    
    func getPaymentInitiate(with params: Dictionary<String,Any>, onCompletion: @escaping ((Dictionary<String,Any>)->()), onError: @escaping ((String)->())) {
        let url = KhaltiAPIUrl.paymentInitiate.rawValue
        var headers = Alamofire.SessionManager.defaultHTTPHeaders
        headers["checkout-version"] = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        headers["checkout-source"] = "iOS"
        headers["checkout-device-model"] = UIDevice.current.model
        headers["checkout-device-id"] = UIDevice.current.identifierForVendor?.uuidString ?? ""
        headers["checkout-ios-version"] = UIDevice.current.systemVersion
        
        let request = Alamofire.request(url, method: HTTPMethod.post, parameters: params, encoding: JSONEncoding(options: []), headers: headers)
        
        print("Request: \(url))")
        print("Parameters: \(params)")
        request.responseJSON { (responseJSON) in
            print("Response: \(url)")
            print(responseJSON)
            
            switch responseJSON.result {
            case .success(let value):
                if let dict = value as? Dictionary<String, Any> {
                    onCompletion(dict)
                }
                break
            case .failure(let error):
                onError(error.localizedDescription)
                break
            }
        }
    }
    
    func getPaymentConfirm(with params: Dictionary<String,Any>, onCompletion: @escaping ((Dictionary<String,Any>)->()), onError: @escaping ((String)->())) {
        
        let url = KhaltiAPIUrl.paymentConfirm.rawValue
        var headers = Alamofire.SessionManager.defaultHTTPHeaders
        headers["checkout-version"] = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        headers["checkout-source"] = "iOS"
        headers["checkout-device-model"] = UIDevice.current.model
        headers["checkout-device-id"] = UIDevice.current.identifierForVendor?.uuidString ?? ""
        headers["checkout-ios-version"] = UIDevice.current.systemVersion
        
        
        let request = Alamofire.request(url, method: HTTPMethod.post, parameters: params, encoding: URLEncoding.default, headers: headers)
        
        print("Request: \(url))")
        print("Parameters: \(params)")
        request.responseJSON { (responseJSON) in
            print("Response: \(url)")
            print(responseJSON)
            
            switch responseJSON.result {
            case .success(let value):
                print(value)
                if let dict = value as? Dictionary<String, Any> {
                    onCompletion(dict)
                }
                break
            case .failure(let error):
                onError(error.localizedDescription)
                break
            }
        }
    }
    
}

