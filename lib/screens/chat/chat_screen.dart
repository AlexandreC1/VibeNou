import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/profile_view_service.dart';
import '../../services/supabase_image_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../widgets/report_dialog.dart';
import '../../widgets/image_gallery_viewer.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;
  final UserModel currentUser;

  const ChatScreen({
    super.key,
    required this.otherUser,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final SupabaseImageService _imageService = SupabaseImageService();
  final TextEditingController _messageController = TextEditingController();
  String? _chatRoomId;
  bool _isSending = false;
  bool _isUploadingImage = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initChat();
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _initChat() async {
    try {
      final chatRoomId = await _chatService.createChatRoom(
        widget.currentUser.uid,
        widget.otherUser.uid,
      );
      if (mounted) {
        setState(() {
          _chatRoomId = chatRoomId;
        });
      }
      // Mark messages as read
      await _chatService.markAsRead(chatRoomId, widget.currentUser.uid);
    } catch (e) {
      print('ERROR initializing chat: $e');
      if (mounted) {
        // Still set chat room ID to show UI even if mark as read fails
        final chatRoomId = _chatService.getChatRoomId(
          widget.currentUser.uid,
          widget.otherUser.uid,
        );
        setState(() {
          _chatRoomId = chatRoomId;
        });
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat initialization warning: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _clearTypingStatus();
    super.dispose();
  }

  void _onTextChanged() {
    if (_chatRoomId == null) return;

    final hasText = _messageController.text.trim().isNotEmpty;

    // Set typing status if user is typing
    if (hasText && !_isTyping) {
      _isTyping = true;
      _setTypingStatus(true);
    }

    // Cancel existing timer
    _typingTimer?.cancel();

    // Set timer to clear typing status after 3 seconds of no typing
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _isTyping = false;
          _setTypingStatus(false);
        }
      });
    } else {
      // Clear typing immediately if text is deleted
      _isTyping = false;
      _setTypingStatus(false);
    }
  }

  void _setTypingStatus(bool isTyping) {
    if (_chatRoomId == null) return;
    _chatService.setTypingStatus(
      chatRoomId: _chatRoomId!,
      userId: widget.currentUser.uid,
      isTyping: isTyping,
    );
  }

  void _clearTypingStatus() {
    if (_chatRoomId != null) {
      _chatService.setTypingStatus(
        chatRoomId: _chatRoomId!,
        userId: widget.currentUser.uid,
        isTyping: false,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatRoomId == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Clear typing status when sending message
    _isTyping = false;
    _typingTimer?.cancel();
    _clearTypingStatus();

    setState(() => _isSending = true);

    // Haptic feedback when tapping send
    HapticFeedbackUtil.mediumImpact();

    try {
      await _chatService.sendMessage(
        chatRoomId: _chatRoomId!,
        senderId: widget.currentUser.uid,
        receiverId: widget.otherUser.uid,
        message: message,
      );
      // Success haptic feedback
      HapticFeedbackUtil.success();
    } catch (e) {
      // Error haptic feedback
      HapticFeedbackUtil.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  /// Shows image source selection dialog (camera or gallery)
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Send Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick image from specified source and send as message
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_chatRoomId == null) return;

    setState(() => _isUploadingImage = true);

    try {
      // Pick image
      XFile? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await _imageService.pickImageFromCamera();
      } else {
        imageFile = await _imageService.pickImageFromGallery();
      }

      if (imageFile == null) {
        // User cancelled
        setState(() => _isUploadingImage = false);
        return;
      }

      // Upload to Supabase
      final imageUrl = await _imageService.uploadChatImage(
        imageFile,
        widget.currentUser.uid,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Send message with image URL
      await _chatService.sendMessage(
        chatRoomId: _chatRoomId!,
        senderId: widget.currentUser.uid,
        receiverId: widget.otherUser.uid,
        message: '[Image]', // Placeholder text
        imageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sent successfully'),
            backgroundColor: AppTheme.teal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: ${e.toString()}'),
            backgroundColor: AppTheme.coral,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportedUser: widget.otherUser,
        reporterUserId: widget.currentUser.uid,
      ),
    );
  }

  void _showImageGallery() {
    // Collect all available photos
    List<String> allPhotos = [];

    // Add main photo if available
    if (widget.otherUser.photoUrl != null) {
      allPhotos.add(widget.otherUser.photoUrl!);
    }

    // Add additional photos from gallery
    allPhotos.addAll(widget.otherUser.photos);

    // Remove duplicates (in case photoUrl is also in photos list)
    allPhotos = allPhotos.toSet().toList();

    if (allPhotos.isEmpty) {
      // No photos available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No photos available'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryViewer(
          imageUrls: allPhotos,
          initialIndex: 0,
          userName: widget.otherUser.name,
        ),
      ),
    );
  }

  void _showUserProfile() {
    // Record profile view
    ProfileViewService().recordProfileView(
      viewerId: widget.currentUser.uid,
      viewedUserId: widget.otherUser.uid,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserProfileSheet(
        user: widget.otherUser,
        currentUser: widget.currentUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: _showImageGallery,
              child: Hero(
                tag: 'chat_avatar_${widget.otherUser.uid}',
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: widget.otherUser.photoUrl != null
                      ? CachedNetworkImageProvider(widget.otherUser.photoUrl!)
                      : null,
                  child: widget.otherUser.photoUrl == null
                      ? Text(
                          widget.otherUser.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryRose,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _showUserProfile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUser.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (widget.otherUser.city != null)
                      Text(
                        widget.otherUser.city!,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: AppTheme.coral),
                    const SizedBox(width: 8),
                    Text(localizations.reportUser),
                  ],
                ),
                onTap: () {
                  Future.delayed(
                    const Duration(milliseconds: 100),
                    _showReportDialog,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: _chatRoomId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getRecentMessages(
                _chatRoomId!,
                limit: 50,
                userId: widget.currentUser.uid,
                userPrivateKey: null, // TODO: Pass private key when encryption is fully enabled
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say hi to start the conversation!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUser.uid;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          // Typing indicator
          StreamBuilder<bool>(
            stream: _chatService.getTypingStatus(
              chatRoomId: _chatRoomId!,
              otherUserId: widget.otherUser.uid,
            ),
            builder: (context, snapshot) {
              final isTyping = snapshot.data ?? false;

              if (!isTyping) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.otherUser.name} is typing',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildMessageInput(localizations),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image picker button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor, width: 1.5),
              ),
              child: IconButton(
                icon: _isUploadingImage
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.primaryRose),
                        ),
                      )
                    : const Icon(Icons.image, color: AppTheme.primaryRose),
                onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                tooltip: 'Send Image',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: localizations.sendMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // Determine bubble decoration based on read status
    BoxDecoration getBubbleDecoration() {
      if (isMe) {
        // For sent messages, show different colors based on read status
        if (message.isRead) {
          // Message has been read - show full gradient
          return BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: const Radius.circular(4),
            ),
          );
        } else {
          // Message not yet read - show faded/gray version
          return BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: const Radius.circular(4),
            ),
          );
        }
      } else {
        // Received messages - always use background color
        return BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryRose,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Message bubble (text or image)
                if (message.imageUrl != null)
                  // Image message
                  GestureDetector(
                    onTap: () {
                      // Open image in fullscreen gallery
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageGalleryViewer(
                            imageUrls: [message.imageUrl!],
                            initialIndex: 0,
                            userName: '', // Could be sender name
                          ),
                        ),
                      );
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                        maxHeight: 300,
                      ),
                      decoration: getBubbleDecoration(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomRight: isMe
                              ? const Radius.circular(4)
                              : const Radius.circular(20),
                          bottomLeft: !isMe
                              ? const Radius.circular(4)
                              : const Radius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: message.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: AppTheme.backgroundColor,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryRose,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: AppTheme.backgroundColor,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: AppTheme.textSecondary,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Fullscreen icon overlay
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Text message
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: getBubbleDecoration(),
                    child: Text(
                      message.displayMessage,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                // Timestamp and read status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeago.format(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? AppTheme.primaryRose
                            : AppTheme.textSecondary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.coral,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

// User Profile Sheet Widget
class _UserProfileSheet extends StatelessWidget {
  final UserModel user;
  final UserModel currentUser;

  const _UserProfileSheet({
    required this.user,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture with gradient border
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Show image gallery when tapping on profile picture
                        _showImageGallery(context);
                      },
                      child: Hero(
                        tag: 'user_profile_${user.uid}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.sunsetGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryRose.withValues(alpha: 0.4),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: AppTheme.primaryRose,
                              backgroundImage: user.photoUrl != null
                                  ? CachedNetworkImageProvider(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? Text(
                                      user.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 56,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Name and age with badge
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryRose.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '${user.age}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Location with icon
                  if (user.city != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.lavender,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppTheme.deepPurple,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.city!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Bio section with card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.loveGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localizations.bio,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.bio,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Interests section with card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.purpleGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localizations.interests,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (user.interests.isEmpty)
                          Text(
                            'No interests added yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: user.interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.lavender,
                                      AppTheme.lavender.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.royalPurple.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  interest,
                                  style: const TextStyle(
                                    color: AppTheme.deepPurple,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageGallery(BuildContext context) {
    // Collect all available photos
    List<String> allPhotos = [];

    // Add main photo if available
    if (user.photoUrl != null) {
      allPhotos.add(user.photoUrl!);
    }

    // Add additional photos from gallery
    allPhotos.addAll(user.photos);

    // Remove duplicates
    allPhotos = allPhotos.toSet().toList();

    if (allPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No photos available'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryViewer(
          imageUrls: allPhotos,
          initialIndex: 0,
          userName: user.name,
        ),
      ),
    );
  }
}
