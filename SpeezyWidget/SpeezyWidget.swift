//
//  SpeezyWidget.swift
//  SpeezyWidget
//
//  Created by Stephen Hofmeyr on 30/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    @available(iOS 14.0, *)
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}


struct SpeezyWidgetEntryView : View {
    var entry: Provider.Entry
    
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var title: some View {
        
        Text("Speezy")
            .font(widgetFamily == .systemSmall ? Font.body.bold() : Font.title3.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.1)
            .foregroundColor(.white)
    }
    
    var description: some View {
        Text("Create an audio message.")
            //.font(.subheadline)
            .font(.system(size: 12))
            .fontWeight(.medium)
            .lineLimit(2)
            .foregroundColor(.white)
            .padding(4)
    }
    
    
    //Widget Deep Link functionality
    var deeplinkURL: URL {
        URL(string: "widget-SpeezyWidget://widgetFamily/\(widgetFamily)")!
    }
    
    var body: some View {
        //Text(entry.date, style: .time) 
        
        ZStack {
            Image("background-gradient widget")
                .resizable()
                //.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 8) {
                Spacer(minLength:1)
                HStack {
                    //Speezy Logo - left aligned
                    Image("speezyLogo-widget")
                        .resizable()
                        .frame(width: 30.0, height: 30.0, alignment: .center)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(4)
                        //.scaleEffect(0.5)
                    
                }
                VStack {
                    
                    description
                    
                    Button(action: {
                        print("start Recording")
                        
                    }) {
                        Image("start-recording-button- widget")
                        .resizable()
                        .frame(width: 75.0, height: 75.0, alignment: .center)
                        .aspectRatio(0.5, contentMode: .fit)
                        .padding(.horizontal)
                        .widgetURL(deeplinkURL)
                    
                    }
                    Spacer(minLength:4)
             } // end VStack2
            } // end ZStack
        }
    }
}

@main
struct SpeezyWidget: Widget {
    let kind: String = "SpeezyWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            SpeezyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Speezy Record Widget")
        .description("This is the Speezy recording widget.")
    }
}

struct SpeezyWidget_Previews: PreviewProvider {
    static var previews: some View {
        SpeezyWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
