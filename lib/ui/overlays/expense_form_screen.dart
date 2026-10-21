import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/expense_form.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/text.dart';
import '../../utils/dates.dart';
import '../../utils/format.dart';
import '../widgets/activity.dart';
import '../widgets/basics.dart';
import '../widgets/pressable.dart';

/// Full-screen form to add an expense, edit one, or adjust an AI proposal.
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  late final ExpenseFormData _initial;
  late final TextEditingController _amount;
  late final TextEditingController _desc;
  late final TextEditingController _note;

  /// Keeps the last form so the screen can animate out after saving.
  ExpenseFormData? _last;

  @override
  void initState() {
    super.initState();
    _initial = context.read<AppState>().form!;
    _amount = TextEditingController(text: _initial.amount);
    _desc = TextEditingController(text: _initial.desc);
    _note = TextEditingController(text: _initial.note);
  }

  @override
  void dispose() {
    _amount.dispose();
    _desc.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final f = state.form ?? _last ?? _initial;
    _last = f;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final footerBottom = keyboard > 0 ? 12.0 : math.max(20.0, media.padding.bottom);

    final title = switch (f.mode) {
      FormMode.create => 'Add expense',
      FormMode.edit => 'Edit expense',
      FormMode.ai => 'Edit details',
    };
    final saveLabel = f.saving
        ? 'Saving…'
        : switch (f.mode) {
            FormMode.create => 'Save expense',
            FormMode.edit => 'Save changes',
            FormMode.ai => 'Update details',
          };

    final today = state.today;
    final dates = <(DateTime, String)>[
      (today, 'Today'),
      (addDays(today, -1), 'Yesterday'),
    ];
    if (!dates.any((d) => isSameDay(d.$1, f.date))) {
      dates.add((f.date, dayLabel(f.date, today: today)));
    } else {
      final d = addDays(today, -3);
      dates.add((d, dayLabel(d, today: today)));
    }

    return Material(
      color: AppColors.bgBase,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: LucideIcons.x,
                      iconSize: 18,
                      label: 'Close',
                      onTap: f.saving ? null : state.closeForm,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: AppText.style(19, weight: 600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (f.mode == FormMode.ai) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.tintStrong,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(LucideIcons.sparkles, size: 16, color: AppColors.deep),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Prepared by Ask SpendWise. Fix anything that’s wrong, then confirm it in the chat.',
                              style: AppText.style(13.5, color: AppColors.deep, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _AmountField(controller: _amount, error: f.amountError, onChanged: (v) => state.updateForm(amount: v)),
                  const SizedBox(height: 22),
                  const SectionLabel('Description'),
                  const SizedBox(height: 8),
                  _BoxedField(
                    controller: _desc,
                    hint: 'e.g. Lunch, Bolt ride',
                    hasError: f.descError != null,
                    onChanged: (v) => state.updateForm(desc: v),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (f.descError != null) ...[const SizedBox(height: 8), FieldError(f.descError!)],
                  const SizedBox(height: 22),
                  const SectionLabel('Category'),
                  const SizedBox(height: 8),
                  _CategoryGrid(selected: f.category, onSelect: (c) => state.updateForm(category: c)),
                  const SizedBox(height: 22),
                  const SectionLabel('Date'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (d, label) in dates)
                        AppChip(
                          label: label,
                          selected: isSameDay(d, f.date),
                          height: 40,
                          fontSize: 14,
                          horizontalPadding: 14,
                          onTap: () => state.updateForm(date: d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text.rich(
                    TextSpan(
                      text: 'Note',
                      style: AppText.style(13, weight: 600, color: AppColors.ink2),
                      children: [
                        TextSpan(text: ' · optional', style: AppText.style(13, color: AppColors.ink4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BoxedField(
                    controller: _note,
                    hint: 'Add a note',
                    minLines: 3,
                    onChanged: (v) => state.updateForm(note: v),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, footerBottom),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderCard))),
              child: AppButton(
                label: saveLabel,
                leading: f.saving ? const Spinner() : null,
                height: 56,
                radius: 18,
                fontSize: 16,
                gap: 10,
                onTap: f.saving
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        state.saveForm();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.error, required this.onChanged});

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Amount'),
        Container(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: error != null ? AppColors.destructive : AppColors.primary, width: 2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₦', style: AppText.style(32, weight: 600, width: 125, color: AppColors.ink4)),
              const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: 'Amount in naira',
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    style: AppText.style(40, weight: 600, width: 125, tracking: -0.02, tabular: true),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: AppText.style(40, weight: 600, width: 125, color: AppColors.ink6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[const SizedBox(height: 8), FieldError(error!)],
      ],
    );
  }
}

class _BoxedField extends StatelessWidget {
  const _BoxedField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.hasError = false,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool hasError;
  final int? minLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final multiline = minLines != null;
    return Container(
      constraints: BoxConstraints(minHeight: multiline ? 0 : 52),
      alignment: multiline ? null : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: multiline ? 14 : 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasError ? AppColors.destructive : AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        minLines: minLines,
        maxLines: multiline ? 6 : 1,
        textCapitalization: textCapitalization,
        style: AppText.style(15, height: multiline ? 1.4 : null),
        decoration: InputDecoration(hintText: hint, hintStyle: AppText.style(15, color: AppColors.ink6)),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelect});

  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0;
        final w = (box.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in ExpenseCategory.values)
              Semantics(
                selected: c == selected,
                child: Pressable(
                  onTap: () => onSelect(c),
                  width: w,
                  height: 66,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: c == selected ? AppColors.tintStrong : AppColors.white,
                  pressedColor: AppColors.tint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c == selected ? AppColors.primary : AppColors.borderSoft, width: 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(c.icon, size: 18, color: AppColors.primary),
                      const SizedBox(height: 6),
                      Text(c.label, maxLines: 1, style: AppText.style(13.5, weight: 500)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
