//
//  OpenAIClient.swift
//  LambdaV2Sample
//
//  Created by Natan Rolnik on 05/08/2025.
//

import AWSLambdaRuntime
import AsyncHTTPClient
import Foundation
import NIOFoundationCompat

struct OpenAIClient {
    let apiKey: String

    func prompt(
        _ prompt: String,
        model: String = "gpt-4o-mini",
        context: LambdaContext
    ) async throws -> AsyncThrowingStream<String, Swift.Error> {
        let url = "https://api.openai.com/v1/responses"
        var request = HTTPClientRequest(url: url)
        request.method = .POST
        request.headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        request.body = try .json(
            PromptRequest(
                model: model,
                input: prompt,
                stream: true
            )
        )

        let response = try await HTTPClient.shared.execute(request, timeout: .seconds(15))
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

        guard response.status == .ok else {
            throw Error(description: "Bad response from OpenAI: \(response.status)")
        }

        let parser = OpenAIParser()

        return AsyncThrowingStream<String, Swift.Error> { continuation in
            Task {
                do {
                    for try await byteBuffer in response.body {
                        guard let text = byteBuffer.peekString(length: byteBuffer.readableBytes) else {
                            continue
                        }

                        let events = parser.parse(text)
                        if events.isEmpty {
                            context.logger.info("Empty: \(text)")
                            continuation.yield("\n\n\(text)\n\n")
                            continue
                        }

                        for event in events {
                            switch event.type {
                            case .responseOutputTextDelta:
                                do {
                                    let delta = try jsonDecoder.decode(PromptDelta.self, from: event.data)
                                    continuation.yield(delta.delta)
                                } catch {
                                    let originalString = String(data: event.data, encoding: .utf8) ?? ""
                                    context.logger.error("\(error) \(originalString)")
                                    continuation.finish(throwing: Error(description: "Error parsing prompt delta.\n\(error)\n\(originalString)"))
                                }
                            case .responseOutputTextDone:
                                continuation.finish()
                            case .responseCompleted,
                                 .responseInProgress,
                                 .responseCreated,
                                 .unknown:
                                continue
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

extension OpenAIClient {
    struct PromptDelta: Decodable {
        let delta: String
        let sequenceNumber: Int?
    }

    struct Error: Swift.Error {
        let description: String
    }
}

private extension OpenAIClient {
    struct PromptRequest: Encodable {
        let model: String
        let input: String
        let stream: Bool?
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
