PROMIS
======

SMART Markers uses the FHIR endpoints of Assessment Center (PROMIS Instruments and CAT service providers). 

Please visit http://assessmentcenter.net to get access credentials for API use.


There are convinience classes to initialize, fetch and administer PROMIS CAT surveys. 



```swift
// First initialize client:
let promisClient = PROMISClient(baseURL: URL(string: baseURI)!,
                            client_id: "<# client id #>",
                            client_secret: "<# client secret #>") 


// initialize the FHIRManager
// usually done in the AppDelegate
let fhir = FHIRManager(main: client, promis: promisClient) 

```

PROMIS serveys are computer adaptive, which means, they require an API exchange between every question item presented. 

