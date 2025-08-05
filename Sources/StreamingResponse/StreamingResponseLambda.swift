import AWSLambdaEvents
import AWSLambdaRuntime
import Foundation
import NIOCore

@main
struct StreamingResponseLambda: StreamingLambdaHandlerWithEvent {
    static func main() async throws {
        let adapter = StreamingLambdaCodableAdapter(handler: StreamingResponseLambda())
        let runtime = LambdaRuntime(handler: adapter)
        try await runtime.run()
    }

    mutating func handle(
        _ event: Request,
        responseWriter: some LambdaResponseStreamWriter,
        context: LambdaContext
    ) async throws {
        let openAIKey = ProcessInfo.processInfo.environment["OPEN_AI_KEY"] ?? ""
        let client = OpenAIClient(apiKey: openAIKey)
        let response: AsyncThrowingStream<String, any Error>

        do {
            response = try await client.prompt(event.prompt, context: context)
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
            context.logger.info("Will start streaming")
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
