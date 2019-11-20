Instrument
---------

By itself, `Instrument` is a _swift_ protocol determining the variables and methods necessary for the framework to parse its metadata, construct and administer a task session and generate an output `FHIR Bundle`.

### Using FHIR Questionnaire

```swift

```

### Using Built in Instruments powered by [ResearchKit](http://researchkit.org) 

```swift
import SMARTMarkers

// intialize a built in Instrument
let amslerGrid = Instruments.ActiveTasks.AmslerGrid.instance 
```


List of Instruments
-------------------

Type            | Name          | FHIR IN           | FHIR OUT          
--------------------------------------------------------------------------
Survey          | Static surveys| Questionnaire     | QuestionnaireResponse
                | Adaptive      | Questionnaire     | QuestionnaireResponse
ActiveTasks     | AmslerGrid    | Coding            | Observation, Media
                | TappingSpeed  | Coding            | Observation, Attachment



