import 'package:flutter/material.dart';

import '../api.dart';

class InputSpec {
  const InputSpec(
    this.keyName,
    this.label, {
    this.required = true,
    this.number = false,
    this.date = false,
    this.lines = 1,
    this.choices,
    this.secret = false,
    this.help,
  });
  final String keyName, label;
  final bool required, number, date, secret;
  final int lines;
  final Map<String, String>? choices;
  final String? help;
}

Future<bool?> showRecordForm(
  BuildContext context, {
  required String title,
  required List<InputSpec> fields,
  Map<String, String> initial = const {},
  required Future<void> Function(Map<String, String>) onSave,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _RecordForm(
    title: title,
    fields: fields,
    initial: initial,
    onSave: onSave,
  ),
);

class _RecordForm extends StatefulWidget {
  const _RecordForm({
    required this.title,
    required this.fields,
    required this.initial,
    required this.onSave,
  });
  final String title;
  final List<InputSpec> fields;
  final Map<String, String> initial;
  final Future<void> Function(Map<String, String>) onSave;
  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> controllers;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    controllers = {
      for (final f in widget.fields)
        f.keyName: TextEditingController(text: widget.initial[f.keyName] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSave(
        controllers.map((k, v) => MapEntry(k, v.text.trim())),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = apiError(e);
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: form,
                    child: Column(
                      children: [
                        for (final f in widget.fields)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: f.choices != null
                                ? DropdownButtonFormField<String>(
                                    initialValue:
                                        controllers[f.keyName]!.text.isEmpty
                                        ? null
                                        : controllers[f.keyName]!.text,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: f.label,
                                      helperText: f.help,
                                    ),
                                    items: f.choices!.entries
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e.key,
                                            child: Text(
                                              e.value,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: busy
                                        ? null
                                        : (v) => controllers[f.keyName]!.text =
                                              v ?? '',
                                    validator: (v) =>
                                        f.required && (v == null || v.isEmpty)
                                        ? 'Choose ${f.label.toLowerCase()}'
                                        : null,
                                  )
                                : TextFormField(
                                    controller: controllers[f.keyName],
                                    enabled: !busy,
                                    maxLines: f.lines,
                                    obscureText: f.secret,
                                    readOnly: f.date,
                                    keyboardType: f.number
                                        ? const TextInputType.numberWithOptions(
                                            decimal: true,
                                            signed: true,
                                          )
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: f.label,
                                      helperText: f.help,
                                      suffixIcon: f.date
                                          ? const Icon(
                                              Icons.calendar_today_outlined,
                                            )
                                          : null,
                                    ),
                                    onTap: !f.date
                                        ? null
                                        : () async {
                                            final value = await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  DateTime.tryParse(
                                                    controllers[f.keyName]!
                                                        .text,
                                                  ) ??
                                                  DateTime.now(),
                                              firstDate: DateTime(1950),
                                              lastDate: DateTime(2100),
                                            );
                                            if (value != null) {
                                              controllers[f.keyName]!.text =
                                                  value
                                                      .toIso8601String()
                                                      .substring(0, 10);
                                            }
                                          },
                                    validator: (v) {
                                      if (f.required &&
                                          (v == null || v.trim().isEmpty)) {
                                        return 'Enter ${f.label.toLowerCase()}';
                                      }
                                      if (f.number &&
                                          v != null &&
                                          v.isNotEmpty &&
                                          double.tryParse(v) == null) {
                                        return 'Enter a number';
                                      }
                                      return null;
                                    },
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: busy ? null : save,
                    child: Text(busy ? 'Saving…' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> confirmDelete(
  BuildContext context,
  String label,
  Future<void> Function() remove,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $label?'),
      content: const Text(
        'This removes the record. Records with linked planting history are kept.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep it'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await remove();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }
}
