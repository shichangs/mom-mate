//
//  MealRecordManager.swift
//  MomMate
//
//  Manages meal records storage and retrieval
//

import Foundation

class MealRecordManager: ObservableObject {
    @Published var mealRecords: [MealRecord] = []
    
    private let mealRecordsKey = "MealRecords"
    
    init() {
        loadMealRecords()
    }
    
    func addMealRecord(_ record: MealRecord) {
        mealRecords.insert(record, at: 0)
        saveMealRecords()
    }
    
    func updateMealRecord(_ record: MealRecord) {
        if let index = mealRecords.firstIndex(where: { $0.id == record.id }) {
            mealRecords[index] = record
            saveMealRecords()
        }
    }
    
    func deleteMealRecord(_ record: MealRecord) {
        mealRecords.removeAll { $0.id == record.id }
        saveMealRecords()
    }
    
    var sortedMealRecords: [MealRecord] {
        mealRecords.sorted { $0.date > $1.date }
    }
    
    func mealRecordsByType(_ type: MealType) -> [MealRecord] {
        mealRecords.filter { $0.mealType == type }.sorted { $0.date > $1.date }
    }
    
    func mealRecordsForToday() -> [MealRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return mealRecords.filter { record in
            record.date >= today && record.date < tomorrow
        }.sorted { $0.date > $1.date }
    }
    
    private func saveMealRecords() {
        if let encoded = try? JSONEncoder().encode(mealRecords) {
            UserDefaults.standard.set(encoded, forKey: mealRecordsKey)
        }
    }
    
    private func loadMealRecords() {
        if let data = UserDefaults.standard.data(forKey: mealRecordsKey),
           let decoded = try? JSONDecoder().decode([MealRecord].self, from: data) {
            mealRecords = decoded
        }
    }
}

