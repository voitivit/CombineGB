import UIKit
import Combine

public func example(of description: String, action: () -> Void) { print("\n------ Пример:", description, "------")
action()
}

var subscription: Set<AnyCancellable> = []
// Тест Filter
//1
example(of: "Filter") {
    let numbers = (1...100).publisher
    numbers
        .filter {$0 > 50 && $0 <= 70 && $0 % 2 == 0}
        .sink { value in
            print(value)
        }
        .store(in: &subscription)
}


//Второй вариант 1 задания:
example(of: "theSecondOption"){
    (1...100).publisher
        .dropFirst(50)
        .prefix(20)
        .filter{ $0 % 2 == 0 }
        .collect()
        .sink(receiveCompletion: { print($0) }, receiveValue: { print($0)})
        .store(in: &subscription)
}





//2
var strInt: Set<AnyCancellable> = []
example(of: "StrInt") {
    let stringNumbers = ["10", "10", "90", "80", "1000"].publisher
    stringNumbers
        .map{Int($0) ?? 0}.reduce(0, +)
        .sink { value in
            print("Сумма полученных чисел, равна: \(value), среднее арифмитическое равно: \(value/value.nonzeroBitCount)")
        }
        .store(in: &strInt)
}
