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
    //let arraInt = ["1", "2", "3", "4", "5"]
    
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













/*
// Задание 2:
//var cancellables: Array<AnyCancellable> = []
example(of: "Subscription"){
    let araay = [1,2,34,5,6,7,8,9]
    let subscription: AnyCancellable =
        araay.publisher
        .map {$0 * 3}
        .sink { value in
            print("Значения изменились: \(value)")
        }
    subscription.cancel()
}
*/







/*var cancellables: Array<AnyCancellable> = []
example(of: "Subscription"){
    let arr = [1,2,3,4,5]
    let subscription: AnyCancellable =
    arr.publisher
        .map{ ($0 * 2)/2 }
        .sink { value in
            print("Передаем данные массива: \(value)")
        }
    
}*/




/* let myNotification = Notification.Name("myNotification")
 let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
 
 let center = NotificationCenter.default
 let observer = center.addObserver(forName: myNotification, object: nil, queue: nil) { _ in
     print("FirstNotification")
 }
     center.post(name: myNotification, object: nil)
     center.removeObserver(observer)
 */

