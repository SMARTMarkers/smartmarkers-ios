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

