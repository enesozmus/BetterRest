//
//  ContentView.swift
//  BetterRest
//
//  Created by enesozmus on 6.03.2024.
//

import CoreML
import SwiftUI

struct ContentView: View {
    
    @State private var _wakeUp = defaultWakeTime
    @State private var _sleepAmount = 8.0
    @State private var _coffeeAmount = 1
    
    @State private var _alertTitle = ""
    @State private var _alertMessage = ""
    @State private var _showingAlert = false
    
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
    
    // ✅ Day 28: Challenge
    // #  There is no longer a "Calculate" button, so therefore the sleep time must be a computed property.
    private var sleepTime: Date? {
        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: _wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60
            
            let prediction = try model.prediction(
                wake: Int64(hour + minute),
                estimatedSleep: _sleepAmount,
                coffee: Int64(_coffeeAmount)
            )
            
            let sleepTime = _wakeUp - prediction.actualSleep
            return sleepTime
            
        } catch {
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                
                Section("Desired wake-up time") {
                    DatePicker("Please enter a time", selection: $_wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                }
                
                
                Section("Desired amount of sleep") {
                    Stepper("\(_sleepAmount.formatted()) hours", value: $_sleepAmount, in: 4...12, step: 0.25)
                }
                
                
                Section("Daily coffee intake") {
                    //Stepper("^[\(_coffeeAmount) cup](inflect: true)", value: $_coffeeAmount, in: 1...20)
                    Picker("Daily coffee intake", selection: $_coffeeAmount){
                        ForEach(1..<21){
                            Text($0 == 1 ? "1 cup" : "\($0) cups")
                        }
                    }
                }
                
                
                Section("Recommended bedtime") {
                    Text(sleepTime?.formatted(date: .omitted, time: .shortened) ?? "???")
                }
                
                
            }
            .navigationTitle("BetterRest")
            .toolbar {
                Button("Calculate", action: calculateBedtime)
            }
            .alert(_alertTitle, isPresented: $_showingAlert) {
                Button("OK") { }
            } message: {
                Text(_alertMessage)
            }
            
            
        }
    }
    
    // Functions
    func calculateBedtime() {
        
        // # I do want you to focus on the do/catch blocks, because using Core ML can throw errors in two places:
        // 1) loading the model 2) when we ask for predictions.
        
        // First, we need to create an instance of the SleepCalculator class, like this:
        do{
            // # That model instance is the thing that reads in all our data, and will output a prediction.
            // # The configuration is there in case you need to enable a handful of what are fairly obscure options.
            // # Perhaps folks working in machine learning full time need these.
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)
            
            
            // # Anyway, we trained our model with a CSV file containing the following fields:
            // 1) wake 2) estimatedSleep 3) coffee
            
            // # So, in order to get a prediction out of our model, we need to fill in those values.
            // # We already have two of them, because our sleepAmount and coffeeAmount properties are mostly good enough
            // # we just need to convert coffeeAmount from an integer to a Double so that Swift is happy.
            // # But figuring out the wake time requires more thinking, because our wakeUp property is a Date not a Double representing the number of seconds.
            // # Helpfully, this is where Swift’s DateComponents type comes in: ↓
            
            
            // # It stores all the parts required to represent a date as individual values.
            // # This means we can read the hour and minute components and ignore the rest.
            let components = Calendar.current.dateComponents([.hour, .minute], from: _wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60
            
            // # The next step is to feed our values into Core ML and see what comes out.
            // # This is done using the prediction() method of our model, which wants the wake time, estimated sleep, and coffee amount values required to make a prediction, all provided as Double values.
            
            let prediction = try model.prediction(
                wake: Int64(hour + minute),
                estimatedSleep: _sleepAmount,
                coffee: Int64(_coffeeAmount)
            )
            
            // # With that in place, prediction now contains how much sleep they actually need.
            // # However, it’s not a helpful value for users. What we want is to convert that into the time they should go to bed, which means we need to subtract that value in seconds from the time they need to wake up.
            // # And now we know exactly when they should go to sleep. Our final challenge, for now at least, is to show that to the user.
            
            // Time they need to go to bed...
            let sleepTime = _wakeUp - prediction.actualSleep
            
            _alertTitle = "Your ideal bedtime is…"
            // # This is a Date rather than a neatly formatted string, so we’ll pass it through the formatted() method to make sure it’s human-readable, then assign it to alertMessage.
            _alertMessage = sleepTime.formatted(date: .omitted, time: .shortened)
        } catch {
            _alertTitle = "Error"
            _alertMessage = "Sorry, there was a problem calculating your bedtime."
        }
        _showingAlert = true
    }
}

#Preview {
    ContentView()
}
