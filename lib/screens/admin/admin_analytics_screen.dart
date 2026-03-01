import 'package:flutter/material.dart';
import '../../services/analytics_service.dart';

/// Admin Analytics Dashboard
/// Route: /admin (protected by email check)
/// Heimdal aesthetic — dark mode, neon green data viz, card-based layout
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  // ─── COLORS ───────────────────────────────────────────────
  static const voidBlack = Color(0xFF000000);
  static const deepCharcoal = Color(0xFF121212);
  static const neonGreen = Color(0xFF39FF14);
  static const ironGrey = Color(0xFF2C2C2C);
  static const pureWhite = Color(0xFFFFFFFF);
  static const dimWhite = Color(0x99FFFFFF); // 60% opacity

  // ─── STATE ────────────────────────────────────────────────
  bool _isLoading = true;
  int _selectedTab = 0; // 0=Overview, 1=Users, 2=Funnel, 3=Live Feed

  // Data
  List<Map<String, dynamic>> _dauData = [];
  List<Map<String, dynamic>> _featureUsage = [];
  Map<String, int> _inviteFunnel = {};
  List<Map<String, dynamic>> _betaUsers = [];
  List<Map<String, dynamic>> _recentEvents = [];
  List<Map<String, dynamic>> _topCharacters = [];
  double _avgSessionDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AnalyticsService.getDailyActiveUsers(days: 14),
        AnalyticsService.getFeatureUsage(days: 7),
        AnalyticsService.getInviteFunnel(days: 30),
        AnalyticsService.getActiveBetaUsers(),
        AnalyticsService.getRecentEvents(limit: 50),
        AnalyticsService.getTopCharacters(days: 7),
        AnalyticsService.getAvgSessionDuration(days: 7),
      ]);

      setState(() {
        _dauData = results[0] as List<Map<String, dynamic>>;
        _featureUsage = results[1] as List<Map<String, dynamic>>;
        _inviteFunnel = results[2] as Map<String, int>;
        _betaUsers = results[3] as List<Map<String, dynamic>>;
        _recentEvents = results[4] as List<Map<String, dynamic>>;
        _topCharacters = results[5] as List<Map<String, dynamic>>;
        _avgSessionDuration = results[6] as double;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ Admin data load failed: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: voidBlack,
      appBar: AppBar(
        backgroundColor: voidBlack,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: pureWhite),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, color: neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              'OGA COMMAND CENTER',
              style: TextStyle(
                color: pureWhite,
                fontSize: isMobile ? 14 : 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: neonGreen),
            onPressed: _loadAllData,
            tooltip: 'Refresh data',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ironGrey),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : Column(
              children: [
                // Tab bar
                _buildTabBar(isMobile),
                Container(height: 1, color: ironGrey),
                // Content
                Expanded(child: _buildTabContent(isMobile)),
              ],
            ),
    );
  }

  // ─── TAB BAR ──────────────────────────────────────────────

  Widget _buildTabBar(bool isMobile) {
    final tabs = ['OVERVIEW', 'USERS', 'FUNNEL', 'LIVE FEED'];
    return Container(
      color: voidBlack,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final isActive = entry.key == _selectedTab;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = entry.key),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? neonGreen.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? neonGreen : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isActive ? neonGreen : dimWhite,
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(bool isMobile) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(isMobile);
      case 1:
        return _buildUsersTab(isMobile);
      case 2:
        return _buildFunnelTab(isMobile);
      case 3:
        return _buildLiveFeedTab(isMobile);
      default:
        return _buildOverviewTab(isMobile);
    }
  }

  // ─── OVERVIEW TAB ─────────────────────────────────────────

  Widget _buildOverviewTab(bool isMobile) {
    // Calculate summary stats
    final todayDAU = _dauData.isNotEmpty ? _dauData.last['user_count'] ?? 0 : 0;
    final totalBetaUsers = _betaUsers.length;
    final totalInvites = _inviteFunnel.values.fold(0, (sum, v) => sum + v);
    final avgDuration = _avgSessionDuration;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards Row
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildKpiCard('DAU', '$todayDAU', 'Today')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        'BETA USERS',
                        '$totalBetaUsers',
                        'Active',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        'AVG SESSION',
                        '${avgDuration.toStringAsFixed(0)}s',
                        'Last 7 days',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        'INVITE EVENTS',
                        '$totalInvites',
                        'Last 30 days',
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildKpiCard('DAU', '$todayDAU', 'Today')),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'BETA USERS',
                    '$totalBetaUsers',
                    'Active',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'AVG SESSION',
                    '${avgDuration.toStringAsFixed(0)}s',
                    'Last 7 days',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'INVITE EVENTS',
                    '$totalInvites',
                    'Last 30 days',
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // DAU Chart
          _buildCard('DAILY ACTIVE USERS', 'Last 14 days', _buildDauChart()),

          const SizedBox(height: 16),

          // Two-column layout for desktop
          if (isMobile) ...[
            _buildCard('TOP FEATURES', 'Last 7 days', _buildFeatureList()),
            const SizedBox(height: 16),
            _buildCard(
              'TOP CHARACTERS',
              'Last 7 days',
              _buildTopCharactersList(),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCard(
                    'TOP FEATURES',
                    'Last 7 days',
                    _buildFeatureList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    'TOP CHARACTERS',
                    'Last 7 days',
                    _buildTopCharactersList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── USERS TAB ────────────────────────────────────────────

  Widget _buildUsersTab(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildCard(
        'ACTIVE BETA USERS',
        '${_betaUsers.length} users',
        Column(
          children: _betaUsers.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No beta users yet',
                      style: TextStyle(color: dimWhite),
                    ),
                  ),
                ]
              : _betaUsers.map((user) {
                  final email = user['email'] ?? 'unknown';
                  final notes = user['notes'] ?? '';
                  final granted = _formatDate(user['granted_at']);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: ironGrey, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar circle
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: neonGreen.withValues(alpha: 0.15),
                            border: Border.all(
                              color: neonGreen.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              email[0].toUpperCase(),
                              style: const TextStyle(
                                color: neonGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: const TextStyle(
                                  color: pureWhite,
                                  fontSize: 14,
                                ),
                              ),
                              if (notes.isNotEmpty)
                                Text(
                                  notes,
                                  style: TextStyle(
                                    color: dimWhite,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Date
                        Text(
                          granted,
                          style: TextStyle(color: dimWhite, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }

  // ─── FUNNEL TAB ───────────────────────────────────────────

  Widget _buildFunnelTab(bool isMobile) {
    final funnelSteps = [
      'link_opened',
      'signup_started',
      'signup_completed',
      'conversion',
    ];
    final funnelLabels = {
      'link_opened': 'LINK OPENED',
      'signup_started': 'SIGNUP STARTED',
      'signup_completed': 'SIGNUP COMPLETED',
      'conversion': 'CONVERSION',
    };

    // Get max value for bar scaling
    final maxVal = _inviteFunnel.values.isEmpty
        ? 1
        : _inviteFunnel.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildCard(
        'INVITE FUNNEL',
        'Last 30 days',
        Column(
          children: funnelSteps.map((step) {
            final count = _inviteFunnel[step] ?? 0;
            final ratio = maxVal > 0 ? count / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        funnelLabels[step] ?? step.toUpperCase(),
                        style: const TextStyle(
                          color: pureWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: neonGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: ironGrey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        neonGreen,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── LIVE FEED TAB ────────────────────────────────────────

  Widget _buildLiveFeedTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: neonGreen,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RECENT EVENTS',
                style: TextStyle(
                  color: pureWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_recentEvents.length} events',
                style: TextStyle(color: dimWhite, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(height: 1, color: ironGrey),
        Expanded(
          child: _recentEvents.isEmpty
              ? Center(
                  child: Text(
                    'No events yet',
                    style: TextStyle(color: dimWhite),
                  ),
                )
              : ListView.builder(
                  itemCount: _recentEvents.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) {
                    final event = _recentEvents[index];
                    return _buildEventRow(event, isMobile);
                  },
                ),
        ),
      ],
    );
  }

  // ─── WIDGET BUILDERS ──────────────────────────────────────

  Widget _buildKpiCard(String label, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ironGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: dimWhite,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: neonGreen,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: dimWhite, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: deepCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ironGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: pureWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(subtitle, style: TextStyle(color: dimWhite, fontSize: 11)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 1,
            color: ironGrey,
          ),
          // Content
          content,
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Simple bar chart for DAU — pure Flutter, no packages needed
  Widget _buildDauChart() {
    if (_dauData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No data yet', style: TextStyle(color: dimWhite)),
        ),
      );
    }

    final maxCount = _dauData
        .map((d) => (d['user_count'] as num?) ?? 0)
        .reduce((a, b) => a > b ? a : b);
    final chartMax = maxCount == 0 ? 1 : maxCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _dauData.map((d) {
            final count = (d['user_count'] as num?) ?? 0;
            final ratio = count / chartMax;
            final dayStr = (d['day'] ?? '').toString();
            final dayLabel = dayStr.length >= 10
                ? dayStr.substring(5, 10)
                : dayStr; // MM-DD

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Count label
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Bar
                    Container(
                      height: 120 * ratio,
                      constraints: const BoxConstraints(minHeight: 2),
                      decoration: BoxDecoration(
                        color: neonGreen,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: neonGreen.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date label
                    Text(
                      dayLabel,
                      style: TextStyle(color: dimWhite, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    if (_featureUsage.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No feature data yet', style: TextStyle(color: dimWhite)),
      );
    }

    final maxCount = _featureUsage
        .map((d) => (d['use_count'] as num?) ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: _featureUsage.take(8).map((f) {
        final feature = (f['feature'] ?? 'unknown') as String;
        final count = (f['use_count'] as num?) ?? 0;
        final ratio = maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  _formatFeatureName(feature),
                  style: const TextStyle(color: pureWhite, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: ironGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(neonGreen),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCharactersList() {
    if (_topCharacters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No character data yet', style: TextStyle(color: dimWhite)),
      );
    }

    return Column(
      children: _topCharacters.take(5).map((c) {
        final id = (c['character_id'] ?? 'unknown') as String;
        final count = (c['view_count'] as num?) ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Character icon placeholder
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: neonGreen.withValues(alpha: 0.1),
                  border: Border.all(color: neonGreen.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    id[0].toUpperCase(),
                    style: const TextStyle(
                      color: neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  id.toUpperCase(),
                  style: const TextStyle(
                    color: pureWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '$count views',
                style: const TextStyle(
                  color: neonGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEventRow(Map<String, dynamic> event, bool isMobile) {
    final email = (event['user_email'] ?? '') as String;
    final type = (event['event_type'] ?? '') as String;
    final data = event['event_data'] as Map<String, dynamic>? ?? {};
    final page = (event['page_context'] ?? '') as String;
    final time = _formatTime(event['created_at']);

    final icon = _getEventIcon(type);
    final color = _getEventColor(type);
    final detail = _getEventDetail(type, data);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ironGrey.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _truncateEmail(email),
                      style: const TextStyle(
                        color: pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatEventType(type),
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail.isNotEmpty)
                  Text(detail, style: TextStyle(color: dimWhite, fontSize: 11)),
              ],
            ),
          ),
          // Time
          Text(time, style: TextStyle(color: dimWhite, fontSize: 10)),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────

  String _formatFeatureName(String feature) {
    return feature
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  String _truncateEmail(String email) {
    if (email.length <= 20) return email;
    final parts = email.split('@');
    if (parts.length == 2) {
      final name = parts[0].length > 10
          ? '${parts[0].substring(0, 10)}…'
          : parts[0];
      return '$name@${parts[1]}';
    }
    return email.substring(0, 20);
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'session_start':
        return Icons.login;
      case 'session_end':
        return Icons.logout;
      case 'page_view':
        return Icons.visibility;
      case 'feature_use':
        return Icons.touch_app;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.circle;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'session_start':
        return neonGreen;
      case 'session_end':
        return dimWhite;
      case 'page_view':
        return const Color(0xFF4FC3F7); // Light blue
      case 'feature_use':
        return neonGreen;
      case 'error':
        return const Color(0xFFFF5252); // Red
      default:
        return dimWhite;
    }
  }

  String _formatEventType(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }

  String _getEventDetail(String type, Map<String, dynamic> data) {
    if (type == 'feature_use') {
      final feature = data['feature'] ?? '';
      final charId = data['character_id'] ?? '';
      if (charId.isNotEmpty) return '$feature → $charId';
      return feature.toString();
    }
    if (type == 'page_view') return '';
    if (type == 'session_end') {
      final dur = data['duration_seconds'];
      if (dur != null) return 'Duration: ${dur}s';
    }
    if (type == 'error') return data['error']?.toString() ?? '';
    return '';
  }
}
