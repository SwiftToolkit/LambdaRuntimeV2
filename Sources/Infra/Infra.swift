import CloudAWS

@main
struct Infra: AWSProject {
    func build() async throws -> Outputs {
        let backgroundExecution = AWS.Function(
            "BackgroundExecution",
            targetName: "BackgroundExecution",
            url: .enabled(),
            environment: [
                "TELEGRAM_BOT_TOKEN": "",
                "TELEGRAM_CHAT_ID": ""
            ]
        )

        let streamingResponse = AWS.Function(
            "StreamingResponse",
            targetName: "StreamingResponse",
            url: .enabled(invokeMode: .streaming),
            timeout: .seconds(15),
            environment: [
                "OPEN_AI_KEY": ""
            ]
        )

        return [
            "Background Execution": backgroundExecution.url,
            "Streaming Response": streamingResponse.url
        ]
    }
}
