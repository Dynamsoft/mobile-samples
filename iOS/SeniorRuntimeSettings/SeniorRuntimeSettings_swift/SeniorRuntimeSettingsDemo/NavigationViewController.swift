//
//  NavigationViewController.swift
//  SeniorRuntimeSettingsDemo
//
//  Created by Dynamsoft on 08/07/2020.
//  Copyright © 2020 Dynamsoft. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc func controllerWillPopHandler() {
    }
    
    
    override func popViewController(animated: Bool) -> UIViewController? {
        let vc = self.topViewController
        if(vc!.responds(to: #selector(controllerWillPopHandler))){
            vc!.perform(#selector(controllerWillPopHandler))
        }
        return super.popViewController(animated: animated)
    }

}
