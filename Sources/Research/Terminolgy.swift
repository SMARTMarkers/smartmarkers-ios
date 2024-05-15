//
//  Terminolgy.swift
//  SMARTMarkers
//
//  Created by raheel on 3/30/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//
import SMART
import Foundation


// 
extension Coding {
    
    public class func sm_ResearchSubjectStatus(code: ResearchSubjectStatus) -> Coding {
        return code.sm_asCoding
    }
    class var sm_ResearchStudyConsent: Coding {
        Coding.sm_LOINC("77602-1", "Research study consent")
    }
    
    class var sm_HL7ActCode_Research: Coding {
        Coding.sm_Coding("research", "http://terminology.hl7.org/CodeSystem/consentcategorycodes", "Research Information Access")
    }
}

extension ResearchSubjectStatus {
    // Removing http://hl7.org/fhir/ValueSet/research-subject-status
    // changed to: http://hl7.org/fhir/research-subject-status
    
    public var sm_asCoding: Coding {
        let uri = "http://hl7.org/fhir/research-subject-status"
        let code = self.rawValue
        return Coding.sm_Coding(code, uri, code)
    }
    
    public var sm_asExtension: SMART.Extension {
        let uri = "http://hl7.org/fhir/research-subject-status"
        let ext = SMART.Extension(url: uri.fhir_string)
        ext.valueCode = self.rawValue.fhir_string
        return ext
    }
    
    public var sm_Humanized: String {
        switch self {
        case .onStudy:
            return "On Study"
        case .followUp:
            return "Follow Up"
        case .offStudy:
            return "Completed"
        case .withdrawn:
            return "Withdrawn"
        default:
            return rawValue
        }
    }
}

/*
Wishes] Comment: Opt-in Consent Directive with restrictions.
research    http://terminology.hl7.org/CodeSystem/consentcategorycodes    Research Information Access    Consent to have healthcare information in an electronic health record accessed for research purposes. [VALUE SET: ActConsentType (2.16.840.1.113883.1.11.19897)]
rsdid    http://terminology.hl7.org/CodeSystem/consentcategorycodes    De-identified Information Access    Consent to have de-identified healthcare information in an electronic health record that is accessed for research purposes, but without consent to re-identify the information under any circumstance. [VALUE SET: ActConsentType (2.16.840.1.113883.1.11.19897)
rsreid    http://terminology.hl7.org/CodeSystem/consentcategorycodes    Re-identifiable Information Access    Consent to have de-identified healthcare information in an electronic health record that is accessed for research purposes re-identified under specific circumstances outlined in the consent. [VALUE SET: ActConsentType (2.16.840.1.113883.1.11.19897)]
ICOL    http://terminology.hl7.org/CodeSystem/v3-ActCode    information collection    Definition: Consent to have healthcare information collected in an electronic health record. This entails that the information may be used in analysis, modified, updated.
IDSCL    http://terminology.hl7.org/CodeSystem/v3-ActCode    information disclosure    Definition: Consent to have collected healthcare information disclosed.
INFA    http://terminology.hl7.org/CodeSystem/v3-ActCode    information access    Definition: Consent to access healthcare information.
INFAO    http://terminology.hl7.org/CodeSystem/v3-ActCode    access only    Definition: Consent to access or "read" only, which entails that the information is not to be copied, screen printed, saved, emailed, stored, re-disclosed or altered in any way. This level ensures that data which is masked or to which access is restricted will not be. Example: Opened and then emailed or screen printed for use outside of the consent directive purpose.
INFASO    http://terminology.hl7.org/CodeSystem/v3-ActCode    access and save only    Definition: Consent to access and save only, which entails that access to the saved copy will remain locked.
IRDSCL    http://terminology.hl7.org/CodeSystem/v3-ActCode    information redisclosure    Definition: Information re-disclosed without the patient's consent.
RESEARCH    http://terminology.hl7.org/CodeSystem/v3-ActCode    research information access    Definition: Consent to have healthcare information in an electronic health record accessed for research purposes.
RSDID    http://terminology.hl7.org/CodeSystem/v3-ActCode    de-identified information access    Definition: Consent to have de-identified healthcare information in an electronic health record that is accessed for research purposes, but without consent to re-identify the information under any circumstance.
RSREID    http://terminology.hl7.org/CodeSystem/v3-ActCode    re-identifiable information access    Definition: Consent to have de-identified healthcare information in an electronic health record that is accessed for research purposes re-identified under specific circumstances outlined in the consent. Example:: Where there is a need to inform the subject of potential health issues.
*/
