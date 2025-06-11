import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taulight/classes/keys.dart';
import 'package:taulight/classes/sources.dart';
import 'package:taulight/services/key_storage_service.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';

class KeyManagementScreen extends StatefulWidget {
  const KeyManagementScreen({super.key});

  @override
  State<KeyManagementScreen> createState() => _KeyManagementScreenState();
}

class _KeyManagementScreenState extends State<KeyManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<ServerKey> serverKeys = [];
  List<PersonalKey> personalKeys = [];
  List<EncryptorKey> encryptorKeys = [];
  List<DEK> deks = [];



  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllKeys();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllKeys() async {
    setState(() => isLoading = true);

    try {
      final keyStorage = KeyStorageService.ins;

      final results = await Future.wait([
        keyStorage.loadAllServerKeys(),
        keyStorage.loadAllPersonalKeys(),
        keyStorage.loadAllEncryptors(),
        keyStorage.loadAllDEKs(),
      ]);

      setState(() {
        serverKeys = results[0] as List<ServerKey>;
        personalKeys = results[1] as List<PersonalKey>;
        encryptorKeys = results[2] as List<EncryptorKey>;
        deks = results[3] as List<DEK>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        snackBarError(context, 'Failed to load keys: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllKeys,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Server (${serverKeys.length})'),
            Tab(text: 'Personal (${personalKeys.length})'),
            Tab(text: 'Encryptor (${encryptorKeys.length})'),
            Tab(text: 'DEK (${deks.length})'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildServerKeysTab(),
          _buildPersonalKeysTab(),
          _buildEncryptorKeysTab(),
          _buildDEKsTab(),
        ],
      ),
    );
  }

  Widget _buildServerKeysTab() {
    if (serverKeys.isEmpty) {
      return const Center(
        child: Text('No server keys found', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: serverKeys.length,
      itemBuilder: (context, index) {
        final key = serverKeys[index];
        return _buildKeyCard(
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

  Widget _buildPersonalKeysTab() {
    if (personalKeys.isEmpty) {
      return const Center(
        child: Text('No personal keys found', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: personalKeys.length,
      itemBuilder: (context, index) {
        final key = personalKeys[index];
        return _buildKeyCard(
          title: 'Personal Key',
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

  Widget _buildEncryptorKeysTab() {
    if (encryptorKeys.isEmpty) {
      return const Center(
        child: Text('No encryptor keys found', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: encryptorKeys.length,
      itemBuilder: (context, index) {
        final key = encryptorKeys[index];
        return _buildKeyCard(
          title: 'Key ID: ${key.keyId}',
          subtitle: 'Encryption: ${key.encryption}',
          details: [
            if (key.symKey != null) 'Has Symmetric Key',
            if (key.publicKey != null) 'Has Public Key',
            'Source: ${key.source.type}',
            'Added: ${formatTime(key.source.datetime)}',
          ],
          onTap: () => _showKeyDetails('Encryptor Key', {
            'Key ID': key.keyId,
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

  Widget _buildDEKsTab() {
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
        return _buildKeyCard(
          title: 'DEK ID: ${dek.keyId}',
          subtitle: 'Encryption: ${dek.encryption}',
          details: [
            if (dek.symKey != null) 'Has Symmetric Key',
            if (dek.publicKey != null) 'Has Public Key',
            if (dek.privateKey != null) 'Has Private Key',
            'Source: ${dek.source.type}',
            'Added: ${formatTime(dek.source.datetime)}',
          ],
          onTap: () => _showKeyDetails('DEK', {
            'Key ID': dek.keyId,
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

  Widget _buildKeyCard({
    required String title,
    required String subtitle,
    required List<String> details,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 8),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            )),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: onTap,
          tooltip: 'View Details',
        ),
        onTap: onTap,
      ),
    );
  }

  String _truncateKey(String key) {
    if (key.length <= 20) return key;
    return '${key.substring(0, 10)}...${key.substring(key.length - 10)}';
  }

  void _showKeyDetails(String title, Map<String, String> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: details.entries.map((entry) =>
                _buildDetailRow(entry.key, entry.value)
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              snackBar(context, 'Copied to clipboard');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}