import 'package:flutter/material.dart';
import '../../services/custom_notification_sound_service.dart';

/// Notification sound picker screen
///
/// Allows users to choose their preferred notification sound
class NotificationSoundPicker extends StatefulWidget {
  const NotificationSoundPicker({super.key});

  @override
  State<NotificationSoundPicker> createState() => _NotificationSoundPickerState();
}

class _NotificationSoundPickerState extends State<NotificationSoundPicker> {
  final CustomNotificationSoundService _soundService = CustomNotificationSoundService();
  String _currentSound = 'purr';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSound();
  }

  Future<void> _loadCurrentSound() async {
    final sound = await _soundService.getCurrentSound();
    setState(() {
      _currentSound = sound;
      _isLoading = false;
    });
  }

  Future<void> _selectSound(String soundName) async {
    // Play preview first
    await _soundService.previewSound(soundName);

    // Wait a bit before saving so user can hear the sound
    await Future.delayed(const Duration(milliseconds: 500));

    // Save selection
    await _soundService.setNotificationSound(soundName);

    setState(() {
      _currentSound = soundName;
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification sound set to ${CustomNotificationSoundService.availableSounds[soundName]}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Sound'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final sounds = CustomNotificationSoundService.getAllSounds();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Sound'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to default',
            onPressed: () async {
              await _soundService.resetToDefault();
              _loadCurrentSound();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: sounds.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final sound = sounds[index];
          final soundId = sound['id']!;
          final soundName = sound['name']!;
          final soundDescription = sound['description']!;
          final isSelected = soundId == _currentSound;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _selectSound(soundId),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Sound icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSoundIcon(soundId),
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Sound info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            soundName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            soundDescription,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Selection indicator
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Preview sound',
                        onPressed: () => _soundService.previewSound(soundId),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getSoundIcon(String soundId) {
    switch (soundId) {
      case 'meow':
        return Icons.pets;
      case 'purr':
        return Icons.favorite;
      case 'kiss':
        return Icons.favorite_border;
      case 'whisper':
        return Icons.record_voice_over;
      case 'chime':
        return Icons.music_note;
      case 'heartbeat':
        return Icons.favorite_border;
      default:
        return Icons.notifications;
    }
  }
}
