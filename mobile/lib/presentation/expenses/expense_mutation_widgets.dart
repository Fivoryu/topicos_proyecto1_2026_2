import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/read_models/read_models.dart';
import '../../domain/write_models/write_models.dart';
import 'expense_mutation_cubit.dart';
import 'expense_participant_selection.dart';

typedef _S = ExpenseMutationState;
typedef _O = ExpenseParticipantOption;
typedef _C = TextEditingController;

const _style = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
);

class ExpenseWriteForm extends StatefulWidget {
  const ExpenseWriteForm({
    required this.cubit,
    required this.participants,
    this.expense,
    this.onCancel,
    super.key,
  });

  final ExpenseMutationCubit cubit;
  final Iterable<ExpenseParticipantOption> participants;
  final ExpenseReadModel? expense;
  final VoidCallback? onCancel;

  @override
  State<ExpenseWriteForm> createState() => _ExpenseWriteFormState();
}

class _ContributorFields {
  _ContributorFields([this.id, String text = '']) : amount = _C(text: text);

  String? id;
  final _C amount;
  void dispose() => amount.dispose();
}

class _ExpenseWriteFormState extends State<ExpenseWriteForm> {
  final _key = GlobalKey<FormState>();
  late final _C _description, _amount;
  late final List<_O> _options;
  late final List<_ContributorFields> _contributors;
  late final Set<String> _beneficiaries;
  bool _groupErrorShown = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _options = List.unmodifiable(widget.participants);
    _description = _C(text: e?.description ?? '');
    _amount = _C(text: e == null ? '' : _cents(e.amountCents));
    _contributors = e == null
        ? []
        : e.contributors
              .map(
                (c) =>
                    _ContributorFields(c.participantId, _cents(c.amountCents)),
              )
              .toList();
    if (e == null && _options.isNotEmpty) {
      _contributors.add(_ContributorFields(_options.first.id));
    }
    _beneficiaries = e == null
        ? _options.map((o) => o.id).toSet()
        : e.beneficiaries.map((b) => b.participantId).toSet();
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    for (final contributor in _contributors) {
      contributor.dispose();
    }
    super.dispose();
  }

  void _change(VoidCallback change) {
    setState(() {
      change();
      _groupErrorShown = false;
    });
  }

  void _add() => _change(() => _contributors.add(_ContributorFields()));
  void _remove(int i) => _change(() => _contributors.removeAt(i).dispose());
  void _select(int i, String? id) => _change(() => _contributors[i].id = id);
  void _toggle(String id, bool selected) => _change(() {
    (selected ? _beneficiaries.add : _beneficiaries.remove)(id);
  });

  void _submit() {
    final valid = _key.currentState?.validate() ?? false;
    if (!valid || _contributors.isEmpty || _beneficiaries.isEmpty) {
      setState(() => _groupErrorShown = true);
      return;
    }
    final draft = ExpenseWriteDraft(
      description: _description.text,
      amount: ExpenseAmount.parse(_amount.text),
      contributors: _contributors.map(_draft).toList(),
      beneficiaryIds: _beneficiaries.toList(),
    );
    final e = widget.expense;
    unawaited(
      e == null ? widget.cubit.create(draft) : widget.cubit.edit(e.id, draft),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<_S>(
    stream: widget.cubit.stream,
    initialData: widget.cubit.state,
    builder: (context, snapshot) => Form(
      key: _key,
      child: SingleChildScrollView(
        child: _content(context, snapshot.data ?? widget.cubit.state),
      ),
    ),
  );

  Widget _content(BuildContext context, _S state) {
    final editing = widget.expense != null;
    final disabled = state.isDisabled;
    final add = disabled || _options.isEmpty ? null : _add;
    final submit = disabled ? null : _submit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(editing ? 'Edit expense' : 'Add expense'),
        _field(_description, 'Description', 'description', state),
        _field(_amount, 'Contract amount', 'amount', state, true),
        const Text('Contributors'),
        for (var i = 0; i < _contributors.length; i++) _row(i, state),
        if (_groupErrorShown && _contributors.isEmpty)
          _error('Add at least one contributor.'),
        _button('Add contributor', add, true),
        const Text('Beneficiaries'),
        if (_options.isEmpty)
          const Text('No participants are available.')
        else
          for (final option in _options) _beneficiary(option, state),
        if (_groupErrorShown && _beneficiaries.isEmpty)
          _error('Select at least one beneficiary.'),
        if (state.failure case final failure?) _error(failure.message),
        if (state.successMessage case final message?)
          Semantics(liveRegion: true, child: Text(message)),
        _button(
          editing ? 'Save changes' : 'Add expense',
          submit,
          false,
          state.isLoading,
        ),
        if (widget.onCancel != null)
          _button('Cancel', disabled ? null : widget.onCancel, true),
      ],
    );
  }

  Widget _row(int i, _S state) => Column(
    children: [
      _dropdown(i, state),
      _field(
        _contributors[i].amount,
        'Contributor ${i + 1} contribution amount',
        'contributors[$i].amount',
        state,
        true,
      ),
      _button(
        'Remove contributor',
        state.isDisabled ? null : () => _remove(i),
        true,
      ),
    ],
  );

  Widget _dropdown(int i, _S state) {
    final c = _contributors[i];
    final selected = _options.any((o) => o.id == c.id) ? c.id : null;
    final key = 'contributors[$i].participantId';
    return DropdownButtonFormField<String>(
      initialValue: selected,
      items: _options
          .map((o) => DropdownMenuItem(value: o.id, child: Text(o.name)))
          .toList(),
      onChanged: state.isDisabled ? null : (id) => _select(i, id),
      validator: _required,
      decoration: _dec(
        'Contributor ${i + 1} participant',
        state.failure?.fieldErrors[key],
      ),
    );
  }

  Widget _beneficiary(_O o, _S state) => CheckboxListTile(
    value: _beneficiaries.contains(o.id),
    onChanged: state.isDisabled ? null : (v) => _toggle(o.id, v == true),
    title: Text(o.name),
  );

  Widget _field(_C c, String l, String k, _S s, [bool amount = false]) =>
      TextFormField(
        controller: c,
        enabled: !s.isDisabled,
        keyboardType: amount
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        validator: (value) => _localError(value, k),
        decoration: _dec(l, s.failure?.fieldErrors[k]),
      );

  Widget _button(
    String label,
    VoidCallback? action, [
    bool outlined = false,
    bool loading = false,
  ]) {
    final child = _buttonChild(label, loading);
    if (outlined) {
      return OutlinedButton(onPressed: action, style: _style, child: child);
    }
    return ElevatedButton(onPressed: action, style: _style, child: child);
  }
}

ExpenseContributorDraft _draft(_ContributorFields c) => ExpenseContributorDraft(
  participantId: c.id!,
  amount: ExpenseAmount.parse(c.amount.text),
);

Widget _buttonChild(String label, bool loading) =>
    loading ? const CircularProgressIndicator(strokeWidth: 2) : Text(label);

InputDecoration _dec(String label, String? error) =>
    InputDecoration(labelText: label, errorText: error);

String? _localError(String? value, String key) {
  if (key == 'description') {
    return value == null || value.trim().isEmpty
        ? 'Enter a description.'
        : null;
  }
  try {
    ExpenseAmount.parse(value ?? '');
    return null;
  } on FormatException {
    final blank = (value ?? '').isEmpty;
    if (key == 'amount') {
      return blank ? 'Enter an amount.' : 'Enter a valid positive amount.';
    }
    return blank
        ? 'Enter a contribution amount.'
        : 'Enter a valid positive contribution.';
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Select a contributor.' : null;

Widget _error(String text) =>
    Semantics(liveRegion: true, container: true, child: Text(text));

String _cents(int value) =>
    '${value < 0 ? '-' : ''}${value.abs() ~/ 100}.${(value.abs() % 100).toString().padLeft(2, '0')}';
