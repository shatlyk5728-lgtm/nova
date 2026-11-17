import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sing_box/flutter_sing_box.dart';
import 'package:mmkv/mmkv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final FlutterSingBox novaVpn = FlutterSingBox();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://joebcmwluizjqrbatpfs.supabase.co',
    anonKey: 'sb_publishable_jEd50a0qw2_J17qEVYiLxg_0Mfj68LX',
  );

  await MMKV.initialize();
  await novaVpn.init();

  runApp(const NovaApp());
}

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

class NovaServer {
  final String id;
  final String name;
  final String country;
  final String flag;
  final String protocol;
  final String configText;

  const NovaServer({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.protocol,
    required this.configText,
  });

  factory NovaServer.fromJson(Map<String, dynamic> json) => NovaServer(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Nova server').toString(),
        country: (json['country'] ?? '').toString(),
        flag: (json['flag'] ?? '🌐').toString(),
        protocol: (json['protocol'] ?? '').toString(),
        configText: (json['config_text'] ?? '').toString(),
      );
}

class NovaHome extends StatefulWidget {
  const NovaHome({super.key});

  @override
  State<NovaHome> createState() => _NovaHomeState();
}

class _NovaHomeState extends State<NovaHome> {
  static const Color bg = Color(0xFF080B16);
  static const Color panel = Color(0xFF111729);
  static const Color border = Color(0xFF252E49);
  static const Color blue = Color(0xFF6575FF);
  static const Color purple = Color(0xFF9B72FF);
  static const Color cyan = Color(0xFF45D7F5);
  static const Color green = Color(0xFF35D6A0);
  static const Color muted = Color(0xFF8993AD);

  final ProfileStorage profileStorage = ProfileStorage.instance;

  List<NovaServer> servers = [];
  int selectedServer = 0;
  int selectedPage = 0;
  bool isLoading = true;
  bool isConnecting = false;
  bool isConnected = false;
  bool isRussian = true;
  String? loadError;
  String? connectionError;
  String search = '';

  StreamSubscription<ProxyState>? proxySubscription;

  String tr(String ru, String en) => isRussian ? ru : en;

  NovaServer? get currentServer =>
      servers.isEmpty ? null : servers[selectedServer.clamp(0, servers.length - 1)];

  @override
  void initState() {
    super.initState();
    proxySubscription = novaVpn.proxyStateStream.listen(_onProxyState);
    loadServers();
  }

  void _onProxyState(ProxyState state) {
    if (!mounted) return;
    setState(() {
      if (state is ProxyStarted) {
        isConnected = true;
        isConnecting = false;
        connectionError = null;
      } else if (state is ProxyStarting) {
        isConnecting = true;
      } else if (state is ProxyStopping) {
        isConnecting = true;
      } else if (state is ProxyStopped) {
        isConnected = false;
        isConnecting = false;
        if (state.errMessage != null && state.errMessage!.isNotEmpty) {
          connectionError = state.errMessage;
        }
      }
    });
  }

  Future<void> loadServers() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'dynamic-service',
        method: HttpMethod.get,
      );
      final body = response.data;
      if (body is! Map || body['servers'] is! List) {
        throw Exception('Неверный ответ сервера');
      }

      final result = (body['servers'] as List)
          .whereType<Map>()
          .map((item) => NovaServer.fromJson(Map<String, dynamic>.from(item)))
          .where((server) => server.configText.trim().isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        servers = result;
        if (selectedServer >= servers.length) selectedServer = 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
    }
  }

  Future<bool> _prepareWindowsService() async {
    if (!Platform.isWindows) return false;

    final status = await novaVpn.queryServiceStatus();
    if (status == WindowsServiceStatus.notInstalled) {
      await novaVpn.installService(
        serviceName: 'clash_sing_service',
        displayName: windowsServiceDisplayName,
        description: windowsServiceDescription,
      );
      return false;
    }
    return status == WindowsServiceStatus.running;
  }

  Future<void> toggleConnection() async {
    if (isConnecting) return;

    if (isConnected) {
      try {
        await novaVpn.stopVpn();
      } catch (e) {
        _message('${tr('Не удалось отключить VPN', 'Could not stop VPN')}: $e');
      }
      return;
    }

    final server = currentServer;
    if (server == null) {
      _message(tr('Сначала дождись загрузки серверов', 'Wait for servers to load'));
      return;
    }

    setState(() {
      isConnecting = true;
      connectionError = null;
    });

    try {
      // Convert the VLESS / Shadowsocks share link to a typed sing-box config.
      final singBoxConfig =
          await SingBoxConfigProvider.provide(server.configText.trim());

      // Save the config as a local profile and make it the active config.
      final id = profileStorage.generateProfileId;
      final configPath = await profileStorage.getProfilePath(id);
      final existingProfiles = profileStorage.getProfiles();

      final profile = Profile(
        id: id,
        order: existingProfiles.length,
        name: server.name,
        outboundsCount: singBoxConfig.outbounds.length,
        typed: TypedProfile(
          type: ProfileType.local,
          path: configPath,
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      await profileStorage.addProfile(profile, singBoxConfig);
      profileStorage.setSelectedProfile(id);
      profileStorage.setUsingConfig(configPath);

      final windowsServiceAlreadyRunning = await _prepareWindowsService();

      if (windowsServiceAlreadyRunning) {
        await novaVpn.serviceReload();
      } else {
        await novaVpn.startVpn();
      }

      // Do not mark the connection as active here. The state stream is
      // the source of truth and will update the UI when the core starts.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isConnecting = false;
        connectionError = e.toString();
      });
      _message('${tr('Ошибка подключения', 'Connection error')}: $e');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF192139),
      ),
    );
  }

  @override
  void dispose() {
    proxySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 850;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (desktop) _sidebar(),
            Expanded(
              child: Column(
                children: [
                  _topBar(desktop),
                  Expanded(child: _page()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: desktop ? null : _bottomNav(),
    );
  }

  Widget _logo() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(colors: [blue, purple]),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NOVA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text('VPN NETWORK',
                  style: TextStyle(fontSize: 9, color: muted, letterSpacing: 2)),
            ],
          ),
        ],
      );

  Widget _sidebar() => Container(
        width: 235,
        decoration: const BoxDecoration(
          color: Color(0xFF0D1222),
          border: Border(right: BorderSide(color: border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _logo()),
            const SizedBox(height: 42),
            _navItem(0, Icons.grid_view_rounded, tr('Главная', 'Home')),
            _navItem(1, Icons.public_rounded, tr('Серверы', 'Servers')),
            _navItem(2, Icons.settings_rounded, tr('Настройки', 'Settings')),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('NOVA VPN • v1.0.0',
                  style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1)),
            ),
          ],
        ),
      );

  Widget _navItem(int index, IconData icon, String label) {
    final active = selectedPage == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        selected: active,
        selectedTileColor: blue.withOpacity(.15),
        leading: Icon(icon, color: active ? blue : muted),
        title: Text(label, style: TextStyle(color: active ? Colors.white : muted)),
        onTap: () => setState(() => selectedPage = index),
      ),
    );
  }

  Widget _topBar(bool desktop) => Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))),
        child: Row(
          children: [
            if (desktop)
              Text(
                selectedPage == 0
                    ? tr('Главная', 'Home')
                    : selectedPage == 1
                        ? tr('Серверы', 'Servers')
                        : tr('Настройки', 'Settings'),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              )
            else
              _logo(),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => isRussian = !isRussian),
              child: Text(isRussian ? 'RU' : 'EN'),
            ),
            const Icon(Icons.person_outline_rounded, color: muted),
          ],
        ),
      );

  Widget _bottomNav() => NavigationBar(
        height: 68,
        backgroundColor: const Color(0xFF0D1222),
        indicatorColor: blue.withOpacity(.2),
        selectedIndex: selectedPage,
        onDestinationSelected: (i) => setState(() => selectedPage = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.grid_view_rounded), label: tr('Главная', 'Home')),
          NavigationDestination(icon: const Icon(Icons.public_rounded), label: tr('Серверы', 'Servers')),
          NavigationDestination(icon: const Icon(Icons.settings_rounded), label: tr('Настройки', 'Settings')),
        ],
      );

  Widget _page() {
    if (selectedPage == 1) return _serversPage();
    if (selectedPage == 2) return _settingsPage();
    return _homePage();
  }

  Widget _pageContainer(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: child,
          ),
        ),
      );

  Widget _homePage() => _pageContainer(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Добро пожаловать в Nova', 'Welcome to Nova'),
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(tr('Твой интернет. Твои правила.', 'Your internet. Your rules.'),
                style: const TextStyle(color: muted)),
            const SizedBox(height: 24),
            _connectionCard(),
            const SizedBox(height: 18),
            _selectedServerCard(),
            const SizedBox(height: 18),
            _notice(),
          ],
        ),
      );

  Widget _connectionCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF202B59), Color(0xFF171D3A), Color(0xFF241A45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: blue.withOpacity(.4)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 9, color: isConnected ? green : muted),
                const SizedBox(width: 9),
                Text(
                  isConnecting
                      ? tr('ПОДКЛЮЧЕНИЕ...', 'CONNECTING...')
                      : isConnected
                          ? tr('ЗАЩИЩЁННОЕ ПОДКЛЮЧЕНИЕ', 'VPN CONNECTED')
                          : tr('НЕ ПОДКЛЮЧЕНО', 'NOT CONNECTED'),
                  style: const TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.shield_rounded, color: cyan),
              ],
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: toggleConnection,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 138,
                height: 138,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isConnected ? [green, const Color(0xFF168C83)] : [blue, purple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected ? green : blue).withOpacity(.35),
                      blurRadius: 32,
                      spreadRadius: 6,
                    ),
                  ],
                  border: Border.all(color: Colors.white24, width: 5),
                ),
                child: Center(
                  child: isConnecting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.power_settings_new_rounded, size: 62, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isConnected
                  ? tr('VPN подключён', 'VPN connected')
                  : isConnecting
                      ? tr('Подключаемся...', 'Connecting...')
                      : tr('Нажми для подключения', 'Tap to connect'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            Text(
              currentServer == null
                  ? tr('Сервер не выбран', 'No server selected')
                  : '${currentServer!.flag} ${currentServer!.name}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (connectionError != null) ...[
              const SizedBox(height: 12),
              Text(connectionError!, style: const TextStyle(color: Colors.orange, fontSize: 11)),
            ],
          ],
        ),
      );

  Widget _selectedServerCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const Icon(Icons.public_rounded, color: cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentServer == null
                    ? tr('Сервер не выбран', 'No server selected')
                    : '${currentServer!.flag}  ${currentServer!.name} • ${currentServer!.protocol}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => selectedPage = 1),
              child: Text(tr('Изменить', 'Change')),
            ),
          ],
        ),
      );

  Widget _notice() => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cyan.withOpacity(.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cyan.withOpacity(.18)),
        ),
        child: Text(
          tr(
            'Nova использует sing-box. Статус подключения отображается по состоянию VPN-движка. Доступность сервера зависит от его конфигурации и сети.',
            'Nova uses sing-box. Connection status reflects the VPN engine state. Server availability depends on its configuration and network.',
          ),
          style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
        ),
      );

  Widget _serversPage() {
    final filtered = servers.where((s) {
      final q = search.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.country.toLowerCase().contains(q);
    }).toList();

    return _pageContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Выбери локацию', 'Choose your location'),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: tr('Поиск страны или сервера', 'Search country or server'),
              prefixIcon: const Icon(Icons.search, color: muted),
              filled: true,
              fillColor: panel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('${filtered.length} ${tr('серверов', 'servers')}',
                  style: const TextStyle(color: muted)),
              const Spacer(),
              TextButton.icon(
                onPressed: isLoading ? null : loadServers,
                icon: const Icon(Icons.refresh, size: 17),
                label: Text(tr('Обновить', 'Refresh')),
              ),
            ],
          ),
          if (isLoading) const Center(child: Padding(padding: EdgeInsets.all(25), child: CircularProgressIndicator())),
          if (loadError != null)
            Center(child: Text('${tr('Ошибка загрузки', 'Loading error')}: $loadError')),
          if (!isLoading && loadError == null && filtered.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(25), child: Text(tr('Серверы не найдены', 'No servers found')))),
          for (final server in filtered) _serverTile(server),
        ],
      ),
    );
  }

  Widget _serverTile(NovaServer server) {
    final index = servers.indexOf(server);
    final selected = selectedServer == index;
    return Card(
      color: selected ? blue.withOpacity(.14) : panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? blue : border),
      ),
      child: ListTile(
        onTap: () {
          if (isConnected || isConnecting) {
            _message(tr('Сначала отключи VPN', 'Disconnect VPN first'));
            return;
          }
          setState(() => selectedServer = index);
        },
        leading: Text(server.flag, style: const TextStyle(fontSize: 29)),
        title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${server.country} • ${server.protocol}',
            style: const TextStyle(color: muted, fontSize: 11)),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? blue : muted,
        ),
      ),
    );
  }

  Widget _settingsPage() => _pageContainer(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Настройки', 'Settings'),
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: border),
              ),
              child: SwitchListTile(
                title: Text(tr('Язык интерфейса', 'Interface language')),
                subtitle: Text(isRussian ? 'Русский' : 'English'),
                value: isRussian,
                onChanged: (v) => setState(() => isRussian = v),
              ),
            ),
            const SizedBox(height: 15),
            _notice(),
            const SizedBox(height: 20),
            const Center(
              child: Text('NOVA VPN • VERSION 1.0.0',
                  style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1)),
            ),
          ],
        ),
      );
}
