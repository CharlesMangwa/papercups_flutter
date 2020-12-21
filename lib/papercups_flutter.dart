library papercups_flutter;

// Imports.
import 'package:flutter/material.dart';
import 'utils/utils.dart';
import 'widgets/widgets.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'models/models.dart';

// Exports.
export 'models/classes.dart';

/// Returns the webview which contains the chat. To use it simply call PaperCupsWidget(), making sure to add the props!
class PaperCupsWidget extends StatefulWidget {
  /// Initialize the props that you will pass on PaperCupsWidget.
  final Props props;

  PaperCupsWidget({
    @required this.props,
  });

  @override
  _PaperCupsWidgetState createState() => _PaperCupsWidgetState();
}

class _PaperCupsWidgetState extends State<PaperCupsWidget> {
  bool _connected = false;
  PhoenixSocket _socket;
  PhoenixChannel _channel;
  PhoenixChannel _conversationChannel;
  List<PapercupsMessage> messages = [];
  PapercupsCustomer customer;
  bool _canJoinConversation = false;
  Conversation _conversation;
  ScrollController _controller = ScrollController();
  bool _sending = false;
  final GlobalKey _lvKey = GlobalKey();

  @override
  void initState() {
    if (widget.props.baseUrl.contains("http"))
      throw "Do not provide a protocol in baseURL";
    if (widget.props.baseUrl.endsWith("/")) throw "Do not provide a trailing /";
    if (widget.props.primaryGradient != null &&
        widget.props.primaryColor != null)
      throw "Expected either primaryColor or primaryGradient to be null";
    if (widget.props.customer != null) {
      setCustomer(PapercupsCustomer(
        email: widget.props.customer.email,
        externalId: widget.props.customer.externalId,
        name: widget.props.customer.name,
      ));
    }
    super.initState();
  }

  @override
  void dispose() {
    _channel.close();
    _conversationChannel.close();
    _socket.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (widget.props.greeting != null) {
      messages = [
        PapercupsMessage(
          body: widget.props.greeting,
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          accountId: widget.props.accountId,
          user: User(
            fullName: widget.props.companyName,
          ),
          userId: 0,
          id: "greeting",
        ),
      ];
    }
    if (_socket == null) {
      _socket =
          PhoenixSocket("wss://" + widget.props.baseUrl + '/socket/websocket')
            ..connect();

      _socket.closeStream.listen((event) {
        _connected = false;
      });

      _socket.openStream.listen(
        (event) {
          return _connected = true;
        },
      );
    }
    if (widget.props.customer != null &&
        widget.props.customer.externalId != null &&
        (customer == null || customer.createdAt == null) &&
        _conversation == null) {
      getCustomerHistory(
        conversationChannel: _conversationChannel,
        c: customer,
        messages: messages,
        rebuild: rebuild,
        setConversationChannel: setConversationChannel,
        setCustomer: setCustomer,
        socket: _socket,
        widget: widget,
      );
    }
    super.didChangeDependencies();
  }

  void setCustomer(PapercupsCustomer c, {rebuild = false}) {
    customer = c;
    if (rebuild) setState(() {});
  }

  void setConversation(Conversation c) {
    _conversation = c;
  }

  void setConversationChannel(PhoenixChannel c) {
    _conversationChannel = c;
  }

  void rebuild(void Function() fn, {bool stateMsg = false, animate = false}) {
    _sending = stateMsg;
    if (mounted) setState(fn);
    if (animate && mounted && messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.position.maxScrollExtent != null)
          _controller.animateTo(
            _controller.position.maxScrollExtent,
            curve: Curves.easeIn,
            duration: Duration(milliseconds: 300),
          );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    initChannels(
      _connected,
      _socket,
      _channel,
      widget.props,
      _canJoinConversation,
      rebuild,
    );
    if (widget.props.primaryColor == null &&
        widget.props.primaryGradient == null)
      widget.props.primaryColor = Theme.of(context).primaryColor;

    if (_sending &&
        mounted &&
        messages.isNotEmpty &&
        _controller.position.maxScrollExtent != null)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (_controller.position.maxScrollExtent != null)
            _controller.animateTo(
              _controller.position.maxScrollExtent,
              curve: Curves.easeIn,
              duration: Duration(milliseconds: 300),
            );
        },
      );

    return Container(
      color: Theme.of(context).canvasColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Header(props: widget.props),
          if (widget.props.showAgentAvailability)
            AgentAvailability(widget.props),
          Expanded(
            child: ChatMessages(
              widget.props,
              messages,
              _controller,
              _sending,
              key: _lvKey,
            ),
          ),
          PoweredBy(),
          (widget.props.requireEmailUpfront &&
                  (customer == null || customer.email == null))
              ? RequireEmailUpfront(setCustomer, widget.props)
              : SendMessage(
                  props: widget.props,
                  customer: customer,
                  setCustomer: setCustomer,
                  setConversation: setConversation,
                  conversationChannel: _conversationChannel,
                  setConversationChannel: setConversationChannel,
                  conversation: _conversation,
                  socket: _socket,
                  setState: rebuild,
                  messages: messages,
                  sending: _sending,
                ),
        ],
      ),
    );
  }
}
