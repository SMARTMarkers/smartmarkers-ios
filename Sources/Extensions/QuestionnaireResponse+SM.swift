//
//  QuestionnaireResponse+SM.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 18/08/21.
//  Copyright © 2021 Boston Children's Hospital. All rights reserved.
//

import SMART

public extension QuestionnaireResponse {

	func sm_allItems() -> [QuestionnaireResponseItem]? {
		let items = self.item ?? [QuestionnaireResponseItem]()
		return items + items.flatMap { $0.sm_allItemsRecursively() }
	}
}


public extension QuestionnaireResponseItem {

	func sm_allItemsRecursively() -> [QuestionnaireResponseItem] {
		let items = self.item ?? [QuestionnaireResponseItem]()
		return items + items.flatMap { $0.sm_allItemsRecursively() }
	}

}
