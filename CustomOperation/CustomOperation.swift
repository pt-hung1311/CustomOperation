//
//  CustomOperation.swift
//  CustomOperation
//
//  Created by Pham The Hung on 22/11/2021.
//

import Foundation

class CustomOperation: Operation {
    private var executeBlock: ((@escaping () -> Void) -> Void)
    private lazy var semaphore = DispatchSemaphore(value: 2)
    private let stateQueue = DispatchQueue(label: "CustomStateQueue",
                                           attributes: .concurrent)
    /// Non thread-safe state storage, use only with locks
    private var stateStore: State = .ready
    
    // Create state management
    enum State: String {
        case ready, executing, finished
        
        fileprivate var keyPath: String {
            return "is\(rawValue.capitalized)"
        }
    }

    /// Thread-safe computed state value
    var state: State {
        get {
            stateQueue.sync {
                return stateStore
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.async(flags: .barrier) { [weak self] in
                self?.stateStore = newValue
            }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    // Override properties
    override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    // Override start
    override func start() {
        if isCancelled {
            state = .finished
            return
        }
        state = .ready
        main()
    }
    
    override func cancel() {
        super.cancel()
        if isExecuting {
            semaphore.signal()
            state = .finished
        }
    }
    
    override func main() {
        autoreleasepool {
            if isCancelled {
                state = .finished
                semaphore.signal()
            } else {
                state = .executing
                semaphore.wait()
                executeBlock { [weak self] in
                    self?.state = .finished
                    self?.semaphore.signal()
                }
            }
        }
    }
    
    init(completion: @escaping (@escaping () -> Void) -> Void) {
        self.executeBlock = completion
        super.init()
    }
}

class PhotoSenderOperation: Operation {
    private var timeoutBlock: ((PhotoSenderOperation) -> Void)?
    
    private var _finished = false
    private var _executing = false
    private var timeout: Double?
    private var semaphore = DispatchSemaphore(value: 0)
    
    override var isReady: Bool {
        return !(isExecuting || isFinished || isCancelled)
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    func executing(_ executing: Bool) {
        _executing = executing
    }
    
    func finish(_ finished: Bool) {
        _finished = finished
    }
    
    init(timeout: Double? = nil) {
        self.timeout = timeout
        super.init()
    }
    
    override func main() {
        if isCancelled {
            forceCancelIfNeed()
            return
        }
        
        executing(true)
        finish(false)
        doSomeThing()
        semaphoreWait()
    }
    
    override func cancel() {
        super.cancel()
        forceCancelIfNeed()
    }
    
    deinit {
        print("PhotoSenderOperation deinit")
    }
    
    private func forceCancelIfNeed() {
        executing(false)
        finish(true)
        semaphore.signal()
        print("PhotoSenderOperation: forceCancelIfNeed")
    }
    
    private func doSomeThing() {
        // Do something
    }
}

extension PhotoSenderOperation {
    private func semaphoreWait() {
        guard let timeout = timeout else {
            semaphore.wait()
            return
        }
        
        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            forceCancelIfNeed()
            timeoutBlock?(self)
        }
    }
}
