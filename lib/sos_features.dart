import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'models.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<AppState>().emergencyContacts;
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactForm(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add contact'),
      ),
      body: contacts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.contact_phone_outlined, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'No emergency contacts yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Save trusted people for quick access. Calls always open in your phone dialer first.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: contacts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(contact.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(
                      contact.relationship.isEmpty
                          ? contact.phone
                          : '${contact.relationship} • ${contact.phone}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'call') _confirmDial(context, contact);
                        if (action == 'edit') {
                          _showContactForm(context, existing: contact);
                        }
                        if (action == 'delete') {
                          _confirmDelete(context, contact);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'call',
                          child: Text('Open dialer'),
                        ),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => _confirmDial(context, contact),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDial(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Call ${contact.name}?'),
        content: Text(
          'Kalasag will open ${contact.phone} in your phone dialer. You will still choose whether to place the call.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.dialpad),
            label: const Text('Open dialer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: contact.phone));
    } on PlatformException {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone dialer is available.')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('${contact.name} will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await context.read<AppState>().deleteEmergencyContact(contact.id);
      } catch (exception) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(exception.toString())));
        }
      }
    }
  }

  Future<void> _showContactForm(
    BuildContext context, {
    EmergencyContact? existing,
  }) async {
    final name = TextEditingController(text: existing?.name);
    final phone = TextEditingController(text: existing?.phone);
    final relationship = TextEditingController(text: existing?.relationship);
    final formKey = GlobalKey<FormState>();
    String? error;
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Add emergency contact' : 'Edit contact',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter a contact name.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                    ),
                    validator: (value) =>
                        EmergencyContact.isValidPhone(value ?? '')
                        ? null
                        : 'Enter 7 to 15 digits.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: relationship,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Relationship (optional)',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() {
                              saving = true;
                              error = null;
                            });
                            try {
                              final state = sheetContext.read<AppState>();
                              if (existing == null) {
                                await state.addEmergencyContact(
                                  name: name.text,
                                  phone: phone.text,
                                  relationship: relationship.text,
                                );
                              } else {
                                await state.updateEmergencyContact(
                                  existing.copyWith(
                                    name: name.text,
                                    phone: phone.text,
                                    relationship: relationship.text,
                                  ),
                                );
                              }
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            } catch (exception) {
                              setSheetState(() {
                                saving = false;
                                error = exception.toString().replaceFirst(
                                  'FormatException: ',
                                  '',
                                );
                              });
                            }
                          },
                    child: Text(saving ? 'Saving…' : 'Save contact'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    relationship.dispose();
  }
}

class EmergencyToolsScreen extends StatefulWidget {
  const EmergencyToolsScreen({super.key});

  @override
  State<EmergencyToolsScreen> createState() => _EmergencyToolsScreenState();
}

class _EmergencyToolsScreenState extends State<EmergencyToolsScreen> {
  static const _channel = MethodChannel('kalasag/emergency_tools');
  bool torchOn = false;
  bool whistleOn = false;
  bool busy = false;

  @override
  void dispose() {
    _channel.invokeMethod<void>('stopAll');
    super.dispose();
  }

  Future<void> _invoke(String method) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await _channel.invokeMethod<void>(method);
      if (!mounted) return;
      setState(() {
        if (method == 'toggleTorch') torchOn = !torchOn;
        if (method == 'toggleWhistle') whistleOn = !whistleOn;
      });
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'This tool is unavailable.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Offline safety tools')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ToolCard(
          icon: torchOn ? Icons.flashlight_on : Icons.flashlight_off,
          title: 'SOS flashlight',
          description:
              'Use the rear torch for visibility. It switches off when you leave this screen.',
          active: torchOn,
          buttonLabel: torchOn ? 'Turn off' : 'Turn on',
          onPressed: busy ? null : () => _invoke('toggleTorch'),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: whistleOn ? Icons.volume_up : Icons.volume_off,
          title: 'Emergency whistle',
          description:
              'Plays a repeating alert tone. Check your volume and stop it as soon as it is no longer needed.',
          active: whistleOn,
          buttonLabel: whistleOn ? 'Stop sound' : 'Play sound',
          onPressed: busy ? null : () => _invoke('toggleWhistle'),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Use responsibly'),
            subtitle: Text(
              'These device tools do not contact responders or confirm that anyone received an SOS.',
            ),
          ),
        ),
      ],
    ),
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.active,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title, description, buttonLabel;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            icon,
            size: 54,
            color: active ? Theme.of(context).colorScheme.error : null,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(description, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    ),
  );
}
