import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/core/l10n/locale_provider.dart';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';

class RulesConfigPage extends ConsumerStatefulWidget {
  const RulesConfigPage({super.key});
  @override
  ConsumerState<RulesConfigPage> createState() => _RulesConfigPageState();
}

class _RulesConfigPageState extends ConsumerState<RulesConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Rule> _rules = [];
  List<OperationLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadRules();
    _loadLogs();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    final r = await ref.read(ruleRepositoryProvider).getAllRules();
    if (mounted) setState(() => _rules = r);
  }

  Future<void> _loadLogs() async {
    final l = await ref.read(operationLogRepositoryProvider).query(limit: 100);
    if (mounted) setState(() => _logs = l);
  }

  Future<void> _delete(Rule r) async {
    final l = ref.read(appStringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.deleteRuleTitle),
        content: Text(
          l.deleteRuleMsg(r.name.isNotEmpty ? r.name : 'Rule ${r.id}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(ruleRepositoryProvider).delete(r.id!);
      await ref
          .read(operationLogRepositoryProvider)
          .log('DELETE_RULE', details: 'id=${r.id} name=${r.name}');
      _loadRules();
      _loadLogs();
    }
  }

  void _openEdit(Rule? r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RuleEditPage(
          existing: r,
          onSaved: () {
            _loadRules();
            _loadLogs();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.rulesTitle),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(icon: const Icon(Icons.rule, size: 18), text: l.tabRules),
            Tab(icon: const Icon(Icons.history, size: 18), text: l.tabOpLogs),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(null),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Rules list ────────────────────────────────────────────────────
          _rules.isEmpty
              ? Center(
                  child: Text(
                    l.noRules,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRules,
                  child: ListView.builder(
                    itemCount: _rules.length,
                    itemBuilder: (ctx, i) {
                      final r = _rules[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            r.name.isNotEmpty ? r.name : 'Rule ${r.id}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.sensorIdFilter ?? '*'} ${r.operator} ${r.threshold}'
                                '  →  ${r.actionType}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${r.deviceAidFilter != null ? 'AID:${r.deviceAidFilter}  ' : ''}'
                                '${l.cooldownDisplay(r.cooldownMs ~/ 1000)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: r.enabled,
                                onChanged: (v) async {
                                  await ref
                                      .read(ruleRepositoryProvider)
                                      .toggleEnabled(r.id!, v);
                                  _loadRules();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _openEdit(r),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                onPressed: () => _delete(r),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

          // ── Operation logs ────────────────────────────────────────────────
          RefreshIndicator(
            onRefresh: _loadLogs,
            child: _logs.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          l.noOpLogs,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (ctx, i) {
                      final log = _logs[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.info,
                        ),
                        title: Text(
                          log.action,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          log.details,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          DateTime.fromMillisecondsSinceEpoch(
                            log.timestampMs,
                          ).toString().substring(0, 19),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Rule edit / create page ───────────────────────────────────────────────────
class RuleEditPage extends ConsumerStatefulWidget {
  final Rule? existing;
  final VoidCallback? onSaved;
  const RuleEditPage({super.key, this.existing, this.onSaved});
  @override
  ConsumerState<RuleEditPage> createState() => _RuleEditPageState();
}

class _RuleEditPageState extends ConsumerState<RuleEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _sensorCtrl;
  late TextEditingController _thresholdCtrl;
  late TextEditingController _deviceAidCtrl;
  late TextEditingController _cooldownCtrl;
  late String _operator;
  late String _actionType;

  // ── send_command structured fields ─────────────────────────────────────────
  String _cmdType = 'PING';
  late TextEditingController _cmdTargetAidCtrl;
  late TextEditingController _cmdCustomCtrl;

  static const _kSendCmds = [
    'PING',
    'PONG',
    'ID_REQUEST',
    'TIME_REQUEST',
    'HANDSHAKE_ACK',
    'HANDSHAKE_NACK',
    'RESET',
    'CUSTOM',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _sensorCtrl = TextEditingController(text: r?.sensorIdFilter ?? '');
    _thresholdCtrl = TextEditingController(
      text: r?.threshold.toString() ?? '50',
    );
    _deviceAidCtrl = TextEditingController(
      text: r?.deviceAidFilter?.toString() ?? '',
    );
    _cooldownCtrl = TextEditingController(
      text: ((r?.cooldownMs ?? 60000) ~/ 1000).toString(),
    );
    _operator = r?.operator ?? '>';
    _actionType = r?.actionType ?? 'create_alert';

    // Parse existing send_command payload
    _cmdTargetAidCtrl = TextEditingController();
    _cmdCustomCtrl = TextEditingController();
    if (r?.actionPayload != null && r!.actionPayload != '{}') {
      try {
        final m = jsonDecode(r.actionPayload) as Map<String, dynamic>;
        _cmdType = (m['cmd'] as String?) ?? 'PING';
        _cmdTargetAidCtrl.text = (m['target_aid'] ?? '').toString();
        _cmdCustomCtrl.text = (m['custom'] as String?) ?? '';
        if (!_kSendCmds.contains(_cmdType)) _cmdType = 'CUSTOM';
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sensorCtrl.dispose();
    _thresholdCtrl.dispose();
    _deviceAidCtrl.dispose();
    _cooldownCtrl.dispose();
    _cmdTargetAidCtrl.dispose();
    _cmdCustomCtrl.dispose();
    super.dispose();
  }

  String _buildPayload() {
    if (_actionType != 'send_command') return '{}';
    final m = <String, dynamic>{'cmd': _cmdType};
    if (_cmdTargetAidCtrl.text.isNotEmpty) {
      m['target_aid'] =
          int.tryParse(_cmdTargetAidCtrl.text) ?? _cmdTargetAidCtrl.text;
    }
    if (_cmdType == 'CUSTOM' && _cmdCustomCtrl.text.isNotEmpty) {
      m['custom'] = _cmdCustomCtrl.text;
    }
    return jsonEncode(m);
  }

  Future<void> _save() async {
    final rule = Rule(
      id: widget.existing?.id,
      name: _nameCtrl.text,
      sensorIdFilter: _sensorCtrl.text.isEmpty ? null : _sensorCtrl.text,
      deviceAidFilter: _deviceAidCtrl.text.isEmpty
          ? null
          : int.tryParse(_deviceAidCtrl.text),
      operator: _operator,
      threshold: double.tryParse(_thresholdCtrl.text) ?? 0,
      actionType: _actionType,
      actionPayload: _buildPayload(),
      cooldownMs: (int.tryParse(_cooldownCtrl.text) ?? 60) * 1000,
      enabled: widget.existing?.enabled ?? true,
    );

    if (rule.id == null) {
      await ref.read(ruleRepositoryProvider).insert(rule);
      await ref
          .read(operationLogRepositoryProvider)
          .log('CREATE_RULE', details: 'name=${rule.name}');
    } else {
      await ref.read(ruleRepositoryProvider).update(rule);
      await ref
          .read(operationLogRepositoryProvider)
          .log('UPDATE_RULE', details: 'id=${rule.id} name=${rule.name}');
    }
    widget.onSaved?.call();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final l = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.editRule : l.newRule),
        actions: [
          FilledButton(onPressed: _save, child: Text(l.save)),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: l.ruleName),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sensorCtrl,
                  decoration: InputDecoration(
                    labelText: l.sensorIdFilter,
                    hintText: l.emptyForAll,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _deviceAidCtrl,
                  decoration: InputDecoration(
                    labelText: l.deviceAidFilter,
                    hintText: l.emptyForAll,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _operator,
                  decoration: InputDecoration(labelText: l.operator_),
                  items: ['>', '<', '>=', '<=', '==', '!=']
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) => setState(() => _operator = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _thresholdCtrl,
                  decoration: InputDecoration(labelText: l.threshold),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _actionType,
            decoration: InputDecoration(labelText: l.triggerAction),
            items: [
              DropdownMenuItem(
                value: 'create_alert',
                child: Text(l.actionCreateAlert),
              ),
              DropdownMenuItem(
                value: 'send_command',
                child: Text(l.actionSendCommand),
              ),
              DropdownMenuItem(value: 'log_only', child: Text(l.actionLogOnly)),
            ],
            onChanged: (v) => setState(() => _actionType = v!),
          ),
          const SizedBox(height: 12),

          if (_actionType == 'send_command') ...[
            DropdownButtonFormField<String>(
              initialValue: _cmdType,
              decoration: const InputDecoration(
                labelText: 'OpenSynaptic CMD',
                prefixIcon: Icon(Icons.settings_remote, size: 18),
              ),
              items: _kSendCmds
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _cmdType = v!),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cmdTargetAidCtrl,
              decoration: InputDecoration(
                labelText: l.targetAidLabel,
                prefixIcon: const Icon(Icons.memory, size: 18),
              ),
              keyboardType: TextInputType.number,
            ),
            if (_cmdType == 'CUSTOM') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _cmdCustomCtrl,
                decoration: InputDecoration(
                  labelText: l.customCmdLabel,
                  hintText: 'hex: 09 00 01',
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              l.generatedPayload(_buildPayload()),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cooldownCtrl,
                  decoration: InputDecoration(
                    labelText: l.cooldownLabel,
                    hintText: '60',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            l.rulesHelpText,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
