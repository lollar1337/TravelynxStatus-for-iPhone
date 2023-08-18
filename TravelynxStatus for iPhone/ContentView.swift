import SwiftUI


struct StatusView: View {
    
    @State private var TrainType: String = "Train Type"
    @State private var From: String = "From"
    @State private var To: String = "To"
    @State private var Destination: String = "Destination"
    @State private var Status: String = "Status"
    @State private var timer: Timer?
    @AppStorage("apiKey") private var apiKey: String = ""
    @State private var checkIn: CheckIn?
    
    func fetchDataFromServer() {
        let cleanedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = "https://travelynx.de/api/v1/status/\(cleanedApiKey)"
        
        if let url = URL(string: urlString) {
            let session = URLSession.shared
            let task = session.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                
                if let data = data {
                    if let decodedCheckIn = decodeCheckIn(from: data) {
                        DispatchQueue.main.async {
                            self.updateUI(with: decodedCheckIn)
                        }
                    }
                }
            }
            
            task.resume()
        }
    }

    func decodeCheckIn(from data: Data) -> CheckIn? {
        do {
            let decoder = JSONDecoder()
            let decodedCheckIn = try decoder.decode(CheckIn.self, from: data)
            return decodedCheckIn
            
        } catch {
            print("Error decoding data: \(error)")
            return nil
        }
    }
    
    func updateUI(with checkIn: CheckIn) {
        self.checkIn = checkIn
        
        if (checkIn.train.line == nil) {
            self.TrainType = checkIn.train.type + " " + checkIn.train.no
        } else {
            self.TrainType = checkIn.train.type + (checkIn.train.line != nil ? " " + checkIn.train.line! : "")
        }
        
        self.Destination = "nach " + checkIn.toStation.name
        
        self.From = checkIn.fromStation.name
        self.To = checkIn.toStation.name
        
        if (checkIn.checkedIn == true) {
            self.Status = "Unterwegs mit:"
        } else {
            //let departureDate =
            self.Status = "Zuletzt gesehen am " + formatDate(checkIn.fromStation.realTime!)
        }
    }

    func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
    func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.YYYY"
        return dateFormatter.string(from: date)
    }
    
    func getMapURL() -> URL {
        if let latitude = checkIn?.toStation.latitude,
           let longitude = checkIn?.toStation.longitude {
            let urlString = "maps://maps.apple.com/?q=\(latitude),\(longitude)"
            return URL(string: urlString)!
        } else {
            return URL(string: "http://maps.apple.com/")!
        }
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 23))
                        .foregroundColor(.indigo)
                    Text("Travelynx Status")
                        .font(.system(size: 28))
                        .fontWeight(.bold)
                }
                .padding(.bottom, 20)
            
                VStack(alignment: .leading, spacing: 0) {
                    Text(Status)
                        .italic(true)
                        .font(.system(size: 18))
                        .fontWeight(.regular)
                        .padding(.bottom, 20)
                
                    Text(TrainType)
                        .font(.system(size: 25))
                        .fontWeight(.bold)
                
                    Text(Destination)
                        .font(.system(size: 18))
                        .fontWeight(.regular)
                        .padding(.bottom, 20)
                    
                    Text(From)
                        .font(.system(size: 18))
                        .fontWeight(.bold)

                    if let fromScheduledTime = checkIn?.fromStation.scheduledTime,
                       let fromRealTime = checkIn?.fromStation.realTime {
                        let scheduledTime = formatTimestamp(fromScheduledTime)
                        let realTime = formatTimestamp(fromRealTime)
                        
                        let textColor: Color = scheduledTime == realTime ? .green : (fromRealTime > fromScheduledTime ? .red : .secondary)
                        
                        if (checkIn?.checkedIn == true) {
                            HStack {
                                Text("Departure:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text(scheduledTime)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text(realTime)
                                    .font(.system(size: 12))
                                    .foregroundColor(textColor)
                                    .italic()
                            }
                        }
                    }

                    
                    if let intermediateStops = checkIn?.intermediateStops, !intermediateStops.isEmpty {
                        List(intermediateStops, id: \.name) { stop in
                            VStack(alignment: .leading) {
                                Text(stop.name)
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                
                                if let scheduledArrival = stop.scheduledArrival, let realArrival = stop.realArrival {
                                    
                                    let scheduledTime = formatTimestamp(scheduledArrival)
                                    let realTime = formatTimestamp(realArrival)
                                    
                                    let textColor: Color = scheduledTime == realTime ? .green : (realArrival > scheduledArrival ? .red : .secondary)
                                    HStack {
                                        Text("Arrival:")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                                    
                                        Text(scheduledTime)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                                    
                                        Text(realTime)
                                            .font(.system(size: 12))
                                            .foregroundColor(textColor)
                                            .italic()
                                    }
                                }
                                            
                                            if let scheduledDeparture = stop.scheduledDeparture, let realDeparture = stop.realDeparture {
                                                let scheduledTime = formatTimestamp(scheduledDeparture)
                                                let realTime = formatTimestamp(realDeparture)
                                                
                                                let textColor: Color = scheduledTime == realTime ? .green : (realDeparture > scheduledDeparture ? .red : .secondary)

                                                HStack {
                                                    Text("Departure:")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(scheduledTime)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(realTime)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(textColor)
                                                        .italic()
                                                }
                                            }
                                
                            }
                        }
                        .listStyle(PlainListStyle())    
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)
                    } else {
                        Text("No Intermediate Stops")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                    
                    Link(destination: getMapURL()) {
                        Text(To)
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                            .padding(.top, 10)
                    }
                    
                    if let toScheduledTime = checkIn?.toStation.scheduledTime,
                       let toRealTime = checkIn?.toStation.realTime {
                        let scheduledTime = formatTimestamp(toScheduledTime)
                        let realTime = formatTimestamp(toRealTime)
                        
                        let textColor: Color = scheduledTime == realTime ? .green : (toRealTime > toScheduledTime ? .red : .secondary)
                        
                        if (checkIn?.checkedIn == true) {
                            HStack {
                                Text("Arrival:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text(scheduledTime)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text(realTime)
                                    .font(.system(size: 12))
                                    .foregroundColor(textColor)
                                    .italic()
                            }
                        }
                        
                    }

                }
                
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
                .padding(.trailing, 20)
            
            
                
                Spacer()
                
                if apiKey.isEmpty {
                    Text("Please set an API key in the settings.")
                        .foregroundColor(.red)
                        .padding(.bottom, 20)
                }
            
                Button("Refresh") { fetchDataFromServer() }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 20)
        }
        
        .onAppear {
            fetchDataFromServer()
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                            fetchDataFromServer()
            }
        }
        
    }

}


struct CheckIn: Decodable {
    
    struct Location: Codable {
        let ds100: String?
        let latitude: Double?
        let longitude: Double?
        let name: String
        let scheduledArrival: Int?
        let realArrival: Int?
        let scheduledDeparture: Int?
        let realDeparture: Int?
        let scheduledTime: Int?
        let realTime:Int?
    }
    
    struct Train: Codable {
        let id: String
        let line: String?
        let no: String
        let type: String
    }
    
    struct Visibility: Codable {
        let desc: String
        let level: Int
    }
    
    let actionTime: Int
    let checkedIn: Bool
    let comment: String?
    let deprecated: Bool
    let fromStation: Location
    let intermediateStops: [Location]
    let toStation: Location
    let train: Train
    let visibility: Visibility
    
}

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("API Key")) {
                TextField("Enter API Key", text: $apiKey)
            }
        }
        .navigationTitle("Settings")
    }
}
