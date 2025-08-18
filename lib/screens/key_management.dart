import 'package:flutter/material.dart';
import 'package:taulight/classes/keys.dart';
import 'package:taulight/classes/sources.dart';
import 'package:taulight/screens/key_details.dart';
import 'package:taulight/services/key_storages.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/key_card.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

class KeyManagementScreen extends StatefulWidget {
  const KeyManagementScreen({super.key});

  @override
  State<KeyManagementScreen> createState() => _KeyManagementScreenState();
}

class _KeyManagementScreenState extends State<KeyManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<List<dynamic>>> _keysFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _keysFuture = _loadAllKeys();
  }

  Future<List<List<dynamic>>> _loadAllKeys() async {
    final keyStorage = KeyStorageService.ins;
    return Future.wait([
      keyStorage.loadAllServerKeys(),
      keyStorage.loadAllPersonalKeys(),
      keyStorage.loadAllEncryptors(),
      keyStorage.loadAllDEKs(),
    ]);
  }

  String _truncateKey(String key) {
    if (key.length <= 20) return key;
    return '${key.substring(0, 10)}...${key.substring(key.length - 10)}';
  }

  Future<void> _showKeyDetails(String title, Map<String, String> det) async {
    KeyDetailsScreen screen = KeyDetailsScreen(title: title, details: det);
    await moveTo(context, screen, fromBottom: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tabLabelColor = isDark ? Colors.grey[300]! : Colors.grey[800]!;
    final tabUnselected = isDark ? Colors.grey[600]! : Colors.grey[500]!;
    final indicatorColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    return Scaffold(
      appBar: TauAppBar.text('Key Management', actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          color: tabLabelColor,
          onPressed: () {
            setState(() {
              _keysFuture = _loadAllKeys();
            });
          },
        ),
      ]),
      body: SafeArea(
        child: FutureBuilder<List<List<dynamic>>>(
          future: _keysFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: indicatorColor,
                  strokeWidth: 2,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load keys',
                    style: TextStyle(color: Colors.red)),
              );
            }

            final serverKeys = snapshot.data![0] as List<ServerKey>;
            final personalKeys = snapshot.data![1] as List<PersonalKey>;
            final encryptorKeys = snapshot.data![2] as List<EncryptorKey>;
            final deks = snapshot.data![3] as List<DEK>;

            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: tabLabelColor,
                  unselectedLabelColor: tabUnselected,
                  indicatorColor: indicatorColor,
                  padding: EdgeInsets.zero,
                  tabAlignment: TabAlignment.center,
                  tabs: [
                    Tab(text: 'Server (${serverKeys.length})'),
                    Tab(text: 'Personal (${personalKeys.length})'),
                    Tab(text: 'Encryptor (${encryptorKeys.length})'),
                    Tab(text: 'DEK (${deks.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildServerKeysTab(serverKeys),
                      _buildPersonalKeysTab(personalKeys),
                      _buildEncryptorKeysTab(encryptorKeys),
                      _buildDEKsTab(deks),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildServerKeysTab(List<ServerKey> serverKeys) {
    if (serverKeys.isEmpty) {
      return const Center(
        child: Text(
          'No server keys found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: serverKeys.length,
      itemBuilder: (context, index) {
        final key = serverKeys[index];
        return KeyCard(
          title: key.address,
          subtitle: 'Encryption: ${key.encryption}',
          details: [
            'Public Key: ${_truncateKey(key.publicKey)}',
            'Source: ${key.source.type}',
            'Added: ${formatTime(key.source.datetime)}',
          ],
          onTap: () => _showKeyDetails('Server Key', {
            'Address': key.address,
            'Public Key': key.publicKey,
            'Encryption': key.encryption,
            'Source Type': key.source.type,
            'Date Added': key.source.datetime.toString(),
            if (key.source is HubSource)
              'Hub Address': (key.source as HubSource).address,
          }),
        );
      },
    );
  }

  Widget _buildPersonalKeysTab(List<PersonalKey> personalKeys) {
    if (personalKeys.isEmpty) {
      return const Center(
        child: Text(
          'No personal keys found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: personalKeys.length,
      itemBuilder: (context, index) {
        final key = personalKeys[index];
        return KeyCard(
          subtitle: 'Encryption: ${key.encryption}',
          details: [
            if (key.symKey != null) 'Has Symmetric Key',
            if (key.publicKey != null) 'Has Public Key',
            if (key.privateKey != null) 'Has Private Key',
            'Source: ${key.source.type}',
            'Added: ${formatTime(key.source.datetime)}',
          ],
          onTap: () => _showKeyDetails('Personal Key', {
            'Encryption': key.encryption,
            if (key.symKey != null) 'Symmetric Key': key.symKey!,
            if (key.publicKey != null) 'Public Key': key.publicKey!,
            if (key.privateKey != null) 'Private Key': key.privateKey!,
            'Source Type': key.source.type,
            'Date Added': key.source.datetime.toString(),
            if (key.source is HubSource)
              'Hub Address': (key.source as HubSource).address,
          }),
        );
      },
    );
  }

  Widget _buildEncryptorKeysTab(List<EncryptorKey> encryptorKeys) {
    if (encryptorKeys.isEmpty) {
      return const Center(
        child: Text(
          'No encryptor keys found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: encryptorKeys.length,
      itemBuilder: (context, index) {
        final key = encryptorKeys[index];
        return KeyCard(
          title: key.encryption, // TODO add nickname
          subtitle: 'Encryption: ${key.encryption}',
          details: [
            if (key.symKey != null) 'Has Symmetric Key',
            if (key.publicKey != null) 'Has Public Key',
            'Source: ${key.source.type}',
            'Added: ${formatTime(key.source.datetime)}',
          ],
          onTap: () => _showKeyDetails('Encryptor Key', {
            'Encryption': key.encryption,
            if (key.symKey != null) 'Symmetric Key': key.symKey!,
            if (key.publicKey != null) 'Public Key': key.publicKey!,
            'Source Type': key.source.type,
            'Date Added': key.source.datetime.toString(),
            if (key.source is HubSource)
              'Hub Address': (key.source as HubSource).address,
          }),
        );
      },
    );
  }

  Widget _buildDEKsTab(List<DEK> deks) {
    if (deks.isEmpty) {
      return const Center(
        child: Text('No DEK keys found', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deks.length,
      itemBuilder: (context, index) {
        final dek = deks[index];
        return KeyCard(
          title: dek.keyId.toString(),
          subtitle: 'Encryption: ${dek.encryption}',
          details: [
            if (dek.symKey != null) 'Has Symmetric Key',
            if (dek.publicKey != null) 'Has Public Key',
            if (dek.privateKey != null) 'Has Private Key',
            'Source: ${dek.source.type}',
            'Added: ${formatTime(dek.source.datetime)}',
          ],
          onTap: () => _showKeyDetails('DEK', {
            'Key ID': dek.keyId.toString(),
            'Encryption': dek.encryption,
            if (dek.symKey != null) 'Symmetric Key': dek.symKey!,
            if (dek.publicKey != null) 'Public Key': dek.publicKey!,
            if (dek.privateKey != null) 'Private Key': dek.privateKey!,
            'Source Type': dek.source.type,
            'Date Added': dek.source.datetime.toString(),
            if (dek.source is HubSource)
              'Hub Address': (dek.source as HubSource).address,
          }),
        );
      },
    );
  }
}
