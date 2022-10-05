//
//  AnotherViewController.swift
//  CustomOperation
//
//  Created by Pham The Hung on 22/11/2021.
//

import Foundation
import UIKit

class AnotherViewController: UIViewController {
    private var operationQueue: CustomOperationQueue = {
        let queue = CustomOperationQueue()
        queue.name = "CustomOperationQueue"
        queue.maxConcurrentOperationCount = 3
        #if DEBUG
        let concurrentQueue = DispatchQueue(label: "concurrentQueue", attributes: .concurrent)
        queue.underlyingQueue = concurrentQueue
        #endif
        return queue
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    func heavyTaskWithAsync(completed: @escaping ((Int) -> Void)) {
        DispatchQueue.global().async {
            sleep(2)
            completed(Int.random(in: Range(0...9)))
        }
    }
    
    func heavyTaskWithSync(completed: @escaping ((Int) -> Void)) {
        sleep(2)
        completed(Int.random(in: Range(0...9)))
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        let completedOperation = BlockOperation()
        completedOperation.completionBlock = {
            print("Completed")
        }
        for i in 1...9 {
            let operation = CustomOperation { [weak self] completed in
                guard let self = self else {
                    completed()
                    return
                }
                self.heavyTaskWithAsync { result in
                    print(i, result)
                    completed()
                }
                
//                self.heavyTaskWithSync { result in
//                    print(i, result)
//                    completed()
//                }
            }
            completedOperation.addDependency(operation)
            operationQueue.addOperation(operation)
        }
        operationQueue.addOperation(completedOperation)
//        if #available(iOS 13.0, *) {
//            operationQueue.addCompletedBlock {
//                print("Completed")
//            }
//        } else {
//            // Fallback on earlier versions
//        }
    }
}
