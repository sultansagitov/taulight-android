import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/platform_settings_service.dart';
import 'package:taulight/widgets/tip.dart';

class ShowStatusSettings extends StatefulWidget {
  final Client client;

  const ShowStatusSettings(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _ShowStatusSettingsState();
}

class _ShowStatusSettingsState extends State<ShowStatusSettings> {
  bool? showStatus;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final val = await PlatformSettingsService.ins.get(widget.client);
    setState(() {
      showStatus = val.showStatus;
      loading = false;
    });
  }

  Future<void> _setValue(bool val) async {
    setState(() {
      showStatus = val;
      loading = true;
    });

    try {
      await PlatformSettingsService.ins.setShowStatus(widget.client, val);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var message = "This setting controls whether others can see "
        "your online status in groups and dialogs. ";

    message += !loading
        ? "Currently, your status is "
            "${showStatus! ? "visible" : "hidden"} to others."
        : "Loading current state...";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Show Status", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Tip(message),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Visible to others",
              style: theme.textTheme.bodyLarge,
            ),
            if (showStatus != null)
              Switch(
                value: showStatus!,
                onChanged: loading ? null : _setValue,
              )
            else
              const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ],
    );
  }
}
