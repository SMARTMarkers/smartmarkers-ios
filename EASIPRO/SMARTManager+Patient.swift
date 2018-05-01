//
//  SMARTManager+Patient.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 01/05/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

extension SMARTManager {
	
	
	public func fetchPrescribing(callback: @escaping ([ProcedureRequest]?, Error?) -> Void) {
		
		guard let patient = patient else {
			callback(nil, nil)
			return
		}
		let searchParams = ["patient": patient.id!.string]
		search(type: ProcedureRequest.self, params: searchParams) { (requests, error) in
			if nil != error {
				callback(nil, error)
				return
			}
			
			if let requests = requests {
				
				let promeasures = requests.map({ (procedureRequest) -> PROMeasure2 in
					
					let title = procedureRequest.ep_titleCode ?? procedureRequest.ep_titleCategory ?? procedureRequest.id!.string
					let identifier = procedureRequest.id!.string
					
					let prom = PROMeasure2(title: title, identifier: identifier)
					prom.prescribingResource = procedureRequest
					return prom
				})
				
				
				
				
			}
			
		}
		
	}
	
	
}
