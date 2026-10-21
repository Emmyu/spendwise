import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../widgets/basics.dart';
import '../widgets/pressable.dart';
import 'chat_widgets.dart';

class AskAiScreen extends StatefulWidget {
  const AskAiScreen({super.key});

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final _scroll = ScrollController();
  List<ChatMessage>? _lastMessages;
  BusyState? _lastBusy;
  double _lastInset = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.messages;
    final busy = state.busy;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = inset > 0;

    final changed = _lastMessages == null ||
        _lastMessages!.length != messages.length ||
        !_sameMessages(_lastMessages!, messages) ||
        _lastBusy != busy ||
        _lastInset != inset;
    // Follow the conversation; the intro panel starts at the top.
    if (changed && (messages.isNotEmpty || busy != null)) {
      _scrollToEnd(animate: _lastMessages != null);
    }
    _lastMessages = messages;
    _lastBusy = busy;
    _lastInset = inset;

    // The composer floats above the nav pill, or above the keyboard while typing.
    final composerBottom = keyboardOpen ? inset + 12 : ShellMetrics.navBottom(context) + ShellMetrics.navHeight + 10;
    final listBottom = composerBottom + 52 + 42;
    final empty = messages.isEmpty && busy == null;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ask SpendWise', style: AppText.style(27, weight: 600, tracking: -0.02)),
                        const SizedBox(height: 3),
                        Text(
                          // After the first reply this shows the model in use, e.g. "Gemini · gemini-3.5-flash-lite".
                          state.assistantLabel ?? 'Records and explains your expenses',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.style(13, color: AppColors.ink3),
                        ),
                      ],
                    ),
                  ),
                  if (messages.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    CircleIconButton(
                      icon: LucideIcons.squarePen,
                      iconSize: 18,
                      label: 'New conversation',
                      onTap: state.resetChat,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(18, 4, 18, listBottom),
                children: [
                  if (empty) const IntroPanel(),
                  for (final (i, m) in messages.indexed) ...[
                    if (i > 0) const SizedBox(height: 18),
                    m.isUser ? UserBubble(m.text) : AiMessageView(m),
                  ],
                  if (busy != null) ...[
                    if (messages.isNotEmpty) const SizedBox(height: 18),
                    BusyRow(busy),
                  ],
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: composerBottom,
          child: const ChatComposer(),
        ),
      ],
    );
  }

  static bool _sameMessages(List<ChatMessage> a, List<ChatMessage> b) {
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }
}

class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (context.read<AppState>().send(_controller.text)) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 5, 5, 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x59133529), blurRadius: 26, spreadRadius: -14, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Message Ask SpendWise',
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                style: AppText.style(15),
                decoration: InputDecoration(
                  hintText: 'Describe an expense or ask a question',
                  hintStyle: AppText.style(15, color: AppColors.ink6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => Pressable(
              onTap: _send,
              semanticLabel: 'Send',
              width: 44,
              height: 44,
              color: value.text.trim().isNotEmpty ? AppColors.primary : AppColors.sendDisabled,
              borderRadius: BorderRadius.circular(22),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.sendHorizontal, size: 18, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
