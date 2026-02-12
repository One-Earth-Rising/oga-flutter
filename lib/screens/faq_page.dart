import 'package:flutter/material.dart';

/// Standalone FAQ page matching Figma design.
/// Sections: General, For Gamers, For Developers & Brands, Technology.
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  // Track which FAQ is expanded: "section-index"
  String? _expandedId;

  // FAQ Data
  static const _sections = [
    _FaqSection(
      title: null,
      items: [
        _FaqItem(
          question: 'What is the OGA Hub?',
          answer:
              'OGA Hub is a cross-game character platform that lets you own, '
              'trade, and play with unique characters across multiple supported '
              'titles. Each character retains its identity and progression, creating '
              'a persistent legacy that evolves across platforms.',
        ),
        _FaqItem(
          question: 'How is this different from other gaming platforms?',
          answer:
              'Unlike traditional platforms, OGA uses a patent-pending PNG '
              'container format that packages all game files for a character into '
              'a single ownable asset, ensuring true player ownership that persists '
              'even if game servers shut down.',
        ),
        _FaqItem(
          question:
              'Do I need special knowledge or experience with technology?',
          answer:
              'Not at all! OGA Hub is designed to be as simple as any gaming '
              'platform. Collect characters, play games, and trade with friends — '
              'the technology works seamlessly in the background.',
        ),
        _FaqItem(
          question: 'Is the OGA Hub available now?',
          answer:
              'OGA Hub is currently in early access. Sign up to be among the '
              'first to experience cross-game character ownership.',
        ),
      ],
    ),
    _FaqSection(
      title: 'FOR GAMERS',
      items: [
        _FaqItem(
          question: 'How do I get started with the OGA Hub?',
          answer:
              'Simply play games that are part of our ecosystem. When you '
              'unlock or purchase items in these games, they automatically become '
              'part of your personal collection in the OGA Hub.',
        ),
        _FaqItem(
          question: 'What can I do with my collection?',
          answer:
              'You can view, trade, and sell your characters. Each character '
              'can be used across multiple supported games, and your progress '
              'carries over between titles.',
        ),
        _FaqItem(
          question: 'Which games are currently supported?',
          answer:
              'We are partnering with major studios and indie developers. '
              'Check our supported games list for the latest titles in the ecosystem.',
        ),
        _FaqItem(
          question: 'Can I invite my friends?',
          answer:
              'Yes! You can invite friends through your profile and share '
              'your collection with them. Friends can view your characters and '
              'trade with you directly.',
        ),
        _FaqItem(
          question: 'What happens if a game shuts down?',
          answer:
              'Your characters are yours forever. Because OGA packages all '
              'game data into a single file you own, your characters persist even '
              'if a game server shuts down. This is the core promise of OGA.',
        ),
      ],
    ),
    _FaqSection(
      title: 'FOR DEVELOPERS & BRANDS',
      items: [
        _FaqItem(
          question: 'How do I get started with the OGA Hub?',
          answer:
              'Reach out to our partnerships team to discuss integration. '
              'We provide SDK tools and documentation to help you add OGA support '
              'to your game quickly.',
        ),
        _FaqItem(
          question: 'What can I do with my collection?',
          answer:
              'As a developer, you can license existing OGA characters for '
              'your game, create new characters, and participate in the cross-game '
              'ecosystem to drive player engagement.',
        ),
        _FaqItem(
          question: 'Which games are currently supported?',
          answer:
              'We work with studios across action RPGs, tactical shooters, '
              'battle royales, and more. Contact us to see how your game fits '
              'into the ecosystem.',
        ),
        _FaqItem(
          question: 'Can I invite my friends?',
          answer:
              'As a developer, you can invite your team members to the '
              'developer portal to manage your game\'s integration with OGA.',
        ),
        _FaqItem(
          question: 'What happens if a game shuts down?',
          answer:
              'Characters created for your game continue to exist in the OGA '
              'ecosystem. Players retain ownership, and the character can still be '
              'used in other supported titles.',
        ),
      ],
    ),
    _FaqSection(
      title: 'TECHNOLOGY',
      items: [
        _FaqItem(
          question: 'How does the technology work?',
          answer:
              'OGA uses a patent-pending PNG container format that embeds '
              'all game engine files (3D models, textures, animations, metadata) '
              'into a single image file. This makes characters truly portable '
              'and ownable.',
        ),
        _FaqItem(
          question: 'Is this secure?',
          answer:
              'Yes. Each OGA container is cryptographically signed and '
              'verified through our platform. Ownership is tracked securely '
              'and cannot be duplicated or forged.',
        ),
        _FaqItem(
          question: 'What platforms are supported?',
          answer:
              'OGA currently supports PC, PlayStation, Xbox, and Nintendo '
              'platforms. Mobile support is on our roadmap.',
        ),
        _FaqItem(
          question: 'What\'s coming next?',
          answer:
              'We\'re building The Portal — an AI-powered system for '
              'automated character conversion between games. This will make '
              'cross-game character transfer instant and seamless.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: voidBlack,
      appBar: AppBar(
        backgroundColor: voidBlack,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/logo.png',
          height: 24,
          errorBuilder: (_, __, ___) => const Text(
            'OGA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: 40,
              ),
              child: Column(
                children: [
                  // Title
                  const Text(
                    'MOST COMMON\nQUESTIONS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Sections
                  ..._sections.asMap().entries.map(
                    (entry) => _buildSection(entry.key, entry.value),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(int sectionIndex, _FaqSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          const SizedBox(height: 48),
          Text(
            section.title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
        ],
        ...section.items.asMap().entries.map(
          (entry) => _buildFaqItem(
            '$sectionIndex-${entry.key}',
            entry.value,
            isFirst: sectionIndex == 0 && entry.key == 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String id, _FaqItem item, {bool isFirst = false}) {
    final isExpanded = _expandedId == id;
    // First item in the general section gets the green highlight
    final isHighlighted = isFirst && !isExpanded;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedId = isExpanded ? null : id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isHighlighted
              ? neonGreen
              : isExpanded
              ? deepCharcoal
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlighted
                ? neonGreen
                : isExpanded
                ? ironGrey
                : ironGrey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: TextStyle(
                        color: isHighlighted ? Colors.black : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.add,
                    color: isHighlighted ? Colors.black54 : Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Text(
                  item.answer,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqSection {
  final String? title;
  final List<_FaqItem> items;
  const _FaqSection({required this.title, required this.items});
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
