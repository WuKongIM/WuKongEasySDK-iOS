import SwiftUI

/// The runnable native streaming screen; model credentials live only in view memory.
struct StreamDemoView: View {
    @StateObject private var controller = StreamController()
    @State private var base = "http://127.0.0.1:5001"
    @State private var question = "介绍一下流消息"
    @State private var reply = StreamController.defaultReply
    @State private var chunk = 3
    @State private var interval = 100
    @State private var settings = false
    @State private var realModel = false
    @State private var modelURL = ""
    @State private var modelName = ""
    @State private var modelKey = ""
    @State private var acceptanceStarted = false
    private var model: StreamModelConfig? {
        realModel ? StreamModelConfig(url: modelURL, model: modelName, key: modelKey) : nil
    }
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            intro
                            connection
                            if !controller.error.isEmpty {
                                Label(controller.error, systemImage: "exclamationmark.triangle")
                                    .font(.callout).foregroundColor(.orange)
                            }
                            if controller.timeline?.rows.isEmpty != false {
                                VStack(spacing: 10) {
                                    Image(systemName: "text.bubble").font(.largeTitle).foregroundColor(.blue)
                                    Text("一条回复，逐段到达").font(.headline)
                                    Text("连接演示会话后发送问题，观察实时事件更新同一个气泡。")
                                        .font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center)
                                }.frame(maxWidth: .infinity).padding(.vertical, 32)
                            }
                            ForEach(controller.timeline?.rows ?? []) { row in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Label(row.user ? "你" : "助手", systemImage: row.user ? "person.circle" : "sparkles")
                                            .font(.caption).foregroundColor(.secondary)
                                        Spacer()
                                        Text(row.status).font(.caption2).foregroundColor(.secondary)
                                    }
                                    Text(row.text.isEmpty ? "正在组织回复…" : row.text)
                                        .font(.body).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(14)
                                .background(row.user ? Color.blue.opacity(0.10) : Color.gray.opacity(0.10))
                                .cornerRadius(14).id(row.key)
                            }
                            Color.clear.frame(height: 1).id("stream-bottom")
                        }.padding()
                    }
                    .onChange(of: controller.timeline?.rows.last?.text) { _ in proxy.scrollTo("stream-bottom", anchor: .bottom) }
                }
                Divider()
                VStack(spacing: 10) {
                    if controller.generating {
                        HStack {
                            ProgressView().controlSize(.small)
                            Text(controller.generator).font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Button("取消生成") { controller.stop() }
                            Button("模拟失败") { controller.stop(failed: true) }.foregroundColor(.orange)
                        }
                    }
                    HStack {
                        TextField("输入问题", text: $question).textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("stream-question")
                        Button { let text = question; Task { await controller.send(text, reply: reply, chunk: chunk, interval: interval, model: model) } }
                        label: { Image(systemName: "arrow.up.circle.fill").font(.title) }
                        .disabled(!controller.canSend || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("发送问题")
                    }
                }.padding().background(Color.gray.opacity(0.04))
            }
            .navigationTitle("流式聊天 Demo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { Button { settings = true } label: { Image(systemName: "slider.horizontal.3") }.accessibilityLabel("演示设置") }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
        .sheet(isPresented: $settings) { settingsView }
        .onDisappear { modelKey = ""; controller.close() }
        #if DEBUG
        .onAppear {
            if !acceptanceStarted, ProcessInfo.processInfo.arguments.contains("--stream-acceptance") {
                acceptanceStarted = true
                let args = ProcessInfo.processInfo.arguments
                if let index = args.firstIndex(of: "--stream-acceptance"), args.count > index + 1 { base = args[index + 1] }
                Task { await StreamAcceptance.run(controller) }
            }
        }
        #endif
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("WuKongIM · 原生流消息", systemImage: "waveform.path").font(.headline)
            Text("SDK 实时收消息与事件 · 历史快照恢复")
                .font(.caption).foregroundColor(.secondary)
            HStack {
                Circle().fill(controller.readerOnline ? Color.green : Color.gray).frame(width: 7, height: 7)
                Text(controller.status).font(.caption)
                Spacer()
                Text(controller.generator).font(.caption).foregroundColor(.secondary)
            }
        }.padding(14).background(Color.blue.opacity(0.07)).cornerRadius(14)
    }
    private var connection: some View {
        VStack(spacing: 10) {
            TextField("HTTP API 地址", text: $base).textFieldStyle(.roundedBorder)
                .disabled(controller.hasSession || controller.connecting)
                .accessibilityIdentifier("stream-api")
            HStack {
                Button(controller.hasSession ? "连接会话" : "创建会话并连接") { Task { await controller.connect(base) } }
                    .buttonStyle(.borderedProminent).disabled(controller.busy || controller.generating || controller.readerOnline)
                if controller.hasSession {
                    Button(controller.readerOnline ? "断开接收端" : "重连接收端") { Task { await controller.toggleReceiver() } }
                        .buttonStyle(.bordered).disabled(controller.busy)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    private var settingsView: some View {
        NavigationView {
            Form {
                Section(header: Text("模拟回复")) {
                    TextEditor(text: $reply).frame(minHeight: 120)
                    Stepper("每段 \(chunk) 字", value: $chunk, in: 1...64)
                    Stepper("间隔 \(interval) ms", value: $interval, in: 40...2000, step: 20)
                }
                Section(header: Text("兼容模型 · Chat Completions SSE")) {
                    Toggle("使用真实模型", isOn: $realModel)
                    if realModel {
                        TextField("模型 URL / v1", text: $modelURL)
                        TextField("模型名称", text: $modelName)
                        SecureField("API Key（仅本屏内存）", text: $modelKey)
                    }
                    Text("开发演示直接请求模型。生产环境由可信后端持有模型 Key 并写入流事件。")
                        .font(.caption).foregroundColor(.secondary)
                }
                Section {
                    Button("单独生成回复") { controller.generate(reply: reply, chunk: chunk, interval: interval, model: model); settings = false }
                        .disabled(!controller.writerOnline || controller.generating || controller.busy)
                    Button("新会话") { modelKey = ""; controller.reset(); settings = false }
                        .disabled(controller.busy || controller.generating)
                }
                Section(header: Text("链路日志 · 最多 100 行")) {
                    Text(controller.logs.joined(separator: "\n")).font(.caption.monospaced())
                }
                Section {
                    Text("仅连接可写演示数据的开发集群；本页直接创建随机账号和群频道。")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("演示设置")
            .toolbar { Button("完成") { settings = false } }
        }
    }
}
