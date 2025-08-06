//
//  OpenAIParser.swift
//  LambdaV2Sample
//
//  Created by Natan Rolnik on 05/08/2025.
//

import Foundation

struct OpenAIParser {
    func parse(_ text: String) -> [Event] {
        var events: [Event] = []
        var currentEventType: String?
        var currentEventData: String = ""

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.starts(with: "event: ") {
                currentEventType = String(line.dropFirst("event: ".count))
            } else if line.starts(with: "data: ") {
                currentEventData = String(line.dropFirst("data: ".count))
            } else if line.isEmpty {
                // End of current event
                if let eventType = currentEventType,
                    !currentEventData.isEmpty,
                   let jsonData = currentEventData.data(using: .utf8) {
                    let event = Event(type: EventType(eventType), data: jsonData)
                    events.append(event)
                }
                currentEventType = nil
                currentEventData = ""
            }
        }

        // Handle last event if there's no trailing empty line
        if let eventType = currentEventType,
           !currentEventData.isEmpty,
           let jsonData = currentEventData.data(using: .utf8) {
            let event = Event(type: EventType(eventType), data: jsonData)
            events.append(event)
        }

        return events
    }
}

extension OpenAIParser {
    enum EventType: String, Decodable {
        case responseCreated = "response.created"
        case responseInProgress = "response.in_progress"
        case responseOutputTextDelta = "response.output_text.delta"
        case responseOutputTextDone = "response.output_text.done"
        case responseCompleted = "response.completed"
        case unknown

        init(_ rawValue: String) {
            self = .init(rawValue: rawValue) ?? .unknown
        }
    }

    struct Event {
        let type: EventType
        let data: Data
    }
}
