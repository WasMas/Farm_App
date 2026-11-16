
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message.dart';

class ChatFlyout extends ConsumerStatefulWidget {
  const ChatFlyout({super.key});

  @override
  ConsumerState<ChatFlyout> createState() => _ChatFlyoutState();
}

class _ChatFlyoutState extends ConsumerState<ChatFlyout> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> _messages = [];

  XFile? _selectedImage;
  int? _conversationId;

  bool _open = false;
  bool _loading = false;
  bool _sending = false;

  String? _error;

  ChatRepository get _repository {
    return ChatRepository(ref.read(dioProvider));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // OPEN CHAT AND LOAD CONVERSATION
  // ------------------------------------------------------------

  Future<void> _openChat() async {
    setState(() {
      _open = true;
      _error = null;
    });

    // If the conversation is already loaded, reuse it.
    if (_conversationId != null) return;

    setState(() {
      _loading = true;
    });

    try {
      // Get the user's latest conversation or create a new one.
      final id = await _repository.getOrCreateConversation();

      // Load previous messages.
      final messages = await _repository.getMessages(id);

      if (!mounted) return;

      setState(() {
        _conversationId = id;
        _messages = messages;
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load the chat. Please try again.';
      });
    }
  }

  // ------------------------------------------------------------
  // SELECT IMAGE
  // ------------------------------------------------------------

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not select the image.'),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SEND MESSAGE
  // ------------------------------------------------------------

  Future<void> _sendMessage() async {
    final String content = _textController.text.trim();
    final XFile? image = _selectedImage;

    // Do not send an empty message.
    if (content.isEmpty && image == null) return;

    if (_conversationId == null || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    // Clear the input after saving its current contents locally.
    _textController.clear();

    setState(() {
      _selectedImage = null;
    });

    try {
      final List<ChatMessage> newMessages =
          await _repository.sendMessage(
        conversationId: _conversationId!,
        content: content,
        image: image,
      );

      if (!mounted) return;

      setState(() {
        _messages.addAll(newMessages);
        _sending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
        _error = 'Your message could not be sent. Please try again.';
      });

      // The backend saves the user's message before contacting Gemini.
      // Reload history in case the AI request failed after saving it.
      try {
        final messages =
            await _repository.getMessages(_conversationId!);

        if (!mounted) return;

        setState(() {
          _messages = messages;
        });

        _scrollToBottom();
      } catch (_) {
        // Keep the original error visible.
      }
    }
  }

  // ------------------------------------------------------------
  // SCROLL TO LATEST MESSAGE
  // ------------------------------------------------------------

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ------------------------------------------------------------
  // MESSAGE BUBBLE
  // ------------------------------------------------------------

  Widget _buildMessage(ChatMessage message) {
    final bool isUser = message.isUser;

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 290,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFFE4E9D8)
              : const Color(0xFFF1F1ED),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display attached image.
            if (message.image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  message.image!,
                  width: 240,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'Image could not be displayed.',
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Display message text.
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CHAT WINDOW
  // ------------------------------------------------------------

  Widget _buildChatWindow() {
    final Size screenSize = MediaQuery.sizeOf(context);

    final double chatWidth =
        screenSize.width < 420
            ? screenSize.width - 32
            : 370;

    final double chatHeight =
        (screenSize.height - 180).clamp(300.0, 520.0);

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: chatWidth,
        height: chatHeight,
        child: Column(
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Container(
              padding: const EdgeInsets.all(14),
              color: const Color(0xFF52613E),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE7EBD9),
                    child: Icon(
                      Icons.eco,
                      color: Color(0xFF52613E),
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Farm Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ask about plants and farming',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        _open = false;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // MESSAGES
            // --------------------------------------------------

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _error != null && _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 12),

                                ElevatedButton(
                                  onPressed: () {
                                    _conversationId = null;
                                    _openChat();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _messages.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Hello! 🌱\n\n'
                                  'Ask me about crops, plant diseases, '
                                  'watering, soil, or fertilizers.\n\n'
                                  'You can also send me a plant photo.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                return _buildMessage(
                                  _messages[index],
                                );
                              },
                            ),
            ),

            // --------------------------------------------------
            // SENDING INDICATOR
            // --------------------------------------------------

            if (_sending)
              const LinearProgressIndicator(
                minHeight: 2,
              ),

            // --------------------------------------------------
            // ERROR MESSAGE
            // --------------------------------------------------

            if (_error != null && _messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                ),
              ),

            // --------------------------------------------------
            // SELECTED IMAGE PREVIEW
            // --------------------------------------------------

            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image,
                      size: 18,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        _selectedImage!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // --------------------------------------------------
            // MESSAGE INPUT
            // --------------------------------------------------

            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Attach image button.
                  IconButton(
                    tooltip: 'Attach plant photograph',
                    onPressed: _sending ? null : _pickImage,
                    icon: const Icon(
                      Icons.image_outlined,
                    ),
                  ),

                  // Text input.
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 3,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your plants...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Send button.
                  IconButton.filled(
                    onPressed: _sending ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FLOATING CHAT BUTTON
  // ------------------------------------------------------------

 
@override
Widget build(BuildContext context) {
  final screenSize = MediaQuery.sizeOf(context);

  final double chatWidth =
      screenSize.width < 420
          ? screenSize.width - 32
          : 370;

  final double chatHeight =
      (screenSize.height - 180).clamp(300.0, 520.0);

  return SizedBox(
    width: chatWidth,
    height: chatHeight + 70,
    child: Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        if (_open)
          Positioned(
            right: 0,
            bottom: 70,
            child: _buildChatWindow(),
          ),

        FloatingActionButton(
          heroTag: 'farmAssistantButton',
          backgroundColor: const Color(0xFF52613E),
          foregroundColor: Colors.white,
          tooltip: 'Open Farm Assistant',
          onPressed: _open
              ? () {
                  setState(() {
                    _open = false;
                  });
                }
              : _openChat,
          child: Icon(
            _open ? Icons.close : Icons.eco,
          ),
        ),
      ],
    ),
  );
}
}
