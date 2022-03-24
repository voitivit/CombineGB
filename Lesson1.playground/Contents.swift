import Foundation
import Combine

public func example(of description: String, action: () -> Void) { print("\n------ Пример:", description, "------")
action()
}

// Задание 1:
var intArray = [1,2,3,4,5,6]
let myNotification = Notification.Name("myNotification")
NotificationCenter.default.publisher(for: myNotification, object: nil)

let center = NotificationCenter.default

center.post(name: myNotification, object: nil)

let observer = center.addObserver(forName: myNotification, object: nil, queue: nil) { _ in
    print(intArray)
}
center.post(name: myNotification, object: nil)
center.removeObserver(observer)

//Задание 2:
// Subscription
example(of: "Subscription") {
    let arrayString = ["one", "two", "three", "four", "five"]
    let subscription: AnyCancellable =
    arrayString.publisher
        .map {$0.capitalized}
        .sink { value in
            print("Измененные значения: \(value)")
        }
    subscription.cancel()
}

// Just
example(of: "Just") {
    let array = [1,2,3,45,6]
    let just = Just(array)
    just
        .sink { value in
            print(value)
        } receiveValue: { value in
            print(value)
        }
    just.eraseToAnyPublisher()
}

// Future
var cancellables: Set<AnyCancellable> = []
let banner = """
          __,
         (           o  /) _/_
          `.  , , , ,  //  /
        (___)(_(_/_(_ //_ (__
                     /)
                    (/
        """
example(of: "Future") {
    let future = Future<String, Never> {promise in
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            promise(.success("Баннер Swift"))
        }
    }
    
    future
        .sink {_ in
            print(banner)
        } receiveValue: { value in
            print(value)
        }
        .store(in: &cancellables)
}
