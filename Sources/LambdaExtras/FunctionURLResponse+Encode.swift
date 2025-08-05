//
//  FunctionURLResponse+Encode.swift
//  LambdaV2Sample
//
//  Created by Natan Rolnik on 05/08/2025.
//

import AWSLambdaEvents
import Foundation
import HTTPTypes

public extension FunctionURLResponse {
    static func encoding<T>(
        _ encodable: T,
        status: HTTPResponse.Status = .ok,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> Self where T: Encodable {
        let encodedResponse = try encoder.encode(encodable)
        return FunctionURLResponse(
            statusCode: status,
            body: String(data: encodedResponse, encoding: .utf8)
        )
    }
}
