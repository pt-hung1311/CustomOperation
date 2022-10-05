//
//  CustomOperationQueue.swift
//  CustomOperation
//
//  Created by hung on 22/11/2021.
//

import Foundation

class CustomOperationQueue: OperationQueue {
    
    override init() {
        super.init()
    }
    
    @available(iOS 13.0, *)
    func addCompletedBlock(completion: @escaping (() -> Void)) {
        addBarrierBlock {
            completion()
        }
    }
}
