SessionController
=============

Creates a single cohesive, unified user session experience for multiple `TaskController` sessions.  If initialized with `Patient` and `Server`, a  result submission module (`SubmissionTask`) is also appended to facilitate data submission to the `FHIR Server`.

```swift

// FHIR Patient resource
let patient: Patient() 

// FHIR Server Instance
let server: Server()

// TaskControllers
let tasks = [
    TaskController(instrument: Instruments.ActiveTasks.AmslerGrid.instance),
    TaskController(instrument: Instruments.HealthKit.StepCount.instance)
]

// Initialize SessionController
let sessionController = SessionController(tasks: tasks, patient: patient, server: server, verifyUser: false)

//  
sessionController?.onCompletion = { session in
print(session.identifier)
}

// Prepare controller and present
sessionController?.prepareController(callback: { (sessionView, error) in
    if let sessionView = sessionView {
        self.present(sessionView, animated: true, completion: nil)
    }
})

// presenting instance should hold on to `sessionController` reference
self.session = sessionController
```

SubmissionTask
-------------------

1. SubmissionTask is a ResearchKit based task controller that that receives generated `SubmissionBundle` from the `Report` module and writes to the `FHIR Server` using [FHIR Bundle Transactions](fhir-bundle-transactions).
2. Works in tandam with `SessionController`


#### Modules of Interest

1. PatientVerifyController
2. PasscodeLock
3. `SubmissionBundle`



