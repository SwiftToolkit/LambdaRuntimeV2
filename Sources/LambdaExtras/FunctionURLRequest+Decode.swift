//
//  FunctionURLRequest+Decode.swift
//  LambdaV2Sample
//
//  Created by Natan Rolnik on 05/08/2025.
//

import AWSLambdaEvents
import Foundation

public extension FunctionURLRequest {
    func decodeBody<T>(
        _ type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T where T: Decodable {
        let bodyData = body?.data(using: .utf8) ?? Data()

        var requestData = bodyData

        if isBase64Encoded,
           let base64Decoded = Data(base64Encoded: requestData) {
            requestData = base64Decoded
        }

        return try decoder.decode(T.self, from: requestData)
    }
}
