import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../models/category.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/theme_rebuilder.dart';
import '../../widgets/empty_state.dart';
import '../../utils/friendly_error.dart';
import '../../widgets/category_icon.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _app = AppState.instance;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _app.loadCategories();
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({MoneyCategory? existing}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CategoryEditorSheet(existing: existing),
    );
    await _reload();
  }

  Future<void> _delete(MoneyCategory c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('حذف دسته «${c.label}»؟'),
        content:
            const Text('تراکنش‌های ثبت‌شده با این دسته، بدون دسته می‌مانند.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: AppColors.magenta)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        await DataService.instance.deleteCategory(c.id);
        await _app.loadCategories();
      } catch (error) {
        if (mounted) setState(() => _error = friendlyError(error));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeRebuilder(
        builder: (context) => Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(
                title: const Text('دسته‌ها'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _openEditor(),
                  ),
                ],
              ),
              body: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.cyan))
                  : _error != null
                      ? _CategoriesError(message: _error!, onRetry: _reload)
                      : _app.categories.isEmpty
                          ? const EmptyState(
                              icon: Icons.category_outlined,
                              title: 'هنوز دسته‌ای ثبت نشده',
                              subtitle:
                                  'برای ساخت دستهٔ جدید دکمهٔ افزودن را بزن.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _app.categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final c = _app.categories[i];
                                final color = AppTheme.categoryColor(c.color);
                                return Container(
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                      colors: [
                                        color.withValues(alpha: 0.028),
                                        AppColors.cardBg,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: color.withValues(alpha: 0.15)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.025),
                                        blurRadius: 18,
                                        offset: const Offset(0, 7),
                                      ),
                                    ],
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                          gradient: RadialGradient(colors: [
                                            color.withValues(alpha: 0.24),
                                            color.withValues(alpha: 0.08),
                                          ]),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                              color: color.withValues(
                                                  alpha: 0.26))),
                                      alignment: Alignment.center,
                                      child: CategoryIcon(
                                          value: c.icon,
                                          color: color,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(c.label,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          if (c.budget != null)
                                            Text('سقف: ${c.budget}',
                                                style: TextStyle(
                                                    color: AppColors.muted,
                                                    fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'ویرایش ${c.label}',
                                      icon: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBgAlt,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.edit_rounded,
                                            size: 16, color: AppColors.muted),
                                      ),
                                      onPressed: () => _openEditor(existing: c),
                                    ),
                                    if (!c.isDefault)
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            size: 18, color: AppColors.magenta),
                                        onPressed: () => _delete(c),
                                      ),
                                  ]),
                                );
                              },
                            ),
            ));
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  final MoneyCategory? existing;
  const _CategoryEditorSheet({this.existing});

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late String _iconKey = resolveCategoryIcon(widget.existing?.icon).key;
  late String _color = widget.existing?.color ?? categoryColorChoices.first;
  int? _budget;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _budget = widget.existing?.budget?.round();
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) {
      setState(() => _error = 'نام دسته را وارد کن');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.existing != null) {
        await DataService.instance.updateCategory(
          widget.existing!.id,
          label: _label.text.trim(),
          icon: _iconKey,
          color: _color,
          budget: _budget,
        );
      } else {
        final id =
            _label.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
        await DataService.instance.createCategory(
          id: id,
          label: _label.text.trim(),
          icon: _iconKey,
          color: _color,
          budget: _budget,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.existing != null ? 'ویرایش دسته' : 'دسته جدید',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                  controller: _label,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'نام دسته')),
              const SizedBox(height: 16),
              _CategoryPreview(
                label: _label.text.trim(),
                iconKey: _iconKey,
                colorHex: _color,
              ),
              const SizedBox(height: 18),
              Align(
                  alignment: Alignment.centerRight,
                  child: Text('آیکون',
                      style: TextStyle(color: AppColors.muted, fontSize: 13))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: categoryIconChoices.map((choice) {
                      final selected = choice.key == _iconKey;
                      final selectedColor = AppTheme.categoryColor(_color);
                      return Semantics(
                        label: choice.label,
                        selected: selected,
                        button: true,
                        child: GestureDetector(
                          onTap: () => setState(() => _iconKey = choice.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: selected
                                  ? selectedColor.withValues(alpha: 0.18)
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selected
                                      ? selectedColor
                                      : AppColors.divider,
                                  width: selected ? 1.5 : 1),
                            ),
                            alignment: Alignment.center,
                            child: Icon(choice.icon,
                                size: 20,
                                color:
                                    selected ? selectedColor : AppColors.muted),
                          ),
                        ),
                      );
                    }).toList()),
              ),
              const SizedBox(height: 16),
              Align(
                  alignment: Alignment.centerRight,
                  child: Text('رنگ',
                      style: TextStyle(color: AppColors.muted, fontSize: 13))),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categoryColorChoices.map((hex) {
                    final color = AppTheme.categoryColor(hex);
                    final selected = hex == _color;
                    return GestureDetector(
                      onTap: () => setState(() => _color = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: selected ? 38 : 34,
                        height: selected ? 38 : 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  selected ? Colors.white : Colors.transparent,
                              width: 2),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                  )
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                size: 17, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList()),
              const SizedBox(height: 16),
              AmountField(
                label: 'سقف بودجه (اختیاری)',
                initialValue: _budget,
                onChanged: (v) => _budget = v,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: TextStyle(color: AppColors.magenta, fontSize: 12.5)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.bg))
                    : const Text('ذخیره'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  final String label;
  final String iconKey;
  final String colorHex;

  const _CategoryPreview({
    required this.label,
    required this.iconKey,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(colorHex);
    return Container(
      key: const Key('category-live-preview'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.13),
          AppColors.cardBgAlt.withValues(alpha: 0.45),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: CategoryIcon(value: iconKey, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label.isEmpty ? 'پیش‌نمایش دسته' : label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Icon(Icons.auto_awesome_rounded, size: 17, color: color),
      ]),
    );
  }
}

class _CategoriesError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CategoriesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('تلاش دوباره')),
          ],
        ),
      );
}
