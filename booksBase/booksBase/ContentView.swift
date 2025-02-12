//
//  ContentView.swift
//  booksBase
//
//  Created by Maksim Bakharev on 12.02.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext // Доступ к контексту
    @Query private var books: [Book] // Автоматический запрос данных
    
    @State private var newBookTitle: String = ""
    @State private var newBookAuthor: String = ""
    @State private var newBookDescription: String = ""
    
    // Состояние для алерта
    @State private var showAlert = false
    // Управление видимостью блока добавления
    @State private var isAddingBook = false
    
    private let minLength = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Кнопка для показа/скрытия блока добавления
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAddingBook.toggle()
                        }
                    }) {
                        Image(systemName: isAddingBook ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(isAddingBook ? 180 : 0))
                            .padding(.trailing)
                            .padding(.bottom, 2)
                    }
                }
                .padding(.top, 8)
                
                // Блок добавления книги
                if isAddingBook {
                    VStack(spacing: 12) {
                        VStack(spacing: 8) {
                            TextField("Название*", text: $newBookTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Автор*", text: $newBookAuthor)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Описание", text: $newBookDescription)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        Button(action: addBook) {
                            Text("Добавить книгу")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .transition(.opacity.combined(with: .scale))
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                
                // Список книг
                List {
                    ForEach(books) { book in
                        NavigationLink(destination: EditBookView(book: book)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.title3)
                                Text(book.author)
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete(perform: deleteBook)
                    .listRowSeparator(.visible)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Список книг")
            .toolbar {
                EditButton()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Ошибка"),
                    message: Text("Название и автор должны содержать минимум \(minLength) символа"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: books) { oldBooks, newBooks in
                // Сохраняем данные при каждом изменении списка книг
                forceSaveData()
            }
        }
    }
    
    // Функция для добавления книги
    private func addBook() {
        let trimmedTitle = newBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = newBookAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = newBookDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Валидация полей
        guard trimmedTitle.count >= minLength, trimmedAuthor.count >= minLength else {
            showAlert = true
            return
        }
        
        let newBook = Book(
            title: trimmedTitle,
            author: trimmedAuthor,
            aboutDescription: trimmedDescription
        )
        
        modelContext.insert(newBook)
        
        newBookTitle = ""
        newBookAuthor = ""
        newBookDescription = ""
    }
    
    // Функция для удаления задачи
    private func deleteBook(at offsets: IndexSet) {
        for index in offsets {
            let book = books[index]
            modelContext.delete(book) // Удаляем книгу из базы данных
        }
    }
    
    func forceSaveData() {
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении: \(error)")
        }
    }
}

/// Экран редактирвания книги
struct EditBookView: View {
    @Bindable var book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // Для закрытия экрана
    @State private var showAlert = false
    
    private let minLength = 3

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название*", text: $book.title)
                    TextField("Автор*", text: $book.author)
                    TextField("Описание", text: $book.aboutDescription)
                } header: {
                    // Оборачиваем Text в замыкание
                    Text("Редактирование книги")
                }
            }
            .navigationTitle("Редактировать книгу")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        let trimmedTitle = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedAuthor = book.author.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Валидация данных
                        guard trimmedTitle.count >= minLength,
                              trimmedAuthor.count >= minLength else {
                            showAlert = true
                            return
                        }
                        
                        // Принудительно сохраняем изменения
                        do {
                            try modelContext.save()
                        } catch {
                            print("Ошибка при сохранении: \(error)")
                        }
                        
                        dismiss() // Закрываем экран только при успешной валидации
                    }
                }
            }
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Название и автор должны содержать минимум \(minLength) символа")
            }
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
