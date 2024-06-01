import Foundation

// MARK: - Todo Struct

struct Todo: CustomStringConvertible, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    var description: String {
        return "\(title) [\(isCompleted ? "✅" : "❌")]"
    }
}

// MARK: - Caching Strategies

protocol Cache {
    func save(todos: [Todo])
    func load() -> [Todo]
}

class FileSystemCache: Cache {
    private var todos: [Todo] = []
    private let filePath: URL

    init() {
        if let currentDirectory = FileManager.default.currentDirectoryPath as NSString? {
            let fileURL = URL(fileURLWithPath: currentDirectory.appendingPathComponent("todos.json"))
            self.filePath = fileURL
        } else {
            fatalError("Unable to locate current directory.")
        }
        self.todos = load()
    }

    func save(todos: [Todo]) {
        self.todos = todos
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(todos)
            try data.write(to: filePath)
            print("📌 Todos saved to file successfully!")
        } catch {
            print("Error saving todos to file: \(error)")
        }
    }

    func load() -> [Todo] {
        do {
            let data = try Data(contentsOf: filePath)
            let decoder = JSONDecoder()
            return try decoder.decode([Todo].self, from: data)
        } catch {
            print("Error loading todos from file: \(error)")
            return []
        }
    }
}



// MARK: - TodosManager Class

class TodosManager {
    private var todos: [Todo]
    private let cache: Cache

    init(cache: Cache) {
        self.cache = cache
        self.todos = cache.load()
    }

    func addTodo(with title: String) {
        let newTodo = Todo(id: UUID(), title: title, isCompleted: false)
        todos.append(newTodo)
        cache.save(todos: todos)
        print("📌 Todo added successfully!")
    }

    func listTodos() {
        print("📝 Here are your todos:")
        for (index, todo) in todos.enumerated() {
            print("\(index + 1). \(todo)")
        }
    }

    func toggleCompletion(forTodoAtIndex index: Int) {
        guard index >= 0, index < todos.count else { return }
        todos[index].isCompleted.toggle()
        cache.save(todos: todos)
        print("✅ Todo marked as completed!")
    }

    func deleteTodo(atIndex index: Int) {
        guard index >= 0, index < todos.count else { return }
        todos.remove(at: index)
        cache.save(todos: todos)
        print("🗑️ Todo removed.")
    }
}


// MARK: - App Class

class App {
    enum Command: String {
        case add, list, toggle, delete, exit
    }

    private let todosManager: TodosManager

    init() {
  
        let cache = FileSystemCache()
        self.todosManager = TodosManager(cache: cache)
    }

    func run() {
        print("Welcome to the Todo CLI App!")

        while true {
            print("\nAvailable commands: add, list, toggle, delete, exit")
            guard let input = readLine()?.lowercased(), let command = Command(rawValue: input) else {
                print("Invalid command. Try again.")
                continue
            }

            switch command {
            case .add:
                print("Enter todo title:")
                if let title = readLine() {
                    todosManager.addTodo(with: title)
                }
            case .list:
                todosManager.listTodos()
            case .toggle:
                print("Enter todo index to toggle completion:")
                if let indexStr = readLine(), let index = Int(indexStr) {
                    todosManager.toggleCompletion(forTodoAtIndex: index - 1)
                }
            case .delete:
                print("Enter todo index to delete:")
                if let indexStr = readLine(), let index = Int(indexStr) {
                    todosManager.deleteTodo(atIndex: index - 1)
                }
            case .exit:
                print("Goodbye! 👋")
                return
            }
        }
    }
}

// Run the app
let app = App()
app.run()
