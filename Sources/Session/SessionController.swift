//
//  SessionController.swift
//  PPMG
//
//  Created by raheel on 4/4/22.
//

import Foundation
import ResearchKit
import UIKit
import SMART

/**
 `SessionController` for Multiple Tasks
 
 SessionController is to create a single unified user session to generate data from multiple tasks. Can also submit generated FHIR Bundles to the `FHIR Server` for a given `Patient`
 */
open class SessionController {
    
    /// Session identifier; a UUID string
    public let identifier: String
    
    /// Task controllers
    public internal(set) var tasks: [TaskController]
    
    /// `Patient` for which a session is created; optional
    public internal(set) var patient: Patient?
    
    /// `FHIR Server` for submission of the results
    public internal(set) var server: Server?
    
    /// Callback to call if a task has been cancelled
    public var onCancellation: ((_ task: TaskController) -> Void)?
    
    /// Callback to call when all tasks have concluded
    public var onConclusion: ((_ sessionResult: StudyTaskResult) -> Void)?
    
    /// LearnMore steps color
    public var learnMoreStepColor: UIColor?

    /**
     Designated Initializer
     
     - parameter tasks:         Array of `TaskControllers` that need to be administered
     - parameter patient:       optional `Patient`; needed for submission to `FHIR Server`
     - parameter server:        optional `Server`; needed for submission to `FHIR Server`
    */
    public init(_ tasks: [TaskController], patient: Patient?, server: Server?) {
        identifier = UUID().uuidString
        self.tasks = tasks
        self.patient = patient
        self.server = server
    }
    
    /**
     Prepares a `SessionViewController with all child `ORKTaskViewControllers`
    */
    open func prepareController(callback: @escaping ((_ controller: SessionViewController?, _ error: Error?) -> Void)) {
        
        var taskViews = [ORKTaskViewController]()
        var errors = [Error]()
        
        let sem = DispatchSemaphore(value: 0)
        for (i, task) in self.tasks.enumerated() {
            smLog("[Session]\(i)---\(task.instrument?.sm_title ?? "")")
            task.prepareSession { (taskViewController, error) in
                smLog("[Session]------\(taskViewController?.task?.description ?? "")")
                if let tvc = taskViewController {
                    taskViews.append(tvc)
                }
                if let error = error {
                    errors.append(error)
                }
                sem.signal()
            }
            sem.wait()
        }

        if taskViews.count > 0 {

            var i = 0
            taskViews.forEach({ $0.view.tag = i; i += 1; })


            if server != nil, patient != nil {
                // TODO: Add a Submission Task
            }

            let sessionView = SessionViewController(viewControllers: taskViews, for: self)

            smLog(errors)
            callback(sessionView, errors.isEmpty ? nil : errors.first)
        }
        else {
            callback(nil, errors.first)
        }

        
    }
    
}



open class SessionViewController: UIViewController {
    
    private var pages: UIPageViewController!
    private var pageIndices: [Int]
    private var taskResults: [Int: ORKTaskResult]
    private var currentPageIndex: Int
    public internal(set) var taskViewControllers: [ORKTaskViewController]
    unowned var session: SessionController!


    init(viewControllers: [ORKTaskViewController], for session: SessionController) {
        self.taskViewControllers = viewControllers
        pageIndices = [Int]()
        currentPageIndex = NSNotFound
        taskResults = [Int: ORKTaskResult]()
        self.session = session
        super.init(nibName: nil, bundle: nil)
        taskViewControllers.forEach{ $0.delegate = self }
    }
    
    func taskDidChange() {
        if !isViewLoaded { return }
        
        currentPageIndex = NSNotFound
        
        self.goto(taskIndex: 0, animated: false)
    }
    
    func goto(taskIndex: Int, animated: Bool) {
        
        guard let taskController = taskViewController(index: taskIndex) else {
            smLog("No view Controller")
            return
        }
        
        var animated = animated
        let currentTask = currentPageIndex
        if currentTask == NSNotFound {
            animated = false
        }
        
        let direction: UIPageViewController.NavigationDirection = (!animated || taskIndex > currentTask) ? .forward : .reverse
        
        currentPageIndex = taskIndex
        
        pages.setViewControllers([taskController], direction: direction, animated: animated) {  finished in
            if finished {
                UIAccessibility.post(notification: .screenChanged, argument: nil)
            }
        }
    }
    
    func updateBackButton() {
        smLog("update back button due \(currentPageIndex)")
        let task = pages.viewControllers!.first as! ORKTaskViewController
        task.currentStepViewController?.backButtonItem = self.backButtonItem()
    }
    
    func taskViewController(index: Int) -> UIViewController? {
        if index >= taskViewControllers.count { return nil }
        
        return taskViewControllers[index]
    }
    
    func navigate(delta: Int) -> Bool {
        
        let pageCount = taskViewControllers.count
        if (currentPageIndex == 0 && delta < 0) {
            return false
        }
        else if (currentPageIndex >= (pageCount - 1) && delta > 0) {
            return false
        }
        else {
            self.goto(taskIndex: (currentPageIndex + delta), animated: true)
            return true
        }
    }
    
    @discardableResult
    func goForward() -> Bool {
        navigate(delta: 1)
    }
    
    @discardableResult
    func goBackword() -> Bool {
        navigate(delta: -1)
    }
    
    
    open override func viewDidLoad() {
        
        super.viewDidLoad()
        pages = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pages.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        pages.view.frame = self.view.bounds
        self.view.addSubview(pages.view)
        self.addChild(pages)
        pages.didMove(toParent: self)
        
        taskDidChange()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func backButtonItem() -> UIBarButtonItem {
        let img = UIImage(named: "arrowLeft")
        let back = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(backButtonTapped(_:)))
        return back
    }
    
    @objc
    func backButtonTapped(_ sender: Any?) {
        smLog("back item pressed")
        goBackword()
    }
    
    @objc
    func cancelButtonTapped(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }
    
}




extension SessionViewController: ORKTaskViewControllerDelegate {
    
    func findTask(with taskView: ORKTaskViewController) -> TaskController {
        
        let tag = taskView.view.tag
        let task = session.tasks[tag]
        return task
    }
    
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {

        let sessionId = taskViewController.taskRunUUID.uuidString
        var instrumentResults = [InstrumentResult]()
        weak var ss = session
        if reason == .discarded {
            let index = taskViewController.view.tag
            taskViewControllers[0...index].forEach { taskView in
                let report = findTask(with: taskView)
                    .generateReports(
                        from: taskView,
                        result: taskView.result,
                        didFinishWith: .discarded,
                        error: error
                    )
                instrumentResults.append(report)
            }
            dismiss(animated: true) {
                ss?.onConclusion?(StudyTaskResult(sessionId: sessionId, result: instrumentResults))
            }
        }
        else {
            if goForward() == false {
                // Session Ended with success, dismiss and grab all data
                taskViewControllers.forEach { taskView in
                    let report = findTask(with: taskView)
                        .generateReports(
                            from: taskView,
                            result: taskView.result,
                            didFinishWith: .completed,
                            error: error
                        )
                    instrumentResults.append(report)
                }
                dismiss(animated: true) {
                    ss?.onConclusion?(StudyTaskResult(sessionId: sessionId, result: instrumentResults))
                }
            }
        }
    }
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        
        let previous = taskViewController.stepViewControllerHasPreviousStep(stepViewController)
        
        if false == previous && currentPageIndex > 0 {
            stepViewController.backButtonItem = self.backButtonItem()
        }
        
        let hasNextStep = taskViewController.stepViewControllerHasNextStep(stepViewController)
        
        if true == hasNextStep || currentPageIndex < (taskViewControllers.count - 1) {
            stepViewController.continueButtonTitle = "Next"
        }
        
    }
    
  
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, learnMoreButtonPressedWith learnMoreStep: ORKLearnMoreInstructionStep, for stepViewController: ORKStepViewController) {


        let clss = learnMoreStep.instantiateStepViewController(with: ORKResult())
        let nav = UINavigationController(rootViewController: clss)
        nav.view.tintColor = session.learnMoreStepColor
        stepViewController.present(nav, animated: true, completion: nil)
    }

}

