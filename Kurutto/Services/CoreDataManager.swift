import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Kurutto")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func saveGameSession(score: Int, level: Int, correctAnswers: Int, totalQuestions: Int, duration: TimeInterval) {
        let session = GameSession(context: context)
        session.id = UUID()
        session.date = Date()
        session.score = Int32(score)
        session.level = Int32(level)
        session.correctAnswers = Int32(correctAnswers)
        session.totalQuestions = Int32(totalQuestions)
        session.duration = duration
        
        save()
        
        updateUserStats(score: score, correctAnswers: correctAnswers, totalQuestions: totalQuestions, duration: duration)
    }
    
    private func updateUserStats(score: Int, correctAnswers: Int, totalQuestions: Int, duration: TimeInterval) {
        let currentHighScore = UserDefaults.standard.integer(forKey: "highScore")
        if score > currentHighScore {
            UserDefaults.standard.set(score, forKey: "highScore")
        }
        
        let totalPlayTime = UserDefaults.standard.integer(forKey: "totalPlayTime")
        UserDefaults.standard.set(totalPlayTime + Int(duration), forKey: "totalPlayTime")
        
        let totalQuestionsCount = UserDefaults.standard.integer(forKey: "totalQuestions")
        UserDefaults.standard.set(totalQuestionsCount + totalQuestions, forKey: "totalQuestions")
        
        let totalCorrectAnswers = UserDefaults.standard.integer(forKey: "correctAnswers")
        UserDefaults.standard.set(totalCorrectAnswers + correctAnswers, forKey: "correctAnswers")
    }
    
    func fetchRecentSessions(limit: Int = 10) -> [GameSession] {
        let request: NSFetchRequest<GameSession> = GameSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch game sessions: \(error)")
            return []
        }
    }
    
    func fetchWeeklyProgress() -> [(day: String, totalScore: Int)] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return [] }
        
        let request: NSFetchRequest<GameSession> = GameSession.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            let sessions = try context.fetch(request)
            
            var dailyScores: [String: Int] = [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E"
            dateFormatter.locale = Locale(identifier: "ja_JP")
            
            for session in sessions {
                if let date = session.date {
                    let dayString = dateFormatter.string(from: date)
                    dailyScores[dayString, default: 0] += Int(session.score)
                }
            }
            
            let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
            return weekdays.map { day in
                (day: day, totalScore: dailyScores[day] ?? 0)
            }
        } catch {
            print("Failed to fetch weekly progress: \(error)")
            return []
        }
    }
    
    func deleteAllData() {
        let entities = ["GameSession", "Achievement", "UserProgress"]
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Failed to delete \(entity): \(error)")
            }
        }
        
        save()
    }
}