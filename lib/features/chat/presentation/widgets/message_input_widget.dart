import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:chatz/core/themes/app_colors.dart';
import 'package:chatz/core/themes/app_text_styles.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';

/// Message input widget with text, attachments, and voice recording
class MessageInputWidget extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(File file, MessageType type) onSendMedia;
  final Function(File audioFile, int duration) onSendVoice;
  final ReplyMetadata? replyTo;
  final VoidCallback? onCancelReply;
  final VoidCallback? onTyping;

  const MessageInputWidget({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    required this.onSendVoice,
    this.replyTo,
    this.onCancelReply,
    this.onTyping,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _showEmojiPicker = false;
  DateTime? _recordingStartTime;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onTyping?.call();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply preview
        if (widget.replyTo != null) _buildReplyPreview(theme),

        // Input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Expanded text field with emoji and attachment buttons
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.receiverBubbleDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // Emoji button
                        IconButton(
                          icon: Icon(
                            _showEmojiPicker
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                            color: AppColors.iconLight,
                          ),
                          onPressed: _toggleEmojiPicker,
                        ),

                        // Text field
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Message',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 10,
                              ),
                            ),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),

                        // Attachment button
                        IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: AppColors.iconLight,
                          ),
                          onPressed: _showAttachmentOptions,
                        ),

                        // Camera button
                        IconButton(
                          icon: Icon(
                            Icons.camera_alt,
                            color: AppColors.iconLight,
                          ),
                          onPressed: _capturePhoto,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Voice/Send button
                if (_isRecording)
                  _buildRecordingControls()
                else
                  _buildSendButton(),
              ],
            ),
          ),
        ),

        // Emoji picker
        if (_showEmojiPicker) _buildEmojiPicker(),
      ],
    );
  }

  Widget _buildReplyPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? AppColors.dividerDark
                : AppColors.dividerLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.replyTo!.senderName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyTo!.content,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onCancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _textController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasText ? _sendTextMessage : null,
      onLongPress: hasText ? null : _startRecording,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          hasText ? Icons.send : Icons.mic,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Row(
      children: [
        // Cancel button
        IconButton(
          icon: const Icon(Icons.delete, color: AppColors.error),
          onPressed: _cancelRecording,
        ),
        const SizedBox(width: 8),
        // Recording indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getRecordingDuration(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Send button
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 300,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _textController.text += emoji.emoji;
        },
        config: Config(
          height: 300,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: const CategoryViewConfig(),
          bottomActionBarConfig: const BottomActionBarConfig(
            enabled: false,
          ),
        ),
      ),
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      _textController.clear();
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showPermissionDeniedDialog('Microphone');
      return;
    }

    try {
      final path = '${Directory.systemTemp.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _recordingPath = path;
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _showErrorSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();

      if (_recordingPath != null) {
        final duration = DateTime.now().difference(_recordingStartTime!).inSeconds;
        widget.onSendVoice(File(_recordingPath!), duration);
      }

      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
        _recordingPath = null;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _showErrorSnackBar('Failed to send voice message');
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();

      // Delete the recording file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
        _recordingPath = null;
      });
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  String _getRecordingDuration() {
    if (_recordingStartTime == null) return '0:00';

    final duration = DateTime.now().difference(_recordingStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _AttachmentOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              _AttachmentOption(
                icon: Icons.videocam,
                label: 'Video',
                color: AppColors.videoCall,
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              _AttachmentOption(
                icon: Icons.insert_drive_file,
                label: 'Document',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showPermissionDeniedDialog('Camera');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        widget.onSendMedia(File(image.path), MessageType.image);
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      _showErrorSnackBar('Failed to capture photo');
    }
  }

  Future<void> _pickFromGallery() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      _showPermissionDeniedDialog('Photos');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        widget.onSendMedia(File(image.path), MessageType.image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        widget.onSendMedia(File(video.path), MessageType.video);
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      _showErrorSnackBar('Failed to pick video');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        widget.onSendMedia(file, MessageType.file);
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      _showErrorSnackBar('Failed to pick document');
    }
  }

  void _showPermissionDeniedDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          'Please enable $permission permission in settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// Attachment option widget for bottom sheet
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
