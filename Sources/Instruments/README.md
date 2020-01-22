Instrument
---------

By itself, `Instrument` is a _swift_ protocol determining the variables and methods necessary for the framework to parse its metadata, construct and administer a task session and generate an output `FHIR Bundle`.


List of Instruments
-------------------

| Category | Name | 🔥FHIR IN | 🔥FHIR OUT |
|-----------------------|---------------------------------------------------|----------------|---------------------------------------|
| Surveys | Static questionnaires<br>surveys<br>[examples](#) | Questionnaire | QuestionnaireResponse |
|  | [PROMIS](/PROMIS) <br>(Adaptive Questionnaire FHIR API) | Coding (LOINC) | QuestionnaireResponse <br>Observation |
| ActiveTasks<br> | Range of Motion | Coding | Observation (angle) |
|  | Tapping Speed | Coding | DocumentReference |
|  | 9-Hole Peg test | Coding | Observation<br>DocumentReference |
|  | Paced Serial Addition Test | Coding | Observation<br>DocumentReference |
|  | Tower of Hanoi | Coding | Observation (Bool) |
|  | Stroop Test | Coding | Observation (Duration) |
|  | Spatial Memory Span | Coding | Observation (score) |
|  | Amsler Grid | Coding | Observation<br>Media |
| Activity<br>HealthKit | Step Count (HealthKit) | Coding (LOINC) | Observation |
| Web Repositories | OMRON Blood Pressure | Coding (LOINC) | Observation |
| FHIR Data | Apple Health App | - | DSTU2 -> R4 Mapped |



### Using Built in Instruments powered by [ResearchKit](http://researchkit.org) 

```swift
import SMARTMarkers

// intialize a built in Instrument
let amslerGrid = Instruments.ActiveTasks.AmslerGrid.instance 
```


