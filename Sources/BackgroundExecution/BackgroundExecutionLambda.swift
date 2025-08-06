import AWSLambdaEvents
import AWSLambdaRuntime
import Foundation

@main
struct BackgroundExecutionLambda: LambdaWithBackgroundProcessingHandler {
    typealias Input = AWSLambdaEvents.FunctionURLRequest
    typealias Output = AWSLambdaEvents.FunctionURLResponse

    static func main() async throws {
        let adapter = LambdaCodableAdapter(handler: BackgroundExecutionLambda())
        let runtime = LambdaRuntime(handler: adapter)
        try await runtime.run()
    }

    func handle(
        _ event: Input,
        outputWriter: some LambdaResponseWriter<Output>,
        context: LambdaContext
    ) async throws {
        let requestPayload: Request

        do {
            requestPayload = try event.decodeBody(Request.self)
        } catch {
            try await outputWriter.write(Output(
                statusCode: .internalServerError,
                body: "Couldn't decode request body ('\(event.body ?? "No body")'): \(error)"
            ))
            return
        }

        let result = "Sending message: \"\(requestPayload.text)\""
        let response = Output.encoding(Response(result: result))
        try await outputWriter.write(response)

        context.logger.info("Response returned. Will now send external HTTP Request")

        do {
            try await sendTelegramMessage(requestPayload.text, context: context)
            context.logger.info("Telegram Message Sent")
        } catch {
            context.logger.error("Telegram request failed! \(error)")
        }
    }

    private func sendTelegramMessage(
        _ text: String,
        context: LambdaContext
    ) async throws {
        let telegramAPIKey = ProcessInfo.processInfo.environment["TELEGRAM_BOT_TOKEN"] ?? ""
        let chatId = ProcessInfo.processInfo.environment["TELEGRAM_CHAT_ID"] ?? ""
        let telegramClient = TelegramClient(apiKey: telegramAPIKey)
        try await telegramClient.sendMessage(text, chatId: chatId)
    }
}

extension BackgroundExecutionLambda {
    struct Request: Codable {
        let text: String
    }

    struct Response: Codable {
        let result: String
    }
}
