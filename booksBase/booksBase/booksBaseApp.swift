//
//  booksBaseApp.swift
//  booksBase
//
//  Created by Maksim Bakharev on 12.02.2025.
//

import SwiftUI
import SwiftData

@main
struct BookBaseApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                let context = ModelContext(sharedModelContainer)
                do {
                    try context.save()
                } catch {
                    print("Ошибка при сохранении: \(error)")
                }
            }
        }
    }
}

var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        Book.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
