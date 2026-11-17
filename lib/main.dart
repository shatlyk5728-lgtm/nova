import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sing_box/flutter_sing_box.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://joebcmwluizjqrbatpfs.supabase.co',
    anonKey: 'sb_publishable_jEd50a0qw2_J17qEVYiLxg_0Mfj68LX',
  );

  await FlutterSingBox().init();

  runApp(const NovaApp());
}

// ============================================================
// NOVA VPN — PREMIUM EDITION
// Platforms: Windows + Android
// Languages: Russian + English
// ============================================================
class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080B16),
        fontFamily: 'Segoe UI',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6575FF),
          secondary: Color(0xFF9B72FF),
          surface: Color(0xFF151A2B),
        ),
        useMaterial3: true,
      ),
      home: const NovaHome(),
    );
  }
}

// ============================================================
// COLORS
// ============================================================

class NovaColors {
  static const background = Color(0xFF080B16);
  static const panel = Color(0xFF111729);
  static const panelLight = Color(0xFF192139);
  static const border = Color(0xFF252E49);
  static const blue = Color(0xFF6575FF);
  static const purple = Color(0xFF9B72FF);
  static const cyan = Color(0xFF45D7F5);
  static const green = Color(0xFF35D6A0);
  static const muted = Color(0xFF8993AD);
  static const white = Color(0xFFF4F6FF);
}

// ============================================================
// SERVER MODEL
// ============================================================

class NovaServer {
  final String id;
  final String name;
  final String country;
  final String flag;
  final int ping;
  final String city;
  final String protocol;
  final String configText;

  const NovaServer({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.ping,
    required this.city,
    required this.protocol,
    required this.configText,
  });

  factory NovaServer.fromJson(Map<String, dynamic> json) {
    return NovaServer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Nova server').toString(),
      country: (json['country'] ?? '').toString(),
      flag: (json['flag'] ?? '🌐').toString(),
      ping: 0, // Задержка пока не измеряется.
      city: (json['name'] ?? 'Nova server').toString(),
      protocol: (json['protocol'] ?? '').toString(),
      configText: (json['config_text'] ?? '').toString(),
    );
  }
}

// ============================================================
// MAIN APP
// ============================================================

class NovaHome extends StatefulWidget {
  const NovaHome({super.key});

  @override
  State<NovaHome> createState() => _NovaHomeState();
}

class _NovaHomeState extends State<NovaHome> {
  int selectedPage = 0;
  int selectedServer = 0;

  bool isConnected = false;
  bool isRussian = true;
  bool autoConnect = false;
  bool killSwitch = false;
  bool notifications = true;

  String searchQuery = '';

  List<NovaServer> servers = [];
  bool isLoadingServers = true;
  String? serverLoadError;

  @override
  void initState() {
    super.initState();
    loadServers();
  }

  Future<void> loadServers() async {
    if (mounted) {
      setState(() {
        isLoadingServers = true;
        serverLoadError = null;
      });
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'dynamic-service',
        method: HttpMethod.get,
      );

      final body = response.data;
      if (body is! Map || body['servers'] is! List) {
        throw Exception('Неверный ответ сервера');
      }

      final loaded = (body['servers'] as List)
          .whereType<Map>()
          .map((item) => NovaServer.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((server) => server.configText.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        servers = loaded;
        isLoadingServers = false;
        if (selectedServer >= servers.length) selectedServer = 0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoadingServers = false;
        serverLoadError = error.toString();
      });
    }
  }

  final NovaServer emptyServer = const NovaServer(
    id: '',
    name: 'No server',
    country: '',
    flag: '🌐',
    ping: 0,
    city: 'Нет серверов',
    protocol: '',
    configText: '',
  );

  String get language => isRussian ? 'ru' : 'en';

  String tr(String ru, String en) => isRussian ? ru : en;

  NovaServer get currentServer =>
      servers.isEmpty
          ? emptyServer
          : (selectedServer < servers.length ? servers[selectedServer] : servers.first);

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NovaColors.panelLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void toggleConnection() {
    showMessage(
      tr(
        'Список серверов загружен. Настоящее VPN-подключение ещё не настроено.',
        'Server list loaded. Real VPN connection is not configured yet.',
      ),
    );
  }

  void copyTelegram() {
    Clipboard.setData(
      const ClipboardData(text: '@artem_codess'),
    );
    showMessage(
      tr('Telegram username скопирован', 'Telegram username copied'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final desktop = width >= 850;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (desktop) _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(desktop),
                  Expanded(
                    child: _buildPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: desktop ? null : _buildBottomNavigation(),
    );
  }

  // ==========================================================
  // SIDEBAR
  // ==========================================================

  Widget _buildSidebar() {
    return Container(
      width: 245,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1222),
        border: Border(
          right: BorderSide(color: NovaColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _logo(),
          ),
          const SizedBox(height: 45),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              tr('ГЛАВНОЕ МЕНЮ', 'MAIN MENU'),
              style: const TextStyle(
                color: NovaColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 15),
          _navItem(0, Icons.grid_view_rounded, tr('Главная', 'Home')),
          _navItem(1, Icons.public_rounded, tr('Серверы', 'Servers')),
          _navItem(2, Icons.analytics_rounded, tr('Статистика', 'Statistics')),
          _navItem(3, Icons.settings_rounded, tr('Настройки', 'Settings')),
          const Spacer(),
          _telegramCard(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'NOVA VPN • v1.0.0',
              style: TextStyle(
                color: NovaColors.muted.withOpacity(0.65),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [NovaColors.blue, NovaColors.purple],
            ),
            boxShadow: [
              BoxShadow(
                color: NovaColors.blue.withOpacity(0.35),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOVA',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              'VPN NETWORK',
              style: TextStyle(
                fontSize: 9,
                color: NovaColors.muted,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _navItem(int index, IconData icon, String title) {
    final active = selectedPage == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => setState(() => selectedPage = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: active
                ? NovaColors.blue.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active
                  ? NovaColors.blue.withOpacity(0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? NovaColors.blue : NovaColors.muted,
              ),
              const SizedBox(width: 13),
              Text(
                title,
                style: TextStyle(
                  color: active ? Colors.white : NovaColors.muted,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telegramCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              NovaColors.blue.withOpacity(0.18),
              NovaColors.purple.withOpacity(0.12),
            ],
          ),
          border: Border.all(color: NovaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.telegram,
              color: NovaColors.cyan,
              size: 25,
            ),
            const SizedBox(height: 10),
            Text(
              tr('Есть вопросы?', 'Need help?'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '@artem_codess',
              style: TextStyle(
                color: NovaColors.cyan,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: copyTelegram,
              child: Text(
                tr('Скопировать контакт →', 'Copy contact →'),
                style: const TextStyle(
                  color: NovaColors.muted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildTopBar(bool desktop) {
    return Container(
      height: 75,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 35 : 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: NovaColors.border),
        ),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            _logo(),
          ] else ...[
            Text(
              _pageTitle(),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => isRussian = !isRussian);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: NovaColors.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NovaColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.language_rounded,
                    color: NovaColors.cyan,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isRussian ? 'RU' : 'EN',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: NovaColors.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NovaColors.border),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: NovaColors.muted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _pageTitle() {
    switch (selectedPage) {
      case 1:
        return tr('Серверы', 'Servers');
      case 2:
        return tr('Статистика', 'Statistics');
      case 3:
        return tr('Настройки', 'Settings');
      default:
        return tr('Главная', 'Home');
    }
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1222),
        border: Border(
          top: BorderSide(color: NovaColors.border),
        ),
      ),
      child: NavigationBar(
        height: 68,
        backgroundColor: const Color(0xFF0D1222),
        indicatorColor: NovaColors.blue.withOpacity(0.2),
        selectedIndex: selectedPage,
        onDestinationSelected: (index) {
          setState(() => selectedPage = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_rounded),
            label: tr('Главная', 'Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.public_rounded),
            label: tr('Серверы', 'Servers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_rounded),
            label: tr('Статистика', 'Stats'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: tr('Настройки', 'Settings'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PAGE ROUTER
  // ==========================================================

  Widget _buildPage() {
    switch (selectedPage) {
      case 1:
        return _serversPage();
      case 2:
        return _statisticsPage();
      case 3:
        return _settingsPage();
      default:
        return _homePage();
    }
  }

  Widget _pageContainer(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: child,
        ),
      ),
    );
  }

  // ==========================================================
  // HOME PAGE
  // ==========================================================

  Widget _homePage() {
    return _pageContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeSection(),
          const SizedBox(height: 25),
          _connectionCard(),
          const SizedBox(height: 20),
          _quickStats(),
          const SizedBox(height: 25),
          _selectedServerCard(),
          const SizedBox(height: 20),
          _homeTelegramCard(),
          const SizedBox(height: 20),
          _securityNotice(),
        ],
      ),
    );
  }

  Widget _welcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Добро пожаловать в Nova', 'Welcome to Nova'),
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: NovaColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr(
            'Твой интернет. Твои правила.',
            'Your internet. Your rules.',
          ),
          style: const TextStyle(
            color: NovaColors.muted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _connectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF202B59),
            Color(0xFF171D3A),
            Color(0xFF241A45),
          ],
        ),
        border: Border.all(
          color: NovaColors.blue.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: NovaColors.blue.withOpacity(0.10),
            blurRadius: 35,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? NovaColors.green : NovaColors.muted,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                isConnected
                    ? tr('ДЕМО-ПОДКЛЮЧЕНИЕ', 'DEMO CONNECTION')
                    : tr('НЕ ПОДКЛЮЧЕНО', 'NOT CONNECTED'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.shield_rounded,
                color: NovaColors.cyan,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: toggleConnection,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isConnected
                      ? [
                          NovaColors.green,
                          const Color(0xFF168C83),
                        ]
                      : [
                          NovaColors.blue,
                          NovaColors.purple,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isConnected
                            ? NovaColors.green
                            : NovaColors.blue)
                        .withOpacity(0.35),
                    blurRadius: 35,
                    spreadRadius: 7,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 5,
                ),
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                size: 66,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            isConnected
                ? tr('Демо активно', 'Demo active')
                : tr('Нажми для подключения', 'Tap to connect'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            tr(
              'Выбран сервер ${currentServer.city}',
              'Selected server ${currentServer.city}',
            ),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tr(
                'Демонстрационный режим',
                'Demonstration mode',
              ),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // QUICK STATS
  // ==========================================================

  Widget _quickStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;

        final items = [
          _statCard(
            Icons.speed_rounded,
            '18 ms',
            tr('Средний Ping', 'Average Ping'),
            NovaColors.cyan,
          ),
          _statCard(
            Icons.cloud_download_rounded,
            '0 MB',
            tr('Загрузка', 'Download'),
            NovaColors.green,
          ),
          _statCard(
            Icons.cloud_upload_rounded,
            '0 MB',
            tr('Отдача', 'Upload'),
            NovaColors.purple,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (final item in items) ...[
                item,
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(child: items[i]),
              if (i != items.length - 1)
                const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: NovaColors.panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: NovaColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: NovaColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SELECTED SERVER
  // ==========================================================

  Widget _selectedServerCard() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: NovaColors.panel,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: NovaColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                color: NovaColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                tr('Выбранный сервер', 'Selected server'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => selectedPage = 1),
                child: Text(tr('Изменить', 'Change')),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                currentServer.flag,
                style: const TextStyle(fontSize: 33),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentServer.city,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRussian
                          ? currentServer.country
                          : currentServer.name,
                      style: const TextStyle(
                        color: NovaColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _pingBadge(currentServer.ping),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pingBadge(int ping) {
    final color = ping < 50
        ? NovaColors.green
        : ping < 100
            ? Colors.orange
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        ping > 0 ? '$ping ms' : '—',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _homeTelegramCard() {
    return InkWell(
      onTap: copyTelegram,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: NovaColors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NovaColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.telegram,
              color: NovaColors.cyan,
              size: 34,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Связаться с нами', 'Contact us'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '@artem_codess',
                    style: TextStyle(
                      color: NovaColors.cyan,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.copy_rounded,
              color: NovaColors.muted,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              tr(
                'Важно: VPN-движок ещё не подключён. Кнопка подключения сейчас демонстрационная. Приложение пока не шифрует интернет-трафик.',
                'Important: The VPN engine is not connected yet. The connection button is currently a demo. This app does not encrypt internet traffic yet.',
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SERVERS PAGE
  // ==========================================================

  Widget _serversPage() {
    final filteredServers = servers.where((server) {
      final query = searchQuery.toLowerCase();
      return server.name.toLowerCase().contains(query) ||
          server.city.toLowerCase().contains(query) ||
          server.country.toLowerCase().contains(query);
    }).toList();

    return _pageContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Выбери локацию', 'Choose your location'),
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Серверы загружаются из Nova VPN',
              'Servers are loaded from Nova VPN',
            ),
            style: const TextStyle(
              color: NovaColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: (value) {
              setState(() => searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: tr('Поиск страны или города', 'Search country or city'),
              hintStyle: const TextStyle(
                color: NovaColors.muted,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: NovaColors.muted,
              ),
              filled: true,
              fillColor: NovaColors.panel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: NovaColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: NovaColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: NovaColors.blue),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                tr('ВСЕ СЕРВЕРЫ', 'ALL SERVERS'),
                style: const TextStyle(
                  color: NovaColors.muted,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${filteredServers.length} ${tr('локаций', 'locations')}',
                style: const TextStyle(
                  color: NovaColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: isLoadingServers ? null : loadServers,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(tr('Обновить список', 'Refresh list')),
            ),
          ),
          const SizedBox(height: 4),
          if (isLoadingServers)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!isLoadingServers && serverLoadError != null)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    tr('Не удалось загрузить серверы', 'Could not load servers'),
                    style: const TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: loadServers,
                    child: Text(tr('Повторить', 'Retry')),
                  ),
                ],
              ),
            ),
          if (!isLoadingServers && serverLoadError == null && filteredServers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Text(
                  tr('Ничего не найдено', 'Nothing found'),
                  style: const TextStyle(color: NovaColors.muted),
                ),
              ),
            ),
          for (final server in filteredServers)
            _serverTile(server),
          const SizedBox(height: 15),
          _securityNotice(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _serverTile(NovaServer server) {
    final index = servers.indexOf(server);
    final selected = selectedServer == index;

    return InkWell(
      onTap: () {
        setState(() => selectedServer = index);
        showMessage(
          tr('Выбран сервер: ${server.city}', 'Selected: ${server.city}'),
        );
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? NovaColors.blue.withOpacity(0.12)
              : NovaColors.panel,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? NovaColors.blue : NovaColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              server.flag,
              style: const TextStyle(fontSize: 31),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.city,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${isRussian ? server.country : server.name} • ${server.protocol}',
                    style: const TextStyle(
                      color: NovaColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _pingBadge(server.ping),
            const SizedBox(width: 12),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? NovaColors.blue : NovaColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // STATISTICS PAGE
  // ==========================================================

  Widget _statisticsPage() {
    return _pageContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Статистика', 'Statistics'),
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Информация о сетевой активности',
              'Network activity information',
            ),
            style: const TextStyle(
              color: NovaColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 25),
          _statisticsCard(
            Icons.cloud_download_rounded,
            tr('Получено данных', 'Data received'),
            '0 MB',
            NovaColors.cyan,
          ),
          _statisticsCard(
            Icons.cloud_upload_rounded,
            tr('Отправлено данных', 'Data sent'),
            '0 MB',
            NovaColors.purple,
          ),
          _statisticsCard(
            Icons.timer_rounded,
            tr('Время подключения', 'Connection time'),
            '00:00:00',
            NovaColors.green,
          ),
          _statisticsCard(
            Icons.speed_rounded,
            tr('Задержка сервера', 'Server latency'),
            '${currentServer.ping} ms',
            Colors.orange,
          ),
          const SizedBox(height: 15),
          _securityNotice(),
          const SizedBox(height: 20),
          Text(
            tr(
              '* Статистика демонстрационная. Реальные данные появятся после подключения VPN-движка.',
              '* Statistics are illustrative. Real data will appear after the VPN engine is integrated.',
            ),
            style: const TextStyle(
              color: NovaColors.muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statisticsCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: NovaColors.panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: NovaColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: NovaColors.muted,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SETTINGS PAGE
  // ==========================================================

  Widget _settingsPage() {
    return _pageContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Настройки', 'Settings'),
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Управляй параметрами приложения',
              'Manage your application preferences',
            ),
            style: const TextStyle(
              color: NovaColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 25),
          _settingsSection(
            tr('ВНЕШНИЙ ВИД', 'APPEARANCE'),
            [
              _languageSetting(),
            ],
          ),
          const SizedBox(height: 18),
          _settingsSection(
            tr('ПОДКЛЮЧЕНИЕ', 'CONNECTION'),
            [
              _switchSetting(
                Icons.bolt_rounded,
                tr('Автоподключение', 'Auto connect'),
                tr(
                  'Автоматическое подключение при запуске',
                  'Connect automatically on launch',
                ),
                autoConnect,
                (value) => setState(() => autoConnect = value),
              ),
              _switchSetting(
                Icons.shield_rounded,
                'Kill Switch',
                tr(
                  'Блокировка трафика при разрыве VPN',
                  'Block traffic if VPN disconnects',
                ),
                killSwitch,
                (value) => setState(() => killSwitch = value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _settingsSection(
            tr('УВЕДОМЛЕНИЯ', 'NOTIFICATIONS'),
            [
              _switchSetting(
                Icons.notifications_rounded,
                tr('Уведомления', 'Notifications'),
                tr(
                  'Уведомления приложения',
                  'Application notifications',
                ),
                notifications,
                (value) => setState(() => notifications = value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _settingsSection(
            tr('ПОДДЕРЖКА', 'SUPPORT'),
            [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                leading: const Icon(
                  Icons.telegram,
                  color: NovaColors.cyan,
                  size: 28,
                ),
                title: const Text(
                  'Telegram',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  '@artem_codess',
                  style: TextStyle(color: NovaColors.cyan),
                ),
                trailing: const Icon(
                  Icons.copy_rounded,
                  color: NovaColors.muted,
                  size: 19,
                ),
                onTap: copyTelegram,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _securityNotice(),
          const SizedBox(height: 25),
          Center(
            child: Column(
              children: [
                _logo(),
                const SizedBox(height: 10),
                const Text(
                  'NOVA VPN • VERSION 1.0.0',
                  style: TextStyle(
                    color: NovaColors.muted,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _settingsSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: NovaColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NovaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 7),
            child: Text(
              title,
              style: const TextStyle(
                color: NovaColors.muted,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _languageSetting() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          const Icon(
            Icons.language_rounded,
            color: NovaColors.cyan,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Язык приложения', 'App language'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Выбери язык интерфейса', 'Choose interface language'),
                  style: const TextStyle(
                    color: NovaColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _languageButton('RU', true),
          const SizedBox(width: 7),
          _languageButton('EN', false),
        ],
      ),
    );
  }

  Widget _languageButton(String label, bool russian) {
    final active = isRussian == russian;

    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        setState(() => isRussian = russian);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: active
              ? NovaColors.blue.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? NovaColors.blue : NovaColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : NovaColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _switchSetting(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: NovaColors.cyan,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: NovaColors.muted,
          fontSize: 11,
        ),
      ),
      value: value,
      activeThumbColor: NovaColors.blue,
      onChanged: onChanged,
    );
  }
}
