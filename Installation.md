### In AppDelegate

App should support a URL Scheme, specified in Client settings to handle authorization callback. Check <# link #> for More information.

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
print(url)
let client = SMARTManager.shared.client
if client.awaitingAuthCallback {
return client.didRedirect(to: url)
}
return false
}
```


Steps
-----

1. SMARTManager
2. SessionController 
3. PatientPicker  -> (patient)
4. MeasuresPicker -> (array)


1. Practioner logs into Tablet
---------------------------
- SMARTManager.authorize() 
- [UI]: onSuccess: Show Practitioner Details
- SMARTManager.listQuestionnaires()
- onSuccess: CacheUI


2. Practitioner Selects Patient 
------------------------------
- SMARTManager.selectPatient() ---> smart.patient!

3. Practitioner Selects Measures
--------------------------------
- SMARTManager.selectMeasures() --> smart.measures?

4. Practitioner begins Sessions
-------------------------------
- SessionController.prepareSession(patient, measures, callback: sessionViewController) {
    self?.present(sessionViewController)
 }

 
5. Patient Starts Sessions
--------------------------
- SessionController.onTaskCompletion() { smart.writeTaskResponse(ProcedureRequest, QuuestionnaireResponse, Observation
)
```swift
SessionController.onTaskCompletion() = { (acsession, task, result) in 
    smartmanager.writeObservations()
    smartmanager.writeQuestionnarieResponse()
    smartmanager.writeQuestionnarie()
    smartmanager.writeProcedureRequest()
}
```

