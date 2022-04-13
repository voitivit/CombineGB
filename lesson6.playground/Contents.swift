import UIKit
import Combine
import Foundation

// API взято из https://genderize.io и https://nationalize.io
// lesson6
// 1. Реализовать обработку ошибок внутри созданного на прошлом уроке API клиента.
enum MyError: Error {
    case requestError
    case codingError
}

var cancellables: Set<AnyCancellable> = []

struct Gender: Codable {
    let name: String
    let gender: String
    // Вероятность совпадения
    let probability: Double
    let count: Int
}

struct Nationalize: Codable {
    let name: String
    let country: [Country]?
    
    struct Country: Codable {
        let countryId: String
        let probability: Double
        
        enum CodingKeys: String, CodingKey {
            case countryId = "country_id"
            case probability
        }
    }
        
    }
    
// Для отладки TimeLogger
class TimeLogger: TextOutputStream {
    private var previous = Date()
    private let formatter = NumberFormatter()

    init() {
        formatter.maximumFractionDigits = 5
        formatter.minimumFractionDigits = 5
    }

    func write(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date()
        print("+\(formatter.string(for: now.timeIntervalSince(previous))!)s: \(string)")
        previous = now }
}

class API {
    var cancellables: Set<AnyCancellable> = []
    // Возвращаем гражданство и пол человеку по этой переменной
    let name: String
    
    let baseUrlNationalize = "https://api.nationalize.io/?name="
    let baseUrlGenderize = "https://api.genderize.io?name="
    
    init (_ name: String) {
        self.name = name
    }
    
    
    // Общая функция, объединяем в Publisher
    
    func fetch(){
        let publisher = Publishers.Zip(fetchGender(), fetchNationalize())
        publisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): print(error.localizedDescription)
                case .finished: break
                }
            },
                  receiveValue: { value in
         
                let gender = value.0.gender == "Пол " ? "Мужской" : "Женский"
                print("Имя: \(self.name)")
                print("Пол: \(gender), вероятность: \(value.0.probability * 100) % согласно \(value.0.count) записям в базе данных")
                if let countries = value.1.country {
                    for country in countries {
                        print("\(self.countryName(from: country.countryId) ?? "Н/Д") с вероятностью \((country.probability * 100).rounded()) %.")
                    }
                }
                
            })
         .store(in: &cancellables)
    }
     
    // Запрос Национальности
    func fetchNationalize() -> AnyPublisher<Nationalize, Error>{
       

        let url = URL(string: baseUrlNationalize + name)!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { error -> MyError in return MyError.requestError }
            .map { $0.data }
            .decode(type: Nationalize.self, decoder: JSONDecoder())
            .mapError { error -> MyError in return MyError.codingError }
            //.replaceError(with: Nationalize.init(name: "", country: nil))
            .eraseToAnyPublisher()
    }
    
    // Запрос Гендера
    func fetchGender() -> AnyPublisher<Gender, Error> {
        let url = URL(string: baseUrlGenderize + name)!
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { error -> MyError in return MyError.requestError }
            .map (\.data)
            .decode(type: Gender.self, decoder: JSONDecoder())
            .mapError { error -> MyError in return MyError.codingError }
            //.replaceError(with: Gender.init(name: "", gender: "", probability: 0, count: 0))
            .eraseToAnyPublisher()
        
    }
    // Преобразует код страны в название этой страны в текущей локации.
    private func countryName(from countryCode: String) -> String? {
        return (Locale.current as NSLocale).displayName(forKey: .countryCode, value: countryCode)
    }
}

let nameExample = ["Helga", "Vladimir", "Steve", "Ivan"].publisher
nameExample
    .sink {
        value in API(value).fetch()
    }
    .store(in: &cancellables)


// _______________________________________________________________________________________________
//3. Реализовать буферизируемый оператор sink.




protocol Pausable {
    var paused: Bool {get}
    func resume()
}



final class PausableSubscriber<Input, Failure: Error>: Subscriber, Pausable, Cancellable {
    let receiveValue: (Input) -> Bool
    let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
    private var subscription: Subscription? = nil
    var paused = false

    init(receiveValue: @escaping (Input) -> Bool,
         receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) {
    self.receiveValue = receiveValue
    self.receiveCompletion = receiveCompletion }
    
    func cancel() { subscription?.cancel()
        subscription = nil
    }
    
    
    func receive(subscription: Subscription) { self.subscription = subscription
        subscription.request(.max(1))
    }
    func receive(_ input: Input) -> Subscribers.Demand {
        paused = receiveValue(input) == false
        return paused ? .none : .max(1) }
    func receive(completion: Subscribers.Completion<Failure>) { receiveCompletion(completion)
        subscription = nil
    }
    
    func resume() {
        guard paused else { return }
        paused = false
        subscription?.request(.max(1))
    }
}
extension Publisher { func pausableSink(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
receiveValue: @escaping ((Output) -> Bool)) -> Pausable & Cancellable {
    let pausable = PausableSubscriber( receiveValue: receiveValue, receiveCompletion: receiveCompletion )
    self.subscribe(pausable)
    return pausable }
    
}


let subscription = [1, 2, 3, 4, 5, 6, 6,7,89,768,678678,6464563534,345345345,36567,64745645] .publisher
    .buffer(size: 10, prefetch: .keepFull, whenFull: .dropNewest)
    .pausableSink(receiveCompletion: { completion in
        print("Pausable subscription completed: \(completion)")
        }) { value -> Bool in print("Receive value: \(value)")
            if value  == 768 {
                print("Pausing")
                    return false }
                        return true }




// практика:
extension Publisher {
    func unwrap<T>() -> Publishers.CompactMap<Self,T> where Output == Optional<T> {
        compactMap { $0 }
    }
}

[1,nil, 2,3,4, nil].publisher
    .unwrap()
    .sink { value in
        print("Receive values \(value)")
    }
    .store(in: &cancellables)


