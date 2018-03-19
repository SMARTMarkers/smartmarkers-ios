Rough Draft
===========




Workflow
--------

```

Step1: [EHRLOGINMODULE]  Provider Picks up the Tablet, logs in. 
Step2: [MEASURESMODULE]  
    1. Measures requests all Questionnaires approved or listed in the FHIR SERVER
    2. Provider selects list of Measures.
    3. Provider taps Start PRO-Measure --> Initiates SessionController(patient: Patient, measure: [Questionnaire]) 
        [SessionController]
            1. SessionController <--- gets all Loincs from [Questionnaire]
            2. SessionController.forEach { questionnaire, in 
                //check questionnaire.code in assessmentcenter.listOfCodes {
                        -if yes = goto AC
                        -if no  = fallback to Default
                 } 
            }

               
```
