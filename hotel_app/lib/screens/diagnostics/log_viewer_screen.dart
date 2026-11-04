import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_logger.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSyncing = false;
  final Set<String> _expandedIds = {};

  final List<String> _filters = [
    'ALL',
    'ERRORS',
    'WARNINGS',
    'AUTH',
    'STORAGE',
    'BOOKINGS',
    'ANALYTICS',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> _getFilteredLogs() {
    final all = AppLogger.logs;
    return all.where((log) {
      // 1. Level / Category Filter
      if (_selectedFilter == 'ERRORS' && log.level != LogLevel.error) return false;
      if (_selectedFilter == 'WARNINGS' && log.level != LogLevel.warn) return false;
      if (_selectedFilter == 'ANALYTICS' && log.level != LogLevel.analytics) return false;
      if (_selectedFilter == 'AUTH' && log.category != 'AUTH') return false;
      if (_selectedFilter == 'STORAGE' && log.category != 'STORAGE') return false;
      if (_selectedFilter == 'BOOKINGS' && log.category != 'BOOKINGS') return false;

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesEvent = log.event.toLowerCase().contains(q);
        final matchesCat = log.category.toLowerCase().contains(q);
        final matchesErr = log.error?.toLowerCase().contains(q) ?? false;
        final matchesDetails = log.details != null && jsonEncode(log.details).toLowerCase().contains(q);
        if (!matchesEvent && !matchesCat && !matchesErr && !matchesDetails) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _syncLogsToCloud() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSyncing = true);
    final count = await AppLogger.flushNow();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Color(0xFF00E599), size: 18),
              const SizedBox(width: 8),
              Text(
                count > 0 ? '$count diagnostic log(s) synced to Supabase!' : 'All diagnostic logs already in cloud.',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _copyAllLogs() {
    HapticFeedback.selectionClick();
    final text = AppLogger.exportAsText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All diagnostic logs copied to clipboard!'),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear In-Memory Logs?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text('This will reset the local diagnostic buffer. Supabase cloud logs remain unaffected.', style: TextStyle(fontSize: 12.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear Buffer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      AppLogger.clear();
      setState(() {});
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Color(0xFFDC2626);
      case LogLevel.warn:
        return const Color(0xFFD97706);
      case LogLevel.analytics:
        return const Color(0xFF2563EB);
      case LogLevel.info:
        return const Color(0xFF059669);
    }
  }

  Color _getLevelBgColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Color(0xFFFEF2F2);
      case LogLevel.warn:
        return const Color(0xFFFFFBEB);
      case LogLevel.analytics:
        return const Color(0xFFEFF6FF);
      case LogLevel.info:
        return const Color(0xFFECFDF5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredLogs();
    final errorCount = AppLogger.logs.where((l) => l.level == LogLevel.error).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostic Logs & Telemetry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Live Operations & Supabase Cloud Logger',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Logs to Supabase',
            icon: _isSyncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_rounded, color: Color(0xFF059669), size: 20),
            onPressed: _isSyncing ? null : _syncLogsToCloud,
          ),
          IconButton(
            tooltip: 'Copy All Logs',
            icon: const Icon(Icons.copy_all_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: _copyAllLogs,
          ),
          IconButton(
            tooltip: 'Clear Buffer',
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
            onPressed: _clearLogs,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats & Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${AppLogger.logs.length} Total Logs',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (errorCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            '$errorCount Errors Caught',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFFDC2626)),
                          ),
                        ),
                      const Spacer(),
                      const Row(
                        children: [
                          Icon(Icons.sync_rounded, size: 12, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Auto-synced to Supabase',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Filter by event, error, or keyword...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.4)),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Filter Chips
            Container(
              height: 44,
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemCount: _filters.length,
                itemBuilder: (context, idx) {
                  final f = _filters[idx];
                  final isSelected = _selectedFilter == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilter = f);
                    },
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Log List View
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No logs match current filter',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'New operations will stream here in real time.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        final isExpanded = _expandedIds.contains(entry.id);
                        final levelColor = _getLevelColor(entry.level);
                        final levelBg = _getLevelBgColor(entry.level);

                        final timeStr =
                            '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}.${entry.timestamp.millisecond.toString().padLeft(3, '0')}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: entry.level == LogLevel.error ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                              width: entry.level == LogLevel.error ? 1.2 : 1.0,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Color(0x040F172A), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedIds.remove(entry.id);
                                } else {
                                  _expandedIds.add(entry.id);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: levelBg,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: levelColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          entry.level.name.toUpperCase(),
                                          style: TextStyle(
                                            color: levelColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          entry.category,
                                          style: const TextStyle(
                                            color: Color(0xFF475569),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                        size: 16,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    entry.event,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (entry.error != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Error: ${entry.error}',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                  if (isExpanded) ...[
                                    const SizedBox(height: 8),
                                    const Divider(color: Color(0xFFE2E8F0)),
                                    if (entry.details != null && entry.details!.isNotEmpty) ...[
                                      const Text('Payload Details:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                                      const SizedBox(height: 3),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: SelectableText(
                                          const JsonEncoder.withIndent('  ').convert(entry.details),
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                    ],
                                    if (entry.stackTrace != null) ...[
                                      const SizedBox(height: 6),
                                      const Text('Stack Trace:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                                      const SizedBox(height: 3),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: SelectableText(
                                          entry.stackTrace!,
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: Color(0xFF991B1B)),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'ID: ${entry.id} · Synced: ${entry.synced}',
                                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                          icon: const Icon(Icons.copy_rounded, size: 12),
                                          label: const Text('Copy Entry', style: TextStyle(fontSize: 10)),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: entry.toFormattedString()));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Log entry copied!'), duration: Duration(seconds: 1)),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
