//
//  StorageKeys.swift
//  MomMate
//
//  Centralized storage key constants
//

import Foundation

enum StorageKeys {
    // Data records
    static let sleepRecords = "SleepRecords"
    static let mealRecords = "MealRecords"
    static let milestones = "Milestones"
    static let notes = "AppNotes"

    // Sync & auth
    static let cloudSyncEnabled = "cloudSyncEnabled"
    static let syncAuthorized = "sync.auth.enabled.v1"
    static let sessionStore = "auth.social_session.v1"

    // Settings
    static let fontSizeFactor = "fontSizeFactor"
    static let dailyWaterGoalML = "dailyWaterGoalML"
    static let testDataGenerated = "TestDataGenerated"

    // Food catalog
    static let foodCatalog = "foodCatalog"
    static let customFoods = "customFoods"
    static let legacySavedFoodList = "savedFoodList"
    static let legacyFoodListInitialized = "foodListInitialized"
}
