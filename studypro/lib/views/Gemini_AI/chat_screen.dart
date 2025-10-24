import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/providers/theme_provider.dart';

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final File? image;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.image,
  });
}

class ChatWithGeminiScreen extends StatefulWidget {
  const ChatWithGeminiScreen({super.key});

  @override
  _ChatWithGeminiScreenState createState() => _ChatWithGeminiScreenState();
}

class _ChatWithGeminiScreenState extends State<ChatWithGeminiScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Gemini _gemini = Gemini.instance;
  final ImagePicker _picker = ImagePicker();
  
  final List<Message> _messages = [];
  File? _selectedImage;
  bool _isLoading = false;
  bool _isStreaming = false;
  String _streamingMessage = '';

  @override
  void initState() {
    super.initState();
    _messages.add(Message(
      content: "Hello! I'm your AI assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() {
      _messages.add(Message(
        content: text.isEmpty ? " Image sent" : text,
        isUser: true,
        timestamp: DateTime.now(),
        image: _selectedImage,
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    if (_selectedImage != null) {
      _sendTextAndImage(text);
    } else {
      _sendPromptStream(text);
    }

    setState(() {
      _selectedImage = null;
    });
  }

  void _sendPromptStream(String text) {
    setState(() {
      _isLoading = true;
      _isStreaming = true;
      _streamingMessage = '';
    });

    setState(() {
      _messages.add(Message(
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    _gemini.promptStream(parts: [Part.text(text)]).listen(
      (value) {
        setState(() {
          _streamingMessage += value?.output ?? '';
          _messages.last = Message(
            content: _streamingMessage,
            isUser: false,
            timestamp: _messages.last.timestamp,
          );
        });
        _scrollToBottom();
      },
      onDone: () {
        setState(() {
          _isLoading = false;
          _isStreaming = false;
        });
      },
      onError: (e) {
        setState(() {
          _messages.last = Message(
            content: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: _messages.last.timestamp,
          );
          _isLoading = false;
          _isStreaming = false;
        });
      },
    );
  }

  void _sendTextAndImage(String text) async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final response = await _gemini.textAndImage(
        text: text.isEmpty ? "What do you see in this image?" : text,
        images: [imageBytes],
      );

      String responseText = 'No response';
      if (response?.content?.parts != null && response!.content!.parts!.isNotEmpty) {
        final lastPart = response.content!.parts!.last;
        if (lastPart is TextPart) {
          responseText = lastPart.text;
        } else {
          for (var part in response.content!.parts!) {
            if (part is TextPart) {
              responseText = part.text;
              break;
            }
          }
        }
      }

      setState(() {
        _messages.add(Message(
          content: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(
          content: 'Sorry, I couldn\'t process the image. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(Message(
        content: "Chat cleared! How can I help you?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.background(context),
        foregroundColor: themeProvider.isDarkMode ? AppColors.primaryLight : AppColors.info,
        title:  Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.background(context),
              child: Image.asset('assets/gemini-color.png'),
            ),
            SizedBox(width: SizeConfig().scaleWidth(12, context)),
            Text('Gemini AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon:  Icon(Icons.delete, color: themeProvider.isDarkMode ? AppColors.primaryLight : AppColors.info),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          if (_isLoading && !_isStreaming)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: SizeConfig().scaleWidth(20, context),
                    height: SizeConfig().scaleHeight(20, context),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                   SizedBox(width: SizeConfig().scaleWidth(12, context)),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.shadow(context)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: SizeConfig().scaleWidth(60, context),
                      height: SizeConfig().scaleHeight(60, context),
                      fit: BoxFit.cover,
                    ),
                  ),
                   SizedBox(width: SizeConfig().scaleWidth(12, context)),
                   Expanded(
                    child: Text(
                      'Image selected',
                      style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary(context)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

 
      
LayoutBuilder(
  builder: (context, constraints) {
      final isTablet = constraints.maxWidth > 600;
      final padding = isTablet ? 24.0 : 16.0;
      final iconSize = isTablet ? 28.0 : 24.0;
  return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, -2),
                blurRadius: 8,
                color: AppColors.shadow(context),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.image,
                      color: _selectedImage != null ? AppColors.iconPrimary : AppColors.iconSecondary(context),
                      size: iconSize,
                    ),
                    onPressed: _pickImage,
                    tooltip: 'Pick Image',
                  ),
                ),
                 SizedBox(width: SizeConfig().scaleWidth(12, context)),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                     
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        
                        color: AppColors.border(context)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                        border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            
                            filled: true,
                            fillColor: AppColors.cardBackground(context),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 20,
                          vertical: isTablet ? 16 : 12,
                        ),
                      ),
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {}); 
                        }
                      },
                    ),
                  ),
                ),
            
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _messageController.text.trim().isNotEmpty || _selectedImage != null ? (isTablet ? 70.0 : 60.0) : 0.0,
                  child: AnimatedOpacity(
                    opacity: _messageController.text.trim().isNotEmpty || _selectedImage != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _messageController.text.trim().isEmpty && _selectedImage == null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.send, color: Colors.white, size: iconSize),
                          onPressed: _isLoading ? null : _sendMessage,
                          tooltip: 'Send Message',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );}
),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.cardBackground(context),
              child: Image.asset('assets/gemini-color.png',height: SizeConfig().scaleHeight(20, context),width: SizeConfig().scaleWidth(20, context),),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser ? themeProvider.isDarkMode ? AppColors.cardBackground(context) : AppColors.cardBackground(context)  : themeProvider.isDarkMode ? AppColors.cardBackground(context) : AppColors.cardBackground(context) ,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                    color: themeProvider.isDarkMode ? AppColors.shadow(context) : AppColors.shadow(context)
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        message.image!,
                        width: double.infinity,
                        height: SizeConfig().scaleHeight(200, context),
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (message.content.isNotEmpty) 
                     SizedBox(height: SizeConfig().scaleHeight(8, context)),
                  ],
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? AppColors.textPrimary(context) : AppColors.textPrimary(context),
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                   SizedBox(height: SizeConfig().scaleHeight(4, context)),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
             SizedBox(width: SizeConfig().scaleWidth(8, context)),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600], size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}