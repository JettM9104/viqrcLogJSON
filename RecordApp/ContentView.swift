import SwiftUI

// MARK: - Record Model

struct Record: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var selectedOption: String
    var scale: Int
    var additionalInfo: String
    var yesOrNo: Bool
    var numberList: [Double]
}

// MARK: - Persistent Store

class RecordStore: ObservableObject {
    @Published var records: [Record] = []

    private let fileName = "records.json"

    init() {
        load()
    }

    private func getFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func load() {
        let url = getFileURL()
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode([Record].self, from: data) {
            self.records = decoded
        }
    }

    func save() {
        let url = getFileURL()
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: url)
        }
    }

    func add(_ record: Record) {
        records.append(record)
        save()
    }

    func update(_ record: Record) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var store = RecordStore()
    @State private var showForm = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.records) { record in
                    NavigationLink {
                        RecordFormView(record: record) { updated in
                            store.update(updated)
                        }
                    } lab: {
                        VStack(alignment: .leading) {
                            Text(record.name).bold()
                            Text("Option: \(record.selectedOption), Scale: \(record.scale), Yes/No: \(record.yesOrNo ? "Yes" : "No")")
                                .font(.subheadline)
                            if !record.numberList.isEmpty {
                                Text("Numbers: \(record.numberList.map { String($0) }.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: store.delete)
            }
            .navigationTitle("Records")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showForm = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                RecordFormView { newRecord in
                    store.add(newRecord)
                }
            }
        }
    }
}

// MARK: - Record Form Vie

struct RecordFormView: View {
    var record: Record?
    var onSave: (Record) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedOption = ""
    @State private var customOption = ""
    @State private var scale: Double = 5
    @State private var additionalInfo = ""
    @State private var yesOrNo = false
    @State private var numberListText = ""

    let options = ["Hero Bot", "Improved Hero Bot", "Backroller w/ T Fling", "Backroller Bot", "Dual Flywheel", "Single FLywheel", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Name", text: $name)

                    Picker("Multiple Choice", selection: $selectedOption) {
                        ForEach(options, id: \.self) { Text($0) }
                    }

                    if selectedOption == "Other" {
                        TextField("Custom Option", text: $customOption)
                    }

                    Slider(value: $scale, in: 1...10, step: 1) {
                        Text("Scale")
                    }
                    Text("Scale: \(Int(scale))")

                    Toggle("Yes or No", isOn: $yesOrNo)
                }

                Section(header: Text("List of Numbers")) {
                    TextField("Comma-separated numbers (e.g. 1, 2.5, 3)", text: $numberListText)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section(header: Text("Additional Info")) {
                    TextField("More info", text: $additionalInfo)
                }
            }
            .navigationTitle(record == nil ? "Add Record" : "Edit Record")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalOption = selectedOption == "Other" ? customOption : selectedOption
                        let numberList = numberListText
                            .split(separator: ",")
                            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

                        let newRecord = Record(
                            id: record?.id ?? UUID(),
                            name: name,
                            selectedOption: finalOption,
                            scale: Int(scale),
                            additionalInfo: additionalInfo,
                            yesOrNo: yesOrNo,
                            numberList: numberList
                        )

                        onSave(newRecord)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let record = record {
                    name = record.name
                    selectedOption = options.contains(record.selectedOption) ? record.selectedOption : "Other"
                    customOption = options.contains(record.selectedOption) ? "" : record.selectedOption
                    scale = Double(record.scale)
                    additionalInfo = record.additionalInfo
                    yesOrNo = record.yesOrNo
                    numberListText = record.numberList.map { String($0) }.joined(separator: ", ")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
