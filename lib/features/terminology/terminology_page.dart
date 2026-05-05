library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';

class MusicTerm {
  final String term;
  final String fullName;
  final String explanation;

  const MusicTerm({
    required this.term,
    required this.fullName,
    required this.explanation,
  });

  factory MusicTerm.fromJson(Map<String, dynamic> json) => MusicTerm(
        term: json['term'] as String,
        fullName: json['full_name'] as String,
        explanation: json['explanation'] as String,
      );
}

class TerminologyService {
  static final Map<String, List<MusicTerm>> _cache = {};

  static Future<List<MusicTerm>> _loadTerms(String languageCode) async {
    if (_cache.containsKey(languageCode)) return _cache[languageCode]!;
    try {
      final file = 'assets/data/music_terms_$languageCode.json';
      final raw = await rootBundle.loadString(file);
      final list = jsonDecode(raw) as List;
      if (list.isEmpty) return [];
      _cache[languageCode] = list.map((e) => MusicTerm.fromJson(e)).toList();
      return _cache[languageCode]!;
    } catch (_) {
      return [];
    }
  }

  static Future<List<MusicTerm>> search(
    String query, {
    String languageCode = 'en',
  }) async {
    final terms = await _loadTerms(languageCode);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final exact = terms.where((t) => t.term.toLowerCase() == q).toList();
    if (exact.isNotEmpty) return exact;

    return terms.where((t) =>
      t.term.toLowerCase().contains(q) ||
      t.fullName.toLowerCase().contains(q),
    ).toList();
  }
}

class TerminologySheet extends StatefulWidget {
  const TerminologySheet({super.key});

  @override
  State<TerminologySheet> createState() => _TerminologySheetState();
}

class _TerminologySheetState extends State<TerminologySheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<MusicTerm> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  static const _quickTerms = [
    'ff', 'pp', 'mf', 'mp', 'f', 'p',
    'rit.', 'accel.', 'D.C.', 'D.S.',
    'pizz.', 'arco', 'cresc.', 'dim.',
  ];

  Future<void> _search(String term) async {
    if (term.trim().isEmpty) return;

    // 取得當前 App 語言，讓術語查詢跟隨 UI 語系
    final languageCode = Localizations.localeOf(context).languageCode;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _results = [];
    });

    final results = await TerminologyService.search(
      term,
      languageCode: languageCode,
    );

    // 確認 widget 仍然 mounted 再更新狀態
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.terminologyTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: TextStyle(color: cs.onSurface, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: l.terminologyHint,
                      hintStyle: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) {
                      if (v.isEmpty) {
                        setState(() {
                          _results = [];
                          _hasSearched = false;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              GestureDetector(
                onTap: () => _search(_controller.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Height 36 gives the quick-term chips a more tappable touch target
          // while keeping them visually compact. The GestureDetector + opaque
          // behavior extends the tap region to the full 36px height.
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickTerms.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final term = _quickTerms[index];
                return GestureDetector(
                  onTap: () {
                    _controller.text = term;
                    _search(term);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      term,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_hasSearched && _results.isEmpty)
            Center(
              child: Text(
                l.terminologyNotFound,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              ),
            )
          else if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = _results[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.term,
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // BC-TM3: fullName can be long — Flexible prevents RenderFlex overflow
                            Flexible(
                              child: Text(
                                t.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.explanation,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
