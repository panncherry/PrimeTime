//
//  WolframAlpha.swift
//  WolframAlpha
//
//  Created by Pann Cherry on 2/28/23.
//

import Combine
import SwiftUI
import PrimeTimeComposableArchitecture

public struct WolframAlphaResult: Decodable {
    let queryresult: QueryResult
    
    struct QueryResult: Decodable {
        let pods: [Pod]
        
        struct Pod: Decodable {
            let primary: Bool?
            let subpods: [SubPod]
            
            struct SubPod: Decodable {
                let plaintext: String
            }
        }
    }
}

/// Function that takes a query string, sends it to the Wolfram Alpha API, tries to decode the json data into our struct, and invokes a callback with the results:
/// - Parameters:
///   - query: A string value to query
///   - callback: A callback with the results
/// - Returns: WolframAlphaResult
public func wolframAlpha(query: String) -> Effect<WolframAlphaResult?> {
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: "QELT5J-YL7A7EVEPY"),
    ]
    
    return URLSession.shared
        .dataTaskPublisher(for: components.url(relativeTo: nil)!)
        .map { data, _ in data }
        .decode(type: WolframAlphaResult?.self, decoder: JSONDecoder())
        .replaceError(with: nil)
        .eraseToEffect()
}

/// Request nth prime from Wolfram Alpha
/// - Parameters:
///   - n: nth prime
///   - callback:
/// - Returns: Next nth prime number
public func nthPrime(_ n: Int) -> Effect<Int?> {
    return wolframAlpha(query: "prime \(n)").map { result in
        result
            .flatMap {
                $0.queryresult
                    .pods
                    .first(where: { $0.primary == .some(true) })?
                    .subpods
                    .first?
                    .plaintext
            }
            .flatMap(Int.init)
    }
    .eraseToEffect()
}


public func offlineNthPrime(_ n: Int) -> Effect<Int?> {
    Future { callback in
        var nthPrime = 1
        var count = 0
        
        while count <= n {
            nthPrime += 1
            
            if isPrime(nthPrime) {
                count += 1
            }
        }
        
        callback(.success(nthPrime))
    }
    .eraseToEffect()
}


/// Checks prime
/// - Parameter p: The number to be checked
/// - Returns: Boolean value
public func isPrime(_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}
