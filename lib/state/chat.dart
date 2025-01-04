part of 'p.dart';

class _Chat {
  late final messages = _gs<List<Message>>([]);

  late final scrollController = ScrollController();

  late final textEditingController = TextEditingController();

  late final focusNode = FocusNode();

  late final text = _gs("");

  late final canSend = _P((ref) {
    final _text = ref.watch(text);
    return _text.trim().isNotEmpty;
  });

  /// Disable sender
  late final receiving = _gs(false);

  late final received = _gs("");

  late final parsedStream = StreamController<String>();

  late final _currentStorageKey = _gsn<String>();

  String _fullString = "";

  late final EventDistributor _eventDistributor = EventDistributor(25.ms);

  late final scrollOffset = _gs(0.0);

  late final inputHeight = _gs(77.0);
}

/// Public methods
extension $Chat on _Chat {
  FV onSendPressed() async {
    final textToSend = text.v.trim();
    text.uc();
    focusNode.unfocus();
    await send(textToSend);
  }

  FV onEditingComplete() async {
    if (kDebugMode) print("💬 $runtimeType.onEditingComplete");
  }

  FV onSubmitted(String aString) async {
    if (kDebugMode) print("💬 $runtimeType.onSubmitted: $aString");
    final textToSend = text.v.trim();
    if (textToSend.isEmpty) return;
    text.uc();
    focusNode.unfocus();
    await send(textToSend);
  }

  FV send(String message) async {
    // debugger();
    if (kDebugMode) print("💬 $runtimeType.send: $message");

    if (Config.offlineChat) {
      final msg = await _feekSend(message);
      await Future.delayed(500.ms);
      await _feekReceive();
      return;
    }

    final id = DateTime.now().microsecondsSinceEpoch;
    final msg = Message(
      id: id,
      content: message,
      isMine: true,
    );
    messages.ua(msg);
    Future.delayed(34.ms).then((_) {
      scrollToBottom();
    });

    final streamId = DateTime.now().microsecondsSinceEpoch;

    // TODO: @wangce
    // final stream = _postStreaming(
    //   "/llm/chat",
    //   body: {
    //     "message": message,
    //     "channelId": currentChannel.id,
    //     "streamId": streamId,
    //   },
    //   headers: {
    //     "Accept": "text/event-stream",
    //   },
    // );

    _fullString = "";
    received.u(_fullString);
    receiving.u(true);

    final receiveId = DateTime.now().microsecondsSinceEpoch;

    final receiveMsg = Message(
      id: receiveId,
      content: "",
      isMine: false,
      changing: true,
    );

    messages.ua(receiveMsg);

    // TODO: @wangce
    // stream.listen((event) {
    //   _onStreamEvent(event: event, streamId: streamId.toString());
    // }, onDone: () {
    //   _onStreamDone(streamId: streamId.toString());
    //   _fullyReceived(id: receiveId);
    // }, onError: (error, stackTrace) {
    //   _onStreamError(streamId: streamId.toString(), error: error, stackTrace: stackTrace);
    //   _fullyReceived(id: receiveId);
    // });
  }

  FV scrollToBottom({Duration? duration, bool? animate = true}) async {
    scrollTo(offset: scrollController.position.maxScrollExtent, duration: duration, animate: animate);
  }

  FV scrollTo({required double offset, Duration? duration, bool? animate = true}) async {
    if (scrollController.hasClients == false) return;
    if (scrollController.offset == offset) return;
    if (animate == true) {
      await scrollController.animateTo(
        offset,
        duration: duration ?? 300.ms,
        curve: Curves.easeInOut,
      );
    } else {
      scrollController.jumpTo(offset);
    }
  }
}

/// Private methods
extension _$Chat on _Chat {
  FV _init() async {
    if (kDebugMode) print("💬 $runtimeType._init");

    if (Config.offlineChat) {
      final l = List.generate(20, (index) {
        return (index, HF.randomString(max: 500));
      }).m((param) {
        final isMine = HF.randomBool();
        return Message(
          id: param.$1,
          content: param.$2,
          isMine: isMine,
        );
      });
      messages.u(l);
    }

    if (kDebugMode) {
      messages.l((messages) {
        final changingMessages = messages.where((m) => m.changing).toList();
        if (changingMessages.length > 1) {
          if (kDebugMode) {
            print("""
😡 Changing messages count is bigger than 1,
check ...,
think about it,
multiple ... channels are changing?
          """);
          }
        }
      });
    }

    textEditingController.addListener(_onTextEditingControllerValueChanged);
    text.l(_onTextChanged);

    scrollController.addListener(() {
      scrollOffset.u(scrollController.offset);
    });
  }

  void _onTextEditingControllerValueChanged() {
    if (kDebugMode) print("💬 _onTextEditingControllerValueChanged");
    final textInController = textEditingController.text;
    if (text.v != textInController) text.u(textInController);
  }

  void _onTextChanged(String next) {
    if (kDebugMode) print("💬 _onTextChanged");
    final textInController = textEditingController.text;
    if (next != textInController) textEditingController.text = next;
  }

  Future<Message?> _feekSend(String message) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    final msg = Message(
      id: id,
      content: message,
      isMine: true,
    );
    messages.ua(msg);
    Future.delayed(34.ms).then((_) {
      scrollToBottom();
    });
    return msg;
  }

  FV _feekReceive() async {
    received.u("");
    receiving.u(true);

    final id = DateTime.now().millisecondsSinceEpoch;

    final msg = Message(
      id: id,
      content: "",
      isMine: false,
      changing: true,
    );

    messages.ua(msg);

    final length = HF.randomInt(max: 500, min: 100);

    if (kDebugMode) print("💬 length: $length");

    for (var i = 0; i < length; i++) {
      await Future.delayed((HF.randomInt(max: 30) + 20).ms);
      final charactor = HF.randomString(min: 1, max: 1, spacingRate: 0.2);
      received.ua(charactor);
      Future.delayed(13.ms).then((_) {
        scrollToBottom(duration: 100.ms);
      });
    }

    receiving.u(false);
    await _fullyReceived(id: id);
  }

  FV _fullyReceived({required int id}) async {
    final currentMessages = [...messages.v];
    bool found = false;
    for (var i = 0; i < currentMessages.length; i++) {
      final msg = currentMessages[i];
      if (msg.id == id) {
        final newMsg = Message(
          id: msg.id,
          content: received.v,
          isMine: msg.isMine,
          changing: false,
        );
        // TODO: @wangce replace!
        currentMessages.replaceRange(i, i + 1, [newMsg]);
        found = true;
        break;
      }
    }
    assert(found, "😡 $runtimeType._fullyReceived: message not found");
    messages.u(currentMessages);
  }

  FV _onStreamEvent({
    required String event,
    required String streamId,
  }) async {
    String eventStr = event.toString().trim();
    if (eventStr.isEmpty) return;
    _fullString += eventStr;

    String temp = "";
    for (var i = 0; i < _fullString.length; i++) {
      final char = _fullString[i];
      temp += char;
      final shouldSend = temp.endsWith("data:{") && temp.startsWith("data:{") && temp.length > 7;
      if (shouldSend) {
        final textToBeSent = temp.substring(5, temp.length - 6).trim();

        try {
          final json = jsonDecode(textToBeSent);
          final _received = json["content"];
          // if (kDebugMode) print("💬 _received: $_received");
          _eventDistributor.addEvent(() {
            received.ua(_received);
          });
        } catch (e) {
          if (kDebugMode) print("😡 $runtimeType._onStreamEvent: $e");
        }

        temp = temp.substring(temp.length - 6, temp.length);
        Future.delayed(13.ms).then((_) {
          scrollToBottom(duration: 100.ms);
        });
      }
    }

    _fullString = temp;
  }

  FV _onStreamDone({
    required String streamId,
  }) async {
    if (kDebugMode) print("💬 _onStreamDone");
    if (kDebugMode) print("💬 _fullString: $_fullString");
    receiving.u(false);
    _eventDistributor.executeAllRemaining();
  }

  FV _onStreamError({
    required String streamId,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    if (kDebugMode) print("💬 _onStreamError");
    if (kDebugMode) print("😡 error: $error");
    receiving.u(false);
    _eventDistributor.executeAllRemaining();
  }
}
