//
//  CompetitionDetailViewModel.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/5/22.
//

import Foundation

public class CompetitionDetailViewModel {
    private let competitionManager: ICompetitionManager
    private let homepageSheetViewModel: HomepageSheetViewModel

    init(competitionManager: ICompetitionManager, homepageSheetViewModel: HomepageSheetViewModel) {
        self.competitionManager = competitionManager
        self.homepageSheetViewModel = homepageSheetViewModel
    }
}
