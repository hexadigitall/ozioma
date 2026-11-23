import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme_provider.dart';

class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isSunlightDark = themeMode == AppThemeMode.sunlightDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Resources'),
        actions: [
          IconButton(
            icon: Icon(isSunlightDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Sunlight Mode',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(themeProvider.notifier).toggleSunlightMode();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sunlight Mode Banner
          Card(
            color: isSunlightDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.wb_sunny,
                    color: isSunlightDark ? const Color(0xFFFFD600) : const Color(0xFF2563EB),
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSunlightDark ? 'Sunlight Ultra-Contrast (Active)' : 'Standard Contrast',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'OLED black with 700-nit yellow accents for direct midday sunlight reading.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isSunlightDark,
                    onChanged: (_) {
                      HapticFeedback.lightImpact();
                      ref.read(themeProvider.notifier).toggleSunlightMode();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sample Presentations Section
          const Text(
            'Sample Presentations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildPresentationCard(
            context,
            title: 'Initial Call — Why Does God Allow Suffering?',
            scripture: 'James 1:13',
            scriptureText: 'When under trial, let no one say: "I am being tried by God." For with evil things God cannot be tried, nor does he himself try anyone.',
            question: 'If God does not cause suffering, why is the world so full of hardship?',
            nextTopic: 'Next visit: Revelation 21:3, 4',
          ),
          const SizedBox(height: 12),

          _buildPresentationCard(
            context,
            title: 'Return Visit — What Is God\'s Purpose for Earth?',
            scripture: 'Psalm 37:10, 11',
            scriptureText: 'Just a little while longer, and the wicked will be no more... But the meek will possess the earth, and they will find exquisite delight in the abundance of peace.',
            question: 'What kind of life can we look forward to on paradise earth?',
            nextTopic: 'Bible Study offer: Enjoy Life Forever!',
          ),
          const SizedBox(height: 12),

          _buildPresentationCard(
            context,
            title: 'Starting Bible Studies — Enjoy Life Forever!',
            scripture: 'John 17:3',
            scriptureText: 'This means everlasting life, their coming to know you, the only true God, and the one whom you sent, Jesus Christ.',
            question: 'How can studying the Bible help you and your family right now?',
            nextTopic: 'Lesson 01: How Can the Bible Help You?',
          ),
          const SizedBox(height: 20),

          // Security & Encryption Status
          const Text(
            'Security & Hardware Privacy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: Color(0xFF00E676), size: 22),
                      SizedBox(width: 8),
                      Text('Zero-Cloud PII Architecture', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All resident names, contact details, and personal visit notes are encrypted locally via AES-256-GCM backed by hardware Keystore. No householder notes are transmitted to cloud servers.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationCard(
    BuildContext context, {
    required String title,
    required String scripture,
    required String scriptureText,
    required String question,
    required String nextTopic,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scripture,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"$scriptureText"',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Question: $question', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(nextTopic, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
