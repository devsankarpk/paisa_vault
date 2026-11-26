import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../transactions/providers.dart';
import 'providers.dart';
import 'category_repository.dart';

/// Add, rename and hide categories. Income and Transfer are fixed.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  String? _message(CategoryResult r) => switch (r) {
    CategoryResult.ok => null,
    CategoryResult.empty => 'Enter a name',
    CategoryResult.exists => 'That category already exists',
    CategoryResult.fixed => 'This one is fixed and cannot be changed',
    CategoryResult.notFound => 'Category not found',
  };

  Future<void> _ask(
    BuildContext context,
    WidgetRef ref, {
    Category? existing,
  }) async {
    final repo = await ref.read(categoryRepositoryProvider.future);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _NameDialog(
        title: existing == null ? 'Add category' : 'Rename category',
        initial: existing?.name ?? '',
        save: (name) async {
          final r = existing == null
              ? await repo.add(name)
              : await repo.rename(existing.name, name);
          // The model is told the category list when it starts, so refresh it.
          ref.invalidate(processingServiceProvider);
          return r;
        },
        message: _message,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(allCategoriesProvider).asData?.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: PvColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ask(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Hiding a category keeps it on old transactions but stops offering it for new ones.',
              style: TextStyle(color: PvColors.muted, height: 1.4),
            ),
          ),
          for (final c in list)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                title: Text(
                  c.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.hidden ? PvColors.muted : PvColors.ink,
                  ),
                ),
                subtitle: c.kind == CategoryKind.expense
                    ? (c.hidden ? const Text('Hidden') : null)
                    : const Text('Fixed'),
                trailing: c.kind == CategoryKind.expense
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _ask(context, ref, existing: c),
                          ),
                          IconButton(
                            tooltip: c.hidden ? 'Show' : 'Hide',
                            icon: Icon(
                              c.hidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () async {
                              final repo = await ref.read(
                                categoryRepositoryProvider.future,
                              );
                              await repo.setHidden(c.name, !c.hidden);
                              ref.invalidate(processingServiceProvider);
                            },
                          ),
                        ],
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initial,
    required this.save,
    required this.message,
  });
  final String title;
  final String initial;
  final Future<CategoryResult> Function(String) save;
  final String? Function(CategoryResult) message;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _name = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final r = await widget.save(_name.text);
    if (!mounted) return;
    final msg = widget.message(r);
    if (msg == null) {
      Navigator.pop(context);
    } else {
      setState(() => _error = msg);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _name,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: 'Name', errorText: _error),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _submit, child: const Text('Save')),
    ],
  );
}
