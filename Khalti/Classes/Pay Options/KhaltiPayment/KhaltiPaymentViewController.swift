//
//  KhaltiPaymentViewController.swift
//  Khalti
//
//  Created by Rajendra Karki on 2/19/18.
//  Copyright (c) 2018 khalti. All rights reserved.
//

import UIKit

class KhaltiPaymentViewController: UIViewController {
    
    // MARK: - Properties
    var config:Config?
    var delegate:KhaltiPayDelegate?
    
    fileprivate var token:String?
    fileprivate var mobile:String?

    // MARK: - Outlets
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var numberOnlyView: UIView!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var confrimCodeTextField: UITextField!
    @IBOutlet weak var fullPayView: UIView!
    @IBOutlet weak var payConfirmButton: UIButton!
    @IBOutlet weak var payInitiateButton: UIButton!
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fullPayView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard self.config != nil else {
            let alertController = UIAlertController(title: "Missing Required Data", message: "Cannot process for payment.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK" , style: .default, handler: {_ in
                self.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        guard let amount = self.config?.getAmount(), amount > 0 else {
            showError(with: "Amount not found")
            return
        }
        self.payInitiateButton.setTitle("PAY RS \(amount/100)", for: .normal)
        
        self.payInitiateButton.layer.cornerRadius = 5.0
        self.payInitiateButton.layer.masksToBounds = true
        self.payConfirmButton.layer.cornerRadius = 5.0
        self.payConfirmButton.layer.masksToBounds = false
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    @IBAction func mobileValueChanged(_ sender: UITextField) {
        if let _ = self.token , self.mobile == self.mobileTextField.text && self.mobileTextField.text != "" {
            self.numberOnlyView.isHidden = true
            self.fullPayView.isHidden = false
            self.mobileTextField.resignFirstResponder()
            self.view.layoutIfNeeded()
            return
        }
        self.fullPayView.isHidden = true
        self.numberOnlyView.isHidden = false
        self.view.layoutIfNeeded()
    }
    
    @IBAction func payInitiate(_ sender: UIButton) {
        
        let params = self.validataInitiate()
        if params.count == 0 {
            return
        }
        self.mobile = self.mobileTextField.text
        self.token = self.mobileTextField.text
        
        KhaltiAPI.shared.getPaymentInitiate(with: params, onCompletion: { (response) in
            print(response)
            if let token = response["token"] as? String {
                self.token = token
                self.numberOnlyView.isHidden = true
                self.fullPayView.isHidden = false
            } else if let message = response["mobile"] as? [String], let value = message.first {
                self.showError(with: value, dismiss: false)
            } else {
                self.showError(with: "Something went wrong.Input data invalid.", dismiss: false)
            }
        }, onError: { errorMessage in
            self.showError(with: errorMessage, dismiss: false)
        })
    }
    
    @IBAction func payNow(_ sender: UIButton) {
        let params = self.validataConfirm()
        if params.count == 0 {
            return
        }
        KhaltiAPI.shared.getPaymentConfirm(with: params, onCompletion: { (response) in
            
            if let detail = response["detail"] as? String {
                self.delegate?.onCheckOutError(action: "", message: detail)
                self.showError(with: detail, dismiss: false)
                return
            }
            self.dismiss(animated: true, completion: {
                self.delegate?.onCheckOutSuccess(data: response)
            })
        }, onError:{ errorMessage in
            self.showError(with: errorMessage, dismiss: false)
        })
    }
    
    
    // MARK: - Helper Methods
    private func validataInitiate() -> Dictionary<String,Any> {
        var params:[String:Any] = [:]
        
        guard let mobile = self.mobileTextField.text, mobile != "" else {
            showError(with: "Mobile number empty", dismiss: false)
            return [:]
        }
        
        let cellRegex = NSPredicate(format:"SELF MATCHES %@", "^([9][678][0-9]{8})$")
        if cellRegex.evaluate(with: mobile) {
            params["mobile"] = mobile
        } else {
            showError(with: "Invalid mobile Number", dismiss: false)
            return [:]
        }
        
        guard let publicKey = self.config?.getPublicKey() else {
            showError(with: "Public key missing")
            return [:]
        }
        params["public_key"] = publicKey
        
        guard let amount = self.config?.getAmount() else {
            showError(with: "Amount not found")
            return [:]
        }
        params["amount"] = amount
        
        guard let productID = self.config?.getProductId() else {
            showError(with: "Amount not found")
            return [:]
        }
        params["product_identity"] = productID
        
        guard let productName = self.config?.getProductName() else {
            showError(with: "Amount not found")
            return [:]
        }
        params["product_name"] = productName
        
        if let value = self.config?.getProductUrl() {
            params["product_url"] = value
        }
        
        if let dict = self.config?.getAdditionalData() {
            for value in dict {
                if !value.key.contains("merchant_") {
                    showError(with: "Addition data must contain keyword start with \"merchant_\" to ")
                    return [:]
                }
                params[value.key] = value.value
            }
        }
        
        return params
    }

    private func validataConfirm() -> Dictionary<String,Any> {
        var params:[String:Any] = [:]
        
        guard let pin = self.pinTextField.text, pin != "" else {
            showError(with: "Pin number empty", dismiss: false)
            return [:]
        }
        
        let pinRegex = NSPredicate(format:"SELF MATCHES %@", "^([0-9]{4})$")
        if pinRegex.evaluate(with: pin) {
            params["transaction_pin"] = pin
        } else {
            showError(with: "Invalid transaction pin", dismiss: false)
            return [:]
        }
        
        guard let code = self.confrimCodeTextField.text, code != "" else {
            showError(with: "Confrimation code text empty", dismiss: false)
            return [:]
        }
        
        let codeRegex = NSPredicate(format:"SELF MATCHES %@", "^([0-9]{6})$")
        if codeRegex.evaluate(with: code) {
            params["confirmation_code"] = code
        } else {
            showError(with: "Invalid Confirmation code", dismiss: false)
            return [:]
        }
        
        guard let publicKey = self.config?.getPublicKey() else {
            showError(with: "Public key missing")
            return [:]
        }
        params["public_key"] = publicKey
        
        guard let token = self.token else {
            showError(with: "Token is missing")
            return [:]
        }
        params["token"] = token
        
        return params
    }

    // MARK: - Alert
    private func showError(with message:String, dismiss:Bool = true) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK" , style: .default, handler: {_ in
            if dismiss {
                self.dismiss(animated: true, completion: nil)
            }
        })
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }



}
