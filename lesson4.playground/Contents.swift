import UIKit
import Combine
import Foundation



//Практическое задание
// 1. Написать простейший клиент, который обращается к любому открытому API, используя Combine в запросах. (Минимальное количество методов API: 2
// 2. Реализовать отладку любых двух издателей в коде.


// API взято из https://genderize.io и https://nationalize.io
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
        // Делаем Отладку
            .print("publisher", to: TimeLogger())
            .print("publisher2")
            .sink {value in
                let gender = value.0.gender == "Пол " ? "Мужской" : "Женский"
                print("Имя: \(self.name)")
                print("Пол: \(gender), вероятность: \(value.0.probability * 100) % согласно \(value.0.count) записям в базе данных")
                if let countries = value.1.country {
                    for country in countries {
                        print("\(self.countryName(from: country.countryId) ?? "Н/Д") с вероятностью \((country.probability * 100).rounded()) %.")
                    }
                }
                
            }
            .store(in: &cancellables)
    }
    
    
    // Запрос Национальности
    func fetchNationalize() -> AnyPublisher<Nationalize, Never>{
        let url = URL(string: baseUrlNationalize + name)!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map{$0.data}
            .decode(type: Nationalize.self, decoder: JSONDecoder())
            .replaceError(with: Nationalize.init(name: "", country: nil))
            .eraseToAnyPublisher()
    }
    
    // Запрос Гендера
    func fetchGender() -> AnyPublisher<Gender, Never> {
        let url = URL(string: baseUrlGenderize + name)!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map (\.data)
            .decode(type: Gender.self, decoder: JSONDecoder())
            .replaceError(with: Gender.init(name: "", gender: "", probability: 0, count: 0))
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

// _____________________________________________________________________________________________________


// MARK: Разбор методички

//1 РАЗБОР ПРИМЕРА ИЗ МЕТОДИЧКИ

//https://rickandmortyapi.com/documentation.
public struct Character: Codable {
    public var id: Int64
    public var name: String
    public var status: String
    public var species: String
    public var type: String
    public var gender: String
    public var image: String
    
public init(id: Int64, name: String, status: String, species: String, type: String, gender: String, image: String) {
self.id = id
    self.name = name
    self.status = status
    self.species = species
    self.type = type
    self.gender = gender
    self.image = image
}
    
}
public struct CharacterPage: Codable {
    public var info: PageInfo
    public var results: [Character]
public init(info: PageInfo, results: [Character]) {
    self.info = info
    self.results = results } }


public struct PageInfo: Codable {
    public var count: Int
    public var pages: Int
    public var prev: String?
    public var next: String?

    public init(count: Int, pages: Int, prev: String?, next: String?) {
        self.count = count
        self.pages = pages
        self.prev = prev
        self.next = next }
        }




struct APIClient {
    
    
    enum Method {
       static let baseUrl = URL(string: "https://rickandmortyapi.com/api/")!
        case character(Int)
        case location
        case episode
        
        var url: URL {
            switch self {
            case .character(let id):
                return Method.baseUrl.appendingPathComponent("character \(id)")
            default:
                fatalError()
            }
        }
    }
private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "APIClient", qos: .default, attributes:.concurrent )
    
    
    func character(id: Int) -> AnyPublisher<Character, Error> {
        return URLSession.shared
            .dataTaskPublisher(for: Method.character(id).url)
            .receive(on: queue)
            .map(\.data)
            .decode(type: Character.self, decoder: decoder)
            //.catch { _  in Empty<Character, Error>()}
            .mapError({ error -> Error in switch error {
            case is URLError:
            return Error.unreachableAddress(url: Method.character(id).url)
            default:
            return Error.invalidResponse }
            })
            .eraseToAnyPublisher()
        
    }
    
    enum Error: LocalizedError {
        case unreachableAddress(url: URL)
        case invalidResponse
        
        var errrorDescription: String? {
            switch self {
            case .unreachableAddress(let url): return "\(url.absoluteString) is unreachable "
            case .invalidResponse: return "invalid response"
            }
        }
    }
   
    
}




let apiClient = APIClient()
var subscriptions: Set<AnyCancellable> = []
apiClient.character(id: 5)
    .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
    .store(in: &subscriptions)



//практическое задание (Тренировка)
 struct User: Codable {
     let id: Int
     let name: String
     let username: String
     let email: String
     let address: Adress?
     let phone: String
     let website: String
     let company: Company?
}

public struct Adress: Codable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: Geo?
}
 struct Geo: Codable {
     let lat: String
     let lng: String
}

 struct Company: Codable {
     let name: String
     let catchPhrase: String
     let bs: String
}


var cancelables: Set<AnyCancellable> = []
let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
class API1 {
    
        let subscription = URLSession.shared
    
        .dataTaskPublisher(for: url)
        .map(\.data)
        .decode(type: User.self, decoder: JSONDecoder())
        /*.tryMap { data, _ in
            try JSONDecoder().decode(User.self, from: data)
        }*/
    
        .sink(receiveCompletion: { completion in if case .failure(let err) = completion {
        print("Sink1 Retrieving data failed with error \(err)") }
        }, receiveValue: { object in
            print("Sink1 Retrieved object \(object.website.utf8CString)")
        })
    
    
       .store(in: &cancelables)
}





//https://jsonplaceholder.typicode.com/users
//[
 //  {
 //    "id": 1,
 //    "name": "Leanne Graham",
 //    "username": "Bret",
 //    "email": "Sincere@april.biz",
 //    "address": {
 //      "street": "Kulas Light",
 //      "suite": "Apt. 556",
 //      "city": "Gwenborough",
 //      "zipcode": "92998-3874",
 //      "geo": {
 //        "lat": "-37.3159",
 //        "lng": "81.1496"
 //      }
 //    },
 //    "phone": "1-770-736-8031 x56442",
 //    "website": "hildegard.org",
 //    "company": {
 //      "name": "Romaguera-Crona",
 //      "catchPhrase": "Multi-layered client-server neural-net",
 //      "bs": "harness real-time e-markets"
 //    }
 //  },





