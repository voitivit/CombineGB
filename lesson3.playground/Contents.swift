import UIKit
import Combine


public func example(of description: String, action: () -> Void) { print("\n------ Пример:", description, "------")
action()
}



var subscription: Set<AnyCancellable> = []
//1 Создайте первый издатель, производный от Subject, который испускает строки.
//2 Используйте .collect() со стратегией .byTime для группировки данных через каждые 0.5 секунд.
//3 Преобразуйте каждое значение в Unicode.Scalar, затем в Character, а затем превратите весь массив в строку с помощью .map().
//4 Создайте второй издатель, производный от Subject, который измеряет интервалы между каждым символом. Если интервал превышает 0,9 секунды, сопоставьте это значение с эмодзи. В противном случае сопоставьте его с пустой строкой.
//5 Окончательный издатель — это слияние двух предыдущих издателей строк и эмодзи. Отфильтруйте пустые строки для лучшего отображения.
//6 Результат выведите в консоль.

example(of: "Lesson3") {
    let queue = DispatchQueue(label: "Collect")
    let subject = PassthroughSubject<String, Never>()
    let firstPublisher = subject
    firstPublisher
        .collect(.byTime(queue, .seconds(0.9)))
        .map({ strings -> String in
            var string = String()
            for str in strings {
                string += "  \(str)"
            }
            return string
        })
        .compactMap{Unicode.Scalar($0)}
        .compactMap{Character($0)}
        .map{String($0).description}
        .sink { value in
            print(value)
        }
    let nextPublisher = PassthroughSubject<String, Never>()
    nextPublisher
        .measureInterval(using: DispatchQueue.main)
        .map{$0 < 0.9 ? "🤯" : " "}
        .merge(with: firstPublisher)
        .sink{ value in print(value)}
        .store(in: &subscription)
    subject.send("Example1")
       
    
}

// ВТОРОЙ ВАРИАНТ РЕШЕНИЯ БЕЗ Unicode.Scalar
example(of: "secondOption") {
    let subject = PassthroughSubject<String, Never>()
    let firstPublisher = subject
    firstPublisher
        .map{ string in return string.map{$0}}
        .map{ String($0) }
    let nextPublisher = subject
    nextPublisher
        .measureInterval(using: DispatchQueue.main)
        .map {$0 < 0.9 ? "🤯" : " "}
        .merge(with: firstPublisher)
        .sink { value in
            print(value)
        }
        .store(in: &subscription)
    subject.send("Example2")
}

