//
//  booksBaseTests.swift
//  booksBaseTests
//
//  Created by Maksim Bakharev on 12.02.2025.
//
import XCTest
import SwiftData
@testable import booksBase

final class BookTests: XCTestCase {
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    override func setUp() {
        super.setUp()
        // Настраиваем тестовый контейнер
        let schema = Schema([Book.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(container)
    }
    
    override func tearDown() {
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // Тест добавления книги
    func testAddBook() {
        let book = Book(title: "Test Book", author: "Test Author", aboutDescription: "Test Description")
        modelContext.insert(book)
        
        // Проверяем, что книга добавлена
        let fetchRequest = FetchDescriptor<Book>()
        let books = try! modelContext.fetch(fetchRequest)
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?.title, "Test Book")
    }
    
    // Тест удаления книги
    func testDeleteBook() {
        let book = Book(title: "Test Book", author: "Test Author", aboutDescription: "Test Description")
        modelContext.insert(book)
        
        // Удаляем книгу
        modelContext.delete(book)
        
        // Проверяем, что книга удалена
        let fetchRequest = FetchDescriptor<Book>()
        let books = try! modelContext.fetch(fetchRequest)
        XCTAssertEqual(books.count, 0)
    }
    
    // Тест поиска книги
    func testSearchBooks() {
        let book1 = Book(title: "Swift Programming", author: "Apple", aboutDescription: "Learn Swift")
        let book2 = Book(title: "Python Basics", author: "Guido", aboutDescription: "Learn Python")
        modelContext.insert(book1)
        modelContext.insert(book2)
        
        // Фильтруем книги по запросу "Swift"
        let fetchRequest = FetchDescriptor<Book>(predicate: #Predicate { $0.title.contains("Swift") })
        let books = try! modelContext.fetch(fetchRequest)
        
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?.title, "Swift Programming")
    }
}
