import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var statsViewModel = StatsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(spacing: 25) {
                    overviewSection
                    progressChartSection
                    achievementsSection
                    detailStatsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
            }
        }
        .background(Color("BackgroundColor"))
        .onAppear {
            statsViewModel.loadStats()
            AudioManager.shared.playBackgroundMusic(.result)
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                appState.currentScreen = .menu
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                    Text("もどる")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundColor(Color("PrimaryColor"))
            }
            
            Spacer()
            
            Text("きろく")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryTextColor"))
            
            Spacer()
            
            Color.clear
                .frame(width: 100)
        }
        .padding(.horizontal, 20)
        .frame(height: 60)
        .frame(maxHeight: 60)
        .background(Color.white)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var overviewSection: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "ハイスコア",
                value: "\(statsViewModel.highScore)",
                icon: "crown.fill",
                color: Color("ScoreColor")
            )
            
            StatCard(
                title: "プレイじかん",
                value: statsViewModel.formattedPlayTime,
                icon: "clock.fill",
                color: Color("TimeColor")
            )
        }
    }
    
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("しゅうかんのきろく")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("PrimaryTextColor"))
            
            if !statsViewModel.weeklyProgress.isEmpty {
                SimpleBarChart(data: statsViewModel.weeklyProgress)
                    .frame(height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
            } else {
                Text("まだデータがありません")
                    .font(.system(size: 18))
                    .foregroundColor(Color("SecondaryTextColor"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("じっせき")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("PrimaryTextColor"))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(statsViewModel.achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
    }
    
    private var detailStatsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("くわしいきろく")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("PrimaryTextColor"))
            
            VStack(spacing: 10) {
                DetailStatRow(label: "そうもんだいすう", value: "\(statsViewModel.totalQuestions)")
                DetailStatRow(label: "せいかいりつ", value: "\(statsViewModel.accuracyRate)%")
                DetailStatRow(label: "れんぞくせいかい", value: "\(statsViewModel.maxStreak)")
                DetailStatRow(label: "とうたつレベル", value: "レベル \(statsViewModel.maxLevel)")
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryTextColor"))
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("SecondaryTextColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AchievementBadge: View {
    let achievement: AchievementItem
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            Text(achievement.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("PrimaryTextColor"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

struct DetailStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color("SecondaryTextColor"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("PrimaryTextColor"))
        }
        .padding(.vertical, 5)
    }
}

struct AchievementItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}

struct WeeklyProgress: Identifiable {
    let id = UUID()
    let day: String
    let score: Int
}

class StatsViewModel: ObservableObject {
    @Published var highScore: Int = 0
    @Published var totalPlayTime: Int = 0
    @Published var weeklyProgress: [WeeklyProgress] = []
    @Published var achievements: [AchievementItem] = []
    @Published var totalQuestions: Int = 0
    @Published var accuracyRate: Int = 0
    @Published var maxStreak: Int = 0
    @Published var maxLevel: Int = 1
    
    var formattedPlayTime: String {
        let hours = totalPlayTime / 3600
        let minutes = (totalPlayTime % 3600) / 60
        
        if hours > 0 {
            return "\(hours)じかん \(minutes)ふん"
        } else {
            return "\(minutes)ふん"
        }
    }
    
    func loadStats() {
        highScore = UserDefaults.standard.integer(forKey: "highScore")
        totalPlayTime = UserDefaults.standard.integer(forKey: "totalPlayTime")
        totalQuestions = UserDefaults.standard.integer(forKey: "totalQuestions")
        let correctAnswers = UserDefaults.standard.integer(forKey: "correctAnswers")
        accuracyRate = totalQuestions > 0 ? (correctAnswers * 100) / totalQuestions : 0
        maxStreak = UserDefaults.standard.integer(forKey: "maxStreak")
        maxLevel = UserDefaults.standard.integer(forKey: "maxLevel")
        
        loadWeeklyProgress()
        loadAchievements()
    }
    
    private func loadWeeklyProgress() {
        let days = ["げつ", "か", "すい", "もく", "きん", "ど", "にち"]
        weeklyProgress = days.map { day in
            WeeklyProgress(day: day, score: Int.random(in: 200...800))
        }
    }
    
    private func loadAchievements() {
        achievements = [
            AchievementItem(name: "はじめてのせいかい", icon: "star.fill", color: Color("SuccessColor"), isUnlocked: true),
            AchievementItem(name: "10もんせいかい", icon: "flame.fill", color: .orange, isUnlocked: totalQuestions >= 10),
            AchievementItem(name: "れんぞく5かい", icon: "bolt.fill", color: .yellow, isUnlocked: maxStreak >= 5),
            AchievementItem(name: "レベル3たっせい", icon: "crown.fill", color: .purple, isUnlocked: maxLevel >= 3),
            AchievementItem(name: "30ぷんプレイ", icon: "clock.fill", color: .blue, isUnlocked: totalPlayTime >= 1800),
            AchievementItem(name: "パーフェクト", icon: "checkmark.seal.fill", color: .green, isUnlocked: accuracyRate == 100)
        ]
    }
}

struct SimpleBarChart: View {
    let data: [WeeklyProgress]
    
    var maxScore: Int {
        data.map { $0.score }.max() ?? 800
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(data) { item in
                    VStack {
                        Spacer()
                        
                        Rectangle()
                            .fill(Color("ChartColor"))
                            .frame(height: CGFloat(item.score) / CGFloat(maxScore) * geometry.size.height * 0.8)
                            .cornerRadius(5)
                        
                        Text(item.day)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("SecondaryTextColor"))
                            .padding(.top, 5)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ResultsView()
        .environmentObject(AppState())
}