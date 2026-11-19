import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'account_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sing_box/flutter_sing_box.dart' hide User;
import 'package:mmkv/mmkv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final FlutterSingBox novaVpn = FlutterSingBox();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://joebcmwluizjqrbatpfs.supabase.co',
    anonKey: 'sb_publishable_jEd50a0qw2_J17qEVYiLxg_0Mfj68LX',
  );

  // Create a passwordless guest account with a stable Supabase user ID.
  if (Supabase.instance.client.auth.currentUser == null) {
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous account creation failed: $e');
    }
  }

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
  bool favoritesOnly = false;
  final Set<String> favoriteIds = <String>{};
  String? loadError;
  String? connectionError;
  String search = '';

  StreamSubscription<ProxyState>? proxySubscription;

  String tr(String ru, String en) => isRussian ? ru : en;

  User? get currentUser => Supabase.instance.client.auth.currentUser;

  Future<void> _openTelegram(String message) async {
    final uri = Uri.parse('https://t.me/shatlyk_codes').replace(
      queryParameters: {'text': message},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _message(tr('Не удалось открыть Telegram', 'Could not open Telegram'));
    }
  }

  Future<void> _contactSupport() async {
    await _openTelegram(tr(
      'Здравствуйте! Нужна помощь с Nova VPN.',
      'Hello! I need help with Nova VPN.',
    ));
  }

  Future<void> _buyPremium() async {
    await _openTelegram(tr(
      'Здравствуйте! Хочу получить Nova VPN Premium. Мой ID: ${currentUser?.id ?? "не создан"}.',
      'Hello! I would like Nova VPN Premium. My ID: ${currentUser?.id ?? "not created"}.',
    ));
  }

  DateTime? premiumExpiresAt;
  bool isPremium = false;
  bool premiumLoading = true;

  Future<void> _refreshPremium() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final result = await Supabase.instance.client.from('nova_user_premium').select('expires_at').eq('user_id', user.id).maybeSingle();
      final raw = result == null ? null : result['expires_at'];
      final expiry = raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();
      if (!mounted) return;
      setState(() { premiumExpiresAt = expiry; isPremium = expiry != null && expiry.isAfter(DateTime.now()); premiumLoading = false; });
    } catch (_) { if (mounted) setState(() => premiumLoading = false); }
  }

  Future<void> _openAccountDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => NovaAccountDialog(
        onAccountChanged: () async {
          if (mounted) setState(() {});
          await _refreshPremium();
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _accountAndPremium() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.person_pin_rounded, color: cyan), const SizedBox(width: 9), Expanded(child: Text(tr('Твой аккаунт Nova', 'Your Nova account'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), if (isPremium) const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD166))]),
      const SizedBox(height: 8),
      Text(tr('Твой постоянный ID пользователя:', 'Your permanent user ID:'), style: const TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 5),
      SelectableText(currentUser?.id ?? tr('Создаём аккаунт...', 'Creating account...'), style: const TextStyle(fontSize: 12, color: cyan, fontWeight: FontWeight.w600)),
      OutlinedButton.icon(onPressed: currentUser == null ? null : () async { await Clipboard.setData(ClipboardData(text: currentUser!.id)); _message(tr('ID скопирован', 'ID copied')); }, icon: const Icon(Icons.copy_rounded, size: 17), label: Text(tr('Скопировать ID', 'Copy ID'))),
      const SizedBox(height: 6),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _openAccountDialog, icon: const Icon(Icons.alternate_email_rounded), label: Text(tr('Регистрация / вход по Email', 'Email registration / sign in')))),
      const Divider(height: 22, color: border),
      Row(children: [
        Icon(isPremium ? Icons.verified_rounded : Icons.lock_outline_rounded, color: isPremium ? green : muted),
        const SizedBox(width: 8),
        Expanded(child: Text(
          premiumLoading
              ? tr('Проверяем Premium...', 'Checking Premium...')
              : isPremium
                  ? tr(
                      'Premium активен до ${premiumExpiresAt!.day.toString().padLeft(2, "0")}.${premiumExpiresAt!.month.toString().padLeft(2, "0")}.${premiumExpiresAt!.year}',
                      'Premium active until ${premiumExpiresAt!.day}/${premiumExpiresAt!.month}/${premiumExpiresAt!.year}',
                    )
                  : tr('Базовый доступ активен', 'Free access is active'),
          style: TextStyle(color: isPremium ? green : Colors.white70, fontWeight: FontWeight.w600),
        )),
        IconButton(onPressed: _refreshPremium, icon: const Icon(Icons.refresh_rounded)),
      ]),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _buyPremium, icon: const Icon(Icons.workspace_premium_rounded), label: Text(tr('Связаться по поводу Premium', 'Contact about Premium')), style: FilledButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white))),
      const SizedBox(height: 6), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _contactSupport, icon: const Icon(Icons.support_agent_rounded), label: Text(tr('Поддержка Telegram', 'Telegram support')))),
      TextButton.icon(onPressed: () => launchUrl(Uri.parse('https://t.me/shatlyk_codes'), mode: LaunchMode.externalApplication), icon: const Icon(Icons.send_rounded), label: const Text('@shatlyk_codes')),
    ]),
  );

  NovaServer? get currentServer =>
      servers.isEmpty ? null : servers[selectedServer.clamp(0, servers.length - 1)];

  @override
  void initState() {
    super.initState();
    proxySubscription = novaVpn.proxyStateStream.listen(_onProxyState);
    _loadFavorites();
    _refreshPremium();
    loadServers();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => favoriteIds.addAll(prefs.getStringList('nova_favorite_servers') ?? const <String>[]));
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nova_favorite_servers', favoriteIds.toList());
  }

  void _toggleFavorite(NovaServer server) {
    setState(() {
      if (!favoriteIds.add(server.id)) favoriteIds.remove(server.id);
    });
    _saveFavorites();
  }

  void _selectQuickServer() {
    if (servers.isEmpty) {
      _message(tr('Нет доступных серверов', 'No servers available'));
      return;
    }
    if (isConnected || isConnecting) {
      _message(tr('Сначала отключи VPN', 'Disconnect VPN first'));
      return;
    }
    final preferred = servers.indexWhere((s) => favoriteIds.contains(s.id));
    setState(() {
      selectedServer = preferred >= 0 ? preferred : 0;
      selectedPage = 0;
    });
    _message(tr('Сервер выбран автоматически', 'Server selected automatically'));
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
      // Share links contain ':' and can be mistaken for YAML by the
      // subscription format detector. Wrap a single share link in Base64
      // so the provider selects its share-link subscription parser.
      final rawConfig = server.configText.trim();
      final isShareLink = RegExp(
        r'^(vless|vmess|ss|trojan|hysteria|hysteria2|hy2|tuic|anytls)://',
        caseSensitive: false,
      ).hasMatch(rawConfig);
      final configInput = isShareLink
          ? base64Encode(utf8.encode(rawConfig))
          : rawConfig;
      late final SingBox singBoxConfig;
      try {
        singBoxConfig = await SingBoxConfigProvider.provide(configInput);
      } catch (parseError) {
        // Some plugin versions can drop a single VLESS node while importing
        // a share link, then fail while looking for the missing proxy group.
        // For a simple TCP VLESS link, build the outbound explicitly instead.
        if (!rawConfig.toLowerCase().startsWith('vless://')) rethrow;
        singBoxConfig = await _buildVlessFallback(rawConfig);
      }

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
      // ProfileStorage.setUsingConfig expects a DIRECTORY, because the plugin
      // appends "using_config.json" to it. configPath itself is profile_*.json.
      profileStorage.setUsingConfig(File(configPath).parent.path);

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

  Future<SingBox> _buildVlessFallback(String raw) async {
    final uri = Uri.parse(raw.trim());
    if (uri.scheme.toLowerCase() != 'vless' ||
        uri.host.isEmpty ||
        uri.port <= 0 ||
        uri.userInfo.isEmpty) {
      throw Exception('Некорректная VLESS-ссылка');
    }

    final query = uri.queryParameters;
    final transportType = (query['type'] ?? 'tcp').toLowerCase();
    if (transportType != 'tcp') {
      throw Exception('Для этой VLESS-ссылки требуется транспорт $transportType. Проверь конфигурацию сервера.');
    }

    final fragment = uri.fragment.split('?serverDescription=').first;
    final decodedName = Uri.decodeComponent(fragment).trim();
    final tag = decodedName.isEmpty ? 'Nova VLESS' : decodedName;

    final fingerprint = query['fp'];
    final OutboundUTLSOptions? utls = fingerprint?.isNotEmpty == true
        ? (OutboundUTLSOptions()
          ..enabled = true
          ..fingerprint = fingerprint!)
        : null;

    OutboundTLSOptions? tls;
    final security = (query['security'] ?? '').toLowerCase();
    if (security == 'tls' || security == 'xtls') {
      tls = OutboundTLSOptions()
        ..enabled = true
        ..insecure = query['allowInsecure'] == '1' || query['insecure'] == '1'
        ..serverName = query['sni'] ?? uri.host
        ..utls = utls;
    } else if (security == 'reality') {
      tls = OutboundTLSOptions()
        ..enabled = true
        ..serverName = query['sni'] ?? uri.host
        ..utls = utls
        ..reality = (OutboundRealityOptions()
          ..enabled = true
          ..publicKey = query['pbk']
          ..shortId = query['sid'] ?? '');
    } else if (security.isNotEmpty && security != 'none') {
      throw Exception('Неподдерживаемый тип защиты VLESS: $security');
    }

    final node = VlessOutbound(tag: tag)
      ..server = uri.host
      ..serverPort = uri.port
      ..uuid = uri.userInfo
      ..flow = query['flow']
      ..tls = tls;

    const directTag = 'direct';
    final selector = SelectorOutbound(
      tag: FlutterSingBoxConstants.defaultGroup,
    )..outbounds = [tag, directTag];

    // Start from the plugin's complete, bundled sing-box template. This
    // keeps required DNS, inbound and route sections instead of relying on
    // the provider to reconstruct them from a partial config.
    final template = jsonDecode(
      await rootBundle.loadString(FlutterSingBoxConstants.templateConfig),
    ) as Map<String, dynamic>;
    template['outbounds'] = [
      selector.toJson(),
      node.toJson(),
      DirectOutbound(tag: directTag).toJson(),
    ];

    return SingBoxConfigProvider.provide(template);
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
            const SizedBox(height: 18),
            _accountAndPremium(),
            const SizedBox(height: 18),
            _quickStats(),
          ],
        ),
      );

  Widget _quickStats() => Row(
        children: [
          Expanded(child: _statCard(Icons.public_rounded, '${servers.length}', tr('Серверов', 'Servers'), cyan)),
          const SizedBox(width: 10),
          Expanded(child: _statCard(Icons.favorite_rounded, '${favoriteIds.length}', tr('Избранное', 'Favorites'), purple)),
          const SizedBox(width: 10),
          Expanded(child: _statCard(Icons.shield_rounded, isConnected ? tr('Активен', 'Active') : tr('Ожидание', 'Idle'), tr('Защита', 'Protection'), green)),
        ],
      );

  Widget _statCard(IconData icon, String value, String label, Color color) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 10),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: muted)),
        ]),
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
      final matchesSearch = s.name.toLowerCase().contains(q) || s.country.toLowerCase().contains(q);
      return matchesSearch && (!favoritesOnly || favoriteIds.contains(s.id));
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
          Wrap(spacing: 8, children: [
            FilterChip(selected: !favoritesOnly, label: Text(tr('Все серверы', 'All servers')), onSelected: (_) => setState(() => favoritesOnly = false)),
            FilterChip(selected: favoritesOnly, avatar: const Icon(Icons.favorite, size: 16), label: Text(tr('Избранное', 'Favorites')), onSelected: (_) => setState(() => favoritesOnly = true)),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${filtered.length} ${tr('серверов', 'servers')}',
                  style: const TextStyle(color: muted)),
              const Spacer(),
              TextButton.icon(
                onPressed: isLoading ? null : _selectQuickServer,
                icon: const Icon(Icons.bolt_rounded, size: 17),
                label: Text(tr('Автовыбор', 'Auto select')),
              ),
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
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: favoriteIds.contains(server.id) ? tr('Убрать из избранного', 'Remove favorite') : tr('В избранное', 'Add favorite'),
            onPressed: () => _toggleFavorite(server),
            icon: Icon(favoriteIds.contains(server.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: favoriteIds.contains(server.id) ? const Color(0xFFFF6B9A) : muted),
          ),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? blue : muted),
        ]),
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
            _accountAndPremium(),
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
