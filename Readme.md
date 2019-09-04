SMART-Markers Framework for Patient-Reported Outcomes
===================================================

This is **iOS** framework written entirely in Swift, relying on [SMART-on-FHIR][link-smart-on-fhir] to parse all avenues of a PRO construct that includes requesting, assessment, submission. 

## Modules of Interest

1. `SMARTManager`: Handles PRO Server management
2. `PROMeasure`: Protocol based PRO construct
    - `PROMeasure.InstrumentProtocol`: 🔥FHIR-Questionnaire, PROMIS
    - `PROMeasure.RequestProtocol`: FHIR-ProcedureRequest
    - `PROMeasure.ResultsProtocol`: FHIR-QuestionnaireResponse, Observation
3. `SessionController`: UI Class for managing PRO administration


## Installation in Xcode

Download this repo or add as a git submodule to your project. Make sure the submodules are pulled as well ([ResearchKit][link-researchkit], [Swift-SMART][link-swift-smart]). 

1. Drag `EASIPRO.xcodepro` to the root directory of your project in Xcode
2. Drag `ResearchKit.xcodeproj` and `SwiftSMART.xcodeproj` to the root directory of the project as well, in Xcode.
3. _Build_ submodules (ResearchKit, SwiftSMART) first and then EASIPRO
3. Select your blue project icon and select the "General" tab to find section _"Embedded Libraries"_ 
4. Add the following libraries to "Embedded Libraries" 
    - EASIPRO.framework
    - SMART.framework
    - ResearchKit.framework


## This is a work in progress, not available for public. 



#####  KNOWN ISSUES

1. Schedule, Plan -> Upcoming indicator
2. Schedule.instant.futuredate = Upcoming


[link-smart-on-fhir]: http://www.smarthealthit.org 
[link-researchkit]: http://researchkit.org
[link-swift-smart]: https://github.com/smart-on-fhir/Swift-SMART


### Workflow

###### Practitioner - Request Workflwo

1. Launches App
2. Selects Instrument from List
  - Show Instrument Metadata
    - Name, Identifier
    - Supported Device 
    - Supported Software
    - **ACTION**: Create Instrument FHIR resource that has this!
  - On Selection: App displays Metadata
3. Practitoner Dispatches Request, with schedule

###### Practitioner - Visualize Workflow

1. Practitioner: Gets list of requests made
2. App gets the responce back
3. App displays Response Completion Status
  - **ACTION**: Need to encode Result
  
###### Patient
1. Patient Receives Request
2. App: Receives Request, for each request
  - Resolves Instrument
  - Checks Instrument Support 
    - Questionnaire: SDC/IG
    - ValueSet(coding)
    - **ACTION** Need method `checkConformance/validateSupportFor:Instrument:`
        - `SUPPORTED`: Proceed
        - `NOTSUPPORTED`: On Device not supported, display instrument metadata: 
            - **ACTION**: `report` To Practitioner
        

## Todo

1. PGRClient: initWithServer: (SMART.Server); writebackTo(SMART.Server) 
2. At InstrumentResolve, check if instrument
    - Is available/not-available
    - check device type necessary
3. PROMIS Stateless API Module
4. 
