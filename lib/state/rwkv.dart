part of 'p.dart';

class _RWKV {
  SendPort? sendPort;

  late final messagesController = StreamController<String>();

  late final String firstMessage = "Hello!";

  late final ready = _gs(false);
  late final generating = _gs(false);
}

/// Public methods
extension $RWKV on _RWKV {
  void send(String message) {
    final messages = P.chat.messages.v.m((e) => e.content);
    sendPort!.send(("message", [...messages, message]));
  }
}

/// Private methods
extension _$RWKV on _RWKV {
  FV _init() async {
    if (kDebugMode) print("✅ initRWKV start");
    ready.u(false);
    await _initRWKV();
    ready.u(true);
    if (kDebugMode) print("✅ initRWKV end");
  }

  Future<void> _initRWKV() async {
    final modelPath = await getModelPath("assets/model/RWKV-x070-World-0.1B-v2.8-20241210-ctx4096-ncnn.bin");
    final _ = await getModelPath("assets/model/RWKV-x070-World-0.1B-v2.8-20241210-ctx4096-ncnn.param");
    final tokenizerPath = await getModelPath("assets/model/b_rwkv_vocab_v20230424.txt");
    final backendName = "ncnn";

    final rootIsolateToken = RootIsolateToken.instance;
    final rwkvMobile = RWKVMobile();
    final availableBackendNames = rwkvMobile.getAvailableBackendNames();
    if (kDebugMode) print("💬 availableBackendNames: $availableBackendNames");
    final receivePort = ReceivePort();

    rwkvMobile.runIsolate(
      modelPath,
      tokenizerPath,
      backendName,
      receivePort.sendPort,
      rootIsolateToken!,
    );

    receivePort.listen(_onMessage);

    List<String> messagesList = [firstMessage];
    while (sendPort == null) {
      if (kDebugMode) print("💬 waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 100));
    }
    // TODO: Decide a better prompt to use
    sendPort!.send(("setPrompt", "User: hi\n\nAssistant: Hi. I am your assistant and I will provide expert full response in full details. Please feel free to ask any question and I will always answer it.\n\n"));
    sendPort!.send(("getPrompt", null));
    sendPort!.send(("setSamplerParams", {"temperature": 2.0, "top_k": 128, "top_p": 0.5, "presence_penalty": 0.5, "frequency_penalty": 0.5, "penalty_decay": 0.996}));
    sendPort!.send(("getSamplerParams", null));
    sendPort!.send(("message", messagesList));
  }

  void _onMessage(message) {
    if (message is SendPort) {
      sendPort = message;
      return;
    }

    if (message["samplerParams"] != null) {
      if (kDebugMode) print("💬 Got samplerParams: ${message["samplerParams"]}");
      return;
    }

    if (message["currentPrompt"] != null) {
      if (kDebugMode) print("💬 Got currentPrompt: \"${message["currentPrompt"]}\"");
      return;
    }

    if (message["generateStart"] == true) {
      generating.u(true);
      return;
    }

    if (message["response"] != null) {
      final responseText = message["response"].toString();
      if (kDebugMode) print("🚧 response:\n$responseText");
      messagesController.add(responseText);
      generating.u(false);
      return;
    }

    if (message["streamResponse"] != null) {
      final responseText = message["streamResponse"].toString();
      if (kDebugMode) print("🚧 streamResponse:\n$responseText");
      messagesController.add(responseText);
      return;
    }
  }
}
