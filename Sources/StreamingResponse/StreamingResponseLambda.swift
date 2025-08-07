import AWSLambdaEvents
import AWSLambdaRuntime
import Foundation
import NIOCore

@main
struct StreamingResponseLambda: StreamingLambdaHandler {
    static func main() async throws {
        let runtime = LambdaRuntime(handler: StreamingResponseLambda())
        try await runtime.run()
    }

    let eventDecoder = LambdaJSONEventDecoder(JSONDecoder())

    mutating func handle(
        _ event: ByteBuffer,
        responseWriter: some LambdaResponseStreamWriter,
        context: LambdaContext
    ) async throws {
        let functionURLRequest = try eventDecoder.decode(AWSLambdaEvents.FunctionURLRequest.self, from: event)
        let request = try functionURLRequest.decodeBody(Request.self)

        let openAIKey = ProcessInfo.processInfo.environment["OPEN_AI_KEY"] ?? ""
        let client = OpenAIClient(apiKey: openAIKey)
        let response: AsyncThrowingStream<String, any Error>

        do {
            response = try await client.prompt(request.prompt, context: context)
            try await responseWriter.writeStatusAndHeaders(.init(
                statusCode: 200,
                headers: ["Content-Type": "text/plain"]
            ))
        } catch {
            try await responseWriter.writeStatusAndHeaders(.init(statusCode: 500))
            try await responseWriter.writeAndFinish(ByteBuffer(string: "Something went wrong: \(error)"))
            return
        }

        do {
            for try await delta in response {
                try await responseWriter.write(ByteBuffer(string: delta))
            }
            try await responseWriter.finish()
        } catch {
            try await responseWriter.writeAndFinish(ByteBuffer(string: "Something went wrong: \(error)"))
        }
    }
}

extension StreamingResponseLambda {
    struct Request: Decodable {
        let prompt: String
    }
}
