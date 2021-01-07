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
    
    //var thisImage: UIImage = UIImage(contentsOfFile: "KarlFace1") ?? (UIImage(named: "KarlFace1")
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var title: some View {
        
        Text("Speezy")
            .font(widgetFamily == .systemSmall ? Font.body.bold() : Font.title3.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.1)
            .foregroundColor(.white)
    }
    
    var description: some View {
        Text("Create a re[play]able audio message.")
            //.font(.subheadline)
            .font(.system(size: 10))
            .fontWeight(.medium)
            .lineLimit(2)
            .foregroundColor(.white)
    }
    
    var image: some View {
        Rectangle()
            //.overlay()
            
            .imageScale(/*@START_MENU_TOKEN@*/.medium/*@END_MENU_TOKEN@*/)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(ContainerRelativeShape())
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
            VStack {
                HStack {
                    //title
                    Image("speezyLogo-widget")
                        .resizable()
                        .frame(width: 30.0, height: 30.0, alignment: .center)
                        .aspectRatio(1, contentMode: .fit)
                        //.scaleEffect(0.5)
                    
                }
                description
                
                //Spacer()
//                Image("Buttons/start-recording-button")
//                    .resizable()
//                    .frame(width: 32.0, height: 32.0, alignment: .center)
//                    .aspectRatio(0.7, contentMode: .fit)
                //HStack {
                    //DiceView(n: leftDiceNumber)
                    //DiceView(n: rightDiceNumber)
                //}
                //.padding(.horizontal)
                //Spacer()
                Button(action: {
                    print("start Recording")
                    print("deep link goes here")
                    //self.leftDiceNumber = Int.random(in: 1...6)
                    //self.rightDiceNumber = Int.random(in: 1...6)
                }) {
                    //Text("Record")
                      //  .font(.system(size: 14))
                       // .fontWeight(.medium)
                        //.foregroundColor(.white)
                        //.padding(.horizontal)
                    Image("start-recording-button- widget")
                        .resizable()
                        .frame(width: 75.0, height: 75.0, alignment: .center)
                        .aspectRatio(0.5, contentMode: .fit)
                        .padding(.horizontal)
                        .widgetURL(deeplinkURL)
                    
                }
                //.padding(.vertical)
                //.background(Color.gray)
            }
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
