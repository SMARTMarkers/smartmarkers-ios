<img src="./assets/smtextlogo.png" alt="SMART Markers">

SMART Markers is standards based software framework for creating health system integrated apps for patient generated health data that includes– patient reported outcomes (PROs), [PROMIS®][promis], smartphone based activity exercises and device sensor data.

Building upon [SMART][smart] on [FHIR][fhir], SMART Markers is fully standards compliant with FHIR version [R4][r4]. All data _in and out_ is FHIR.

#### Designed for Patient & Practitioner apps

While the framework is fully functional with open FHIR servers, it can enable user-type dependent functionality– specific to either patients or practitioners and hence, both patient facing and practitioner facing apps can be created.


#### Requirements

The framework is written entirely in _Swift_ and requires Xcode 11.0 or newer and supports iOS devices with base SDK version of 12.1 (SMART Markers framework can run on devices with iOS 12.1 or newer). Two essential submodules are required for compiling: [Swift-SMART][swift-smart]– a SMART on FHIR swift library, and [ResearchKit][rk]– for data generating user interfaces.

#### Getting Started

[Installation](INSTALLATION.md)  
[Sample: Patient Facing App][easipro-patient]  
[Sample: Practitioner Facing App][easipro-practitioner]

```swift
// Start by importing
import SMARTMarkers
```

Protocols and  Modules
----------------------

SMART Markers follows a model of _request_ & _report_. The framework's core functionality is abstracted into the following three _protocols_ and supporting controller classes

### Request Protocol

Defines a set of variables needed to parse an incoming, practitioner dispatched _request_ resource. For R4, the default support is for FHIR `ServiceRequest`, but adding more `Request` compliant resources is possible. This protocol further resolves the _Instrument_ (PROs, surveys, PROMIS, activity reports, etc..) and also the associated schedule.   
[➔ Request](./Sources/Requests/)  
[➔ Schedule](./Sources/Requests/Schedule.swift)


### Instrument Protocol

Classes conforming to `Instrument` define the metadata and methods needed for initiating an interactive user session for generating data. A variety of instruments are supported out of the box with capability to add more downstream. Curently all instruments are required to be proactive data generating sessions. For consistent UX, ResearchKit's `ORKTaskViewController` created for _all_ instruments.  
[➔ Instrument](./Sources/Instruments/)  
[➔ Instrument List](./Sources/Instruments/README.md)  

### Report Protocol

FHIR `Resources` generated as results for a given instrument conform to `Report`. Eg. `QuestionnaireResponse`, `Observation`, `Media`etc. A report collector class `Reports` builds historical FHIR resources from a FHIR Server for a given `Instrument` or a `Request` or both. Also manages _reporting_ of newly created FHIR Bundles to the server after tagging with Patient and, if available, Practitioner.  
[➔ Report](./Sources/Reports/)  
[➔ Reports](./Sources/Reports/Reports.swift) 


### TaskController

Controller to manage all aspects of `Request`, `Instrument` and `Report` based classes and makes it easier to fetch PGHD requests, administer instrument session and report back to the FHIR server.   
[➔ TaskController](./Sources/TaskController/)

### Multiple Sessions & Submission to FHIR Server

For multiple, back to back interactive sessions, a set of `TaskControllers` can be passed onto a `SessionController` to create a single presentable `UIViewController`. The output from these sessions are collected by `SubmissionTask`– a `ORKTaskViewController` based UI layer to facilitate writing the resources to the `FHIR Server`  
[➔ SessionController](./Sources/Session/)




License
-------
This work is [Apache 2](LICENSE.txt) licensed. Also take look at [NOTICE.txt](NOTICE.txt). Please include licensing information of the submodulessomewhere in your product. 

- [ResearchKit][rk]


[easipro-patient]: https://github.com/easipro/easipro-smart
[easipro-practitioner]: https://github.com/easipro/easipro-smart-practitioner
[promis]: http://www.healthmeasures.net/index.php?option=com_content&view=category&layout=blog&id=147&Itemid=806
[swift-smart]: https://github.com/smart-on-fhir/swift-smart
[rk]: https://researchkit.org
[r4]: http://hl7.org/fhir/R4/
[smart]: https://smarthealthit.org
[fhir]: https://hl7.org/fhir


