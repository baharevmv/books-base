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
    // Текст для поиска
    @State private var searchText = ""
    
    private let minLength = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Кнопка для показа/скрытия блока добавления
                HStack {
                    Text(String(localized: "add_book_title"))
                        .font(.headline)
                        .foregroundColor(.gray)
                    
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
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Блок добавления книги
                if isAddingBook {
                    addBookForm
                }
                
                // Список книг
                bookList
            }
            .navigationTitle(String(localized: "book_list_title"))
            .toolbar {
                EditButton()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(String(localized: "error_title")),
                    message: Text(String(localized: "error_message")),
                    dismissButton: .default(Text(String(localized: "OK")))
                )
            }
            .onChange(of: books) { oldBooks, newBooks in
                forceSaveData()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
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
    
    // MARK: - Компоненты
        private var addBookForm: some View {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    TextField(String(localized: "book_title_placeholder"), text: $newBookTitle)
                        .textFieldStyle(.roundedBorder)
                    TextField(String(localized: "book_author_placeholder"), text: $newBookAuthor)
                        .textFieldStyle(.roundedBorder)
                    TextField(String(localized: "book_description_placeholder"), text: $newBookDescription)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                Button(String(localized: "add_book_button")) {
                    addBook()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .transition(.opacity.combined(with: .scale))
        }
    
    private var bookList: some View {
        List {
            ForEach(filteredBooks) { book in
                NavigationLink(destination: EditBookView(book: book)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title).font(.title3)
                        Text(book.author).font(.headline).foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .onDelete(perform: deleteBook)
            .listRowSeparator(.visible)
        }
        .listStyle(.plain)
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
    
    // MARK: - Фильтрация книг для поиска
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
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
                    TextField(String(localized: "book_title_placeholder"), text: $book.title)
                    TextField(String(localized: "book_author_placeholder"), text: $book.author)
                    TextField(String(localized: "book_description_placeholder"), text: $book.aboutDescription)
                } header: {
                    // Оборачиваем Text в замыкание
                    Text(String(localized: "edit_book_label"))
                }
            }
            .navigationTitle(String(localized: "edit_book_title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "save_button")) {
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
            .alert(String(localized: "error_title"), isPresented: $showAlert) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(String(localized: "error_message"))
            }
        }
    }
}

// MARK: - Расширение для обрезки пробелов
extension String {
    func trimmed() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
