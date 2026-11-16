
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NovaApp());
}

// NOVA DESIGN SYSTEM
const Color bg = Color(0xFF0B1020);
const Color panel = Color(0xFF151E30);
const Color blue = Color(0xFF398BFF);
const Color cyan = Color(0xFF35C8F4);
const Color muted = Color(0xFF8998B2);
const Color borderColor = Color(0xFF26344C);

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: blue,
          secondary: cyan,
          surface: panel,
        ),
        fontFamily: 'Roboto',
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: panel,
        ),
      ),
      home: const NovaHome(),
    );
  }
}

// SERVER MODEL
class VpnServer {
  final String country;
  final String city;
  final String flag;
  final int ping;

  const VpnServer(
    this.country,
    this.city,
    this.flag,
    this.ping,
  );
}

const servers = [
  VpnServer('France', 'Paris', '🇫🇷', 18),
  VpnServer('Germany', 'Frankfurt', '🇩🇪', 24),
  VpnServer('Netherlands', 'Amsterdam', '🇳🇱', 29),
  VpnServer('Switzerland', 'Zurich', '🇨🇭', 31),
  VpnServer('United Kingdom', 'London', '🇬🇧', 35),
  VpnServer('United States', 'New York', '🇺🇸', 95),
  VpnServer('Japan', 'Tokyo', '🇯🇵', 142),
];

class NovaHome extends StatefulWidget {
  const NovaHome({super.key});

  @override
  State<NovaHome> createState() => _NovaHomeState();
}

class _NovaHomeState extends State<NovaHome>
    with TickerProviderStateMixin {
  int page = 0;
  int selectedServer = 0;

  bool connected = false;
  bool autoConnect = false;
  bool killSwitch = false;

  final TextEditingController searchController =
      TextEditingController();

  String searchQuery = '';

  late final AnimationController pulseController;

  VpnServer get server => servers[selectedServer];

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    pulseController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void selectServer(int index) {
    setState(() {
      selectedServer = index;
      connected = false;
    });

    showMessage(
      '${servers[index].city} выбран',
    );
  }

  void toggleConnection() {
    setState(() {
      connected = !connected;
    });

    showMessage(
      connected
          ? 'Демонстрационный режим: подключено'
          : 'Демонстрационный режим: отключено',
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 750;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (desktop) _sidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _topBar(desktop),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 250,
                          ),
                          child: _pageContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              desktop ? null : _bottomNavigation(),
        );
      },
    );
  }

  Widget _sidebar() {
    return Container(
      width: 225,
      decoration: const BoxDecoration(
        color: Color(0xFF101829),
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          _logo(),
          const SizedBox(height: 45),
          _navItem(Icons.home_rounded, 'Главная', 0),
          _navItem(Icons.public_rounded, 'Серверы', 1),
          _navItem(Icons.bar_chart_rounded, 'Статистика', 2),
          _navItem(Icons.settings_rounded, 'Настройки', 3),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_rounded, color: cyan),
                SizedBox(height: 9),
                Text(
                  'Nova Protection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your privacy matters',
                  style: TextStyle(
                    color: muted,
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

  Widget _logo() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Icon(
            Icons.shield_rounded,
            color: cyan,
            size: 34,
          ),
          SizedBox(width: 10),
          Text(
            'NOVA',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index,
  ) {
    final active = page == index;

    return InkWell(
      onTap: () => setState(() => page = index),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: active
              ? blue.withOpacity(0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? cyan : muted,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : muted,
                fontWeight: active
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool desktop) {
    const titles = [
      'Главная',
      'Серверы',
      'Статистика',
      'Настройки',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Row(
        children: [
          if (!desktop) ...[
            const Icon(
              Icons.shield_rounded,
              color: cyan,
              size: 27,
            ),
            const SizedBox(width: 9),
            const Text(
              'NOVA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 20,
              ),
            ),
          ] else
            Text(
              titles[page],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.diamond_outlined,
                  color: cyan,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'NOVA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNavigation() {
    return NavigationBar(
      backgroundColor: const Color(0xFF101829),
      selectedIndex: page,
      onDestinationSelected: (value) {
        setState(() => page = value);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Главная',
        ),
        NavigationDestination(
          icon: Icon(Icons.public_outlined),
          label: 'Серверы',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Статистика',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Настройки',
        ),
      ],
    );
  }

  Widget _pageContent() {
    switch (page) {
      case 1:
        return _serversPage();
      case 2:
        return _statsPage();
      case 3:
        return _settingsPage();
      default:
        return _homePage();
    }
  }

  Widget _homePage() {
    return SingleChildScrollView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.all(22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Защити своё соединение',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Быстро. Безопасно. Приватно.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 35),
              _connectButton(),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  connected ? 'Демонстрация: включено' : 'Не подключено',
                  key: ValueKey(connected),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: connected ? cyan : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Режим демонстрации интерфейса',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 30),
              _selectedServerCard(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      Icons.arrow_downward_rounded,
                      'Загрузка',
                      '—',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      Icons.arrow_upward_rounded,
                      'Отдача',
                      '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _securityCard(),
              const SizedBox(height: 25),
              const Text(
                'NOVA VPN • YOUR PRIVACY MATTERS',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _connectButton() {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final glow = 0.20 + pulseController.value * 0.16;

        return GestureDetector(
          onTap: toggleConnection,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: connected
                    ? [
                        const Color(0xFF16BFA5),
                        const Color(0xFF087F91),
                      ]
                    : [
                        blue,
                        const Color(0xFF2454C8),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (connected ? cyan : blue)
                      .withOpacity(glow),
                  blurRadius: 45,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 145,
                height: 145,
                decoration: const BoxDecoration(
                  color: Color(0xFF111D32),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: connected ? cyan : Colors.white,
                  size: 70,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _selectedServerCard() {
    return _panel(
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => setState(() => page = 1),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Text(
                server.flag,
                style: const TextStyle(fontSize: 34),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ВЫБРАННЫЙ СЕРВЕР',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      server.city,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      server.country,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(
                    Icons.signal_cellular_alt,
                    color: cyan,
                  ),
                  Text(
                    '${server.ping} ms*',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    String label,
    String value,
  ) {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cyan),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityCard() {
    return _panel(
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: cyan,
              size: 27,
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Защита Nova',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'VPN-движок ещё не подключён. '
                    'Этот экран не обеспечивает реальную защиту.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serversPage() {
    final filtered = servers
        .where((item) {
          final query = searchQuery.toLowerCase();
          return item.city.toLowerCase().contains(query) ||
              item.country.toLowerCase().contains(query);
        })
        .toList()
      ..sort((a, b) => a.ping.compareTo(b.ping));

    return ListView(
      key: const ValueKey('servers'),
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Выберите сервер',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Найдите подходящее расположение.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() => searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Поиск страны или города',
            prefixIcon: const Icon(
              Icons.search,
              color: cyan,
            ),
            filled: true,
            fillColor: panel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      setState(() => searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(25),
            child: Center(
              child: Text(
                'Сервер не найден',
                style: TextStyle(color: muted),
              ),
            ),
          ),
        ...filtered.map((item) {
          final index = servers.indexOf(item);
          final selected = selectedServer == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _panel(
              child: ListTile(
                onTap: () => selectServer(index),
                leading: Text(
                  item.flag,
                  style: const TextStyle(fontSize: 30),
                ),
                title: Text(
                  item.country,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  item.city,
                  style: const TextStyle(color: muted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.ping} ms*',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: selected ? cyan : muted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        const Text(
          '* Указанные значения Ping демонстрационные.',
          style: TextStyle(color: muted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _statsPage() {
    return ListView(
      key: const ValueKey('stats'),
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Статистика',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Показатели сетевого соединения.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        _statCard(
          Icons.arrow_downward,
          'Скорость загрузки',
          '—',
        ),
        const SizedBox(height: 12),
        _statCard(
          Icons.arrow_upward,
          'Скорость отдачи',
          '—',
        ),
        const SizedBox(height: 12),
        _statCard(
          Icons.data_usage,
          'Использовано данных',
          '—',
        ),
        const SizedBox(height: 12),
        _statCard(
          Icons.timer_outlined,
          'Время соединения',
          '—',
        ),
        const SizedBox(height: 20),
        _panel(
          child: const Padding(
            padding: EdgeInsets.all(17),
            child: Text(
              'Статистика появится после интеграции '
              'VPN-движка и сетевого мониторинга.',
              style: TextStyle(color: muted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsPage() {
    return ListView(
      key: const ValueKey('settings'),
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Настройки',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 22),
        _panel(
          child: Column(
            children: [
              _settingSwitch(
                Icons.power_settings_new,
                'Автоподключение',
                'Настройка интерфейса',
                autoConnect,
                (value) => setState(() => autoConnect = value),
              ),
              const Divider(color: borderColor),
              _settingSwitch(
                Icons.shield,
                'Kill Switch',
                'Требуется реализация VPN-движка',
                killSwitch,
                (value) => setState(() => killSwitch = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          child: Column(
            children: [
              _settingInfo(
                Icons.swap_horiz,
                'VPN-протокол',
                'WireGuard — планируется',
              ),
              const Divider(color: borderColor),
              _settingInfo(
                Icons.language,
                'Язык',
                'Русский',
              ),
              const Divider(color: borderColor),
              _settingInfo(
                Icons.info_outline,
                'Версия приложения',
                'Nova 1.1.0',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'NOVA VPN • DARK EDITION',
            style: TextStyle(
              color: muted,
              letterSpacing: 1.5,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingSwitch(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: cyan,
      secondary: Icon(icon, color: cyan),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: muted,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _settingInfo(
    IconData icon,
    String title,
    String value,
  ) {
    return ListTile(
      leading: Icon(icon, color: cyan),
      title: Text(title),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: muted,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
