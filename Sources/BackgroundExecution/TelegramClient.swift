//
//  TelegramClient.swift
//  LambdaV2Sample
//
//  Created by Natan Rolnik on 05/08/2025.
//

import AsyncHTTPClient
import Foundation
import NIOFoundationCompat

struct TelegramClient {
    let apiKey: String

    private let jsonEncoder: JSONEncoder = {
        var encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    func sendMessage(_ string: String, chatId: String) async throws {
        let url = "https://api.telegram.org/bot\(apiKey)/sendMessage"

        let payload = SendMessagePayload(
            chatId: chatId,
            text: string
        )
        var request = HTTPClientRequest(url: url)
        request.method = .POST
        request.headers = ["Content-Type": "application/json"]
        request.body = try .json(payload, encoder: jsonEncoder)
        let response = try await HTTPClient.shared.execute(
            request,
            timeout: .seconds(5)
        )

        guard response.status == .ok else {
            let bodyData = try await response.body.collect(upTo: 1024)
            let responseBody = String(buffer: bodyData)
            throw Error.failedResponse(
                statusCode: response.status.code,
                body: responseBody
            )
        }
    }
}

private extension TelegramClient {
    struct SendMessagePayload: Encodable {
        let chatId: String
        let text: String
    }

    enum Error: Swift.Error {
        case failedResponse(statusCode: UInt, body: String)
    }
}

private extension HTTPClientRequest.Body {
    static func json<T>(
        _ value: T,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> Self where T: Encodable {
        let data = try encoder.encode(value)
        return .bytes(.init(data: data))
    }
}
