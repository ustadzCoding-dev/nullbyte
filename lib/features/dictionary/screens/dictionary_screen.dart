import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class _DictionaryEntry {
  const _DictionaryEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final String category;

  factory _DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return _DictionaryEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'GENERAL',
    );
  }
}

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<_DictionaryEntry> _entries = const [];
  List<_DictionaryEntry> _filtered = const [];
  String _activeCategory = 'ALL';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilters);
    _loadEntries();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilters);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final raw = await rootBundle.loadString('assets/data/dictionary.json');
    final decoded = json.decode(raw) as List<dynamic>;
    final loaded = decoded
        .map((entry) => _DictionaryEntry.fromJson(entry as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (!mounted) {
      return;
    }

    setState(() {
      _entries = loaded;
      _filtered = loaded;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _entries.where((entry) {
      final matchesCategory =
          _activeCategory == 'ALL' || entry.category == _activeCategory;
      final matchesQuery =
          query.isEmpty ||
          entry.name.toLowerCase().contains(query) ||
          entry.description.toLowerCase().contains(query) ||
          entry.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    setState(() {
      _filtered = filtered;
    });
  }

  List<String> get _categories {
    final categories = _entries.map((entry) => entry.category).toSet().toList()
      ..sort();
    return ['ALL', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: AppTheme.surfaceContainerHigh),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.signal_cellular_alt,
                color: AppTheme.primaryContainer,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'MISSION_DICTIONARY',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.primaryContainer,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Color(0x8000FF41), blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryContainer,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSearch(),
                    const SizedBox(height: 12),
                    _buildCategoryChips(),
                    const SizedBox(height: 16),
                    _buildSummary(),
                    const SizedBox(height: 16),
                    _buildEntries(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppTheme.surfaceContainerLow,
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TACTICAL GLOSSARY',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: AppTheme.primaryContainer,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Istilah di layar ini diambil dari data internal NULLBYTE dan dipakai untuk membantu pemain memahami command path, teknik, dan konteks dunia nyata di setiap mission.',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
        color: AppTheme.onSurface,
      ),
      decoration: const InputDecoration(
        filled: true,
        fillColor: AppTheme.surfaceContainerLow,
        hintText: 'Cari istilah seperti nmap, sql injection, reverse shell',
        hintStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          color: AppTheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(Icons.search, color: AppTheme.primaryContainer),
        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.surfaceContainerHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.primaryContainer),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isActive = category == _activeCategory;
        return GestureDetector(
          onTap: () {
            setState(() {
              _activeCategory = category;
            });
            _applyFilters();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: isActive
                ? AppTheme.primaryContainer
                : AppTheme.surfaceContainerHigh,
            child: Text(
              category,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: isActive ? AppTheme.onPrimary : AppTheme.onSurface,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      color: AppTheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(16),
      child: Text(
        '${_filtered.length} istilah aktif ditampilkan. Gunakan glossary ini sebagai referensi cepat saat Anda menemui objective, hint, atau debrief mission yang memakai istilah teknis.',
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 11,
          color: AppTheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildEntries() {
    if (_filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: AppTheme.surfaceContainerLow,
        child: const Text(
          'Tidak ada istilah yang cocok dengan filter saat ini.',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: _filtered.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: double.infinity,
            color: AppTheme.surfaceContainerLow,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.name.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: AppTheme.surfaceContainerHigh,
                      child: Text(
                        entry.category,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          color: AppTheme.primaryContainer,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.id,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
