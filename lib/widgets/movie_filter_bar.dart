import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movie_provider.dart';
import '../services/movie_filter_service.dart';

class MovieFilterBar extends StatefulWidget {
  const MovieFilterBar({super.key});

  @override
  State<MovieFilterBar> createState() => _MovieFilterBarState();
}

class _MovieFilterBarState extends State<MovieFilterBar> {
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _yearFromController = TextEditingController();
  final TextEditingController _yearToController = TextEditingController();
  final TextEditingController _durationMinController = TextEditingController();
  final TextEditingController _durationMaxController = TextEditingController();

  late MovieProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<MovieProvider>();
    _provider.addListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllers(_provider.currentFilters);
    });
  }

  @override
  void didUpdateWidget(MovieFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllers(_provider.currentFilters);
    });
  }

  void _onProviderChanged() {
    setState(() {});
  }

  void _updateControllers(MovieFilters filters) {
    _searchController.text = filters.titleSearch ?? '';
    _yearFromController.text = filters.releaseYearFrom?.year.toString() ?? '';
    _yearToController.text = filters.releaseYearTo?.year.toString() ?? '';
    _durationMinController.text = filters.durationMin?.inMinutes.toString() ?? '';
    _durationMaxController.text = filters.durationMax?.inMinutes.toString() ?? '';
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    _durationMinController.dispose();
    _durationMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        final filters = movieProvider.currentFilters;

        return Container(
          color: const Color(0xFF1A1A1A),
          child: Column(
            children: [
              // Collapsed filter bar
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Color(0xFF00FF7F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: filters.hasActiveFilters
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _buildActiveFilterChips(filters),
                                ),
                              )
                            : const Text(
                                'Tap to filter movies',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF00FF7F),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded filter options (capped height)
              if (_isExpanded)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search bar
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search movies...',
                                    hintStyle: const TextStyle(color: Colors.white54),
                                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF7F)),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, color: Colors.white54),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                              });
                                              _applyFilters(titleSearch: null);
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // Debounce search
                                    Future.delayed(const Duration(milliseconds: 500), () {
                                      if (mounted && _searchController.text == value) {
                                        _applyFilters(titleSearch: value.isEmpty ? null : value);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_searchController.text.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                    _applyFilters(titleSearch: null);
                                  },
                                  icon: const Icon(Icons.list, size: 18),
                                  label: const Text('Show All'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF00FF7F),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Status filter
                          _buildMultiSelectFilter(
                            'Status',
                            MovieFilterService.statuses,
                            filters.statuses ?? [],
                            (selected) => _applyFilters(statuses: selected.isEmpty ? null : selected),
                          ),

                          // Language filter
                          _buildMultiSelectFilter(
                            'Language',
                            MovieFilterService.languages,
                            filters.languages ?? [],
                            (selected) => _applyFilters(languages: selected.isEmpty ? null : selected),
                          ),

                          // Maturity rating filter
                          _buildMultiSelectFilter(
                            'Maturity Rating',
                            MovieFilterService.maturityRatings,
                            filters.maturityRatings ?? [],
                            (selected) => _applyFilters(maturityRatings: selected.isEmpty ? null : selected),
                          ),

                          // Release year range
                          _buildYearRangeFilter(filters),

                          // Duration range
                          _buildDurationRangeFilter(filters),

                          // Sort options
                          _buildSortOptions(filters),

                          // Action buttons
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => movieProvider.clearFilters(),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white54),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Clear All'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => setState(() => _isExpanded = false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00FF7F),
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildActiveFilterChips(MovieFilters filters) {
    final chips = <Widget>[];

    if (filters.titleSearch?.isNotEmpty ?? false) {
      chips.add(
        ActionChip(
          label: Text('Search: "${filters.titleSearch}"', style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: const Color(0xFF00FF7F).withOpacity(0.2),
          onPressed: () => _applyFilters(titleSearch: null),
        ),
      );
    }

    if (filters.statuses?.isNotEmpty ?? false) {
      for (final status in filters.statuses!) {
        chips.add(
          ActionChip(
            label: Text('Status: $status', style: const TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color(0xFF00FF7F).withOpacity(0.2),
            onPressed: () {
              final newStatuses = filters.statuses!.where((s) => s != status).toList();
              _applyFilters(statuses: newStatuses.isEmpty ? null : newStatuses);
            },
          ),
        );
      }
    }

    if (filters.languages?.isNotEmpty ?? false) {
      for (final language in filters.languages!) {
        chips.add(
          ActionChip(
            label: Text('Language: $language', style: const TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color(0xFF00FF7F).withOpacity(0.2),
            onPressed: () {
              final newLanguages = filters.languages!.where((l) => l != language).toList();
              _applyFilters(languages: newLanguages.isEmpty ? null : newLanguages);
            },
          ),
        );
      }
    }

    if (filters.maturityRatings?.isNotEmpty ?? false) {
      for (final rating in filters.maturityRatings!) {
        chips.add(
          ActionChip(
            label: Text('Rating: $rating', style: const TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color(0xFF00FF7F).withOpacity(0.2),
            onPressed: () {
              final newRatings = filters.maturityRatings!.where((r) => r != rating).toList();
              _applyFilters(maturityRatings: newRatings.isEmpty ? null : newRatings);
            },
          ),
        );
      }
    }

    if (filters.releaseYearFrom != null || filters.releaseYearTo != null) {
      final from = filters.releaseYearFrom?.year.toString() ?? '';
      final to = filters.releaseYearTo?.year.toString() ?? '';
      chips.add(
        ActionChip(
          label: Text('Year: $from-$to', style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: const Color(0xFF00FF7F).withOpacity(0.2),
          onPressed: () => _applyFilters(releaseYearFrom: null, releaseYearTo: null),
        ),
      );
    }

    if (filters.durationMin != null || filters.durationMax != null) {
      final min = filters.durationMin?.inMinutes.toString() ?? '';
      final max = filters.durationMax?.inMinutes.toString() ?? '';
      chips.add(
        ActionChip(
          label: Text('Duration: ${min}m-${max}m', style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: const Color(0xFF00FF7F).withOpacity(0.2),
          onPressed: () => _applyFilters(durationMin: null, durationMax: null),
        ),
      );
    }

    return chips;
  }

  Widget _buildMultiSelectFilter(
    String label,
    List<String> options,
    List<String> selected,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (isSelected) {
                final newSelected = List<String>.from(selected);
                if (isSelected) {
                  newSelected.add(option);
                } else {
                  newSelected.remove(option);
                }
                onChanged(newSelected);
              },
              backgroundColor: const Color(0xFF2A2A2A),
              selectedColor: const Color(0xFF00FF7F).withOpacity(0.2),
              checkmarkColor: const Color(0xFF00FF7F),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF00FF7F) : Colors.white,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildYearRangeFilter(MovieFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Release Year',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _yearFromController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'From',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final year = int.tryParse(value);
                  _applyFilters(
                    releaseYearFrom: year != null ? DateTime(year) : null,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _yearToController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'To',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final year = int.tryParse(value);
                  _applyFilters(
                    releaseYearTo: year != null ? DateTime(year) : null,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDurationRangeFilter(MovieFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration (minutes)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _durationMinController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Min',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  _applyFilters(
                    durationMin: minutes != null ? Duration(minutes: minutes) : null,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _durationMaxController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Max',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  _applyFilters(
                    durationMax: minutes != null ? Duration(minutes: minutes) : null,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSortOptions(MovieFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: filters.sortBy,
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF2A2A2A),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'release_date', child: Text('Release Date')),
            DropdownMenuItem(value: 'title', child: Text('Title')),
            DropdownMenuItem(value: 'created_at', child: Text('Date Added')),
          ],
          onChanged: (value) {
            if (value != null) {
              _applyFilters(sortBy: value);
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Ascending', style: TextStyle(color: Colors.white)),
            Switch(
              value: filters.ascending,
              onChanged: (value) => _applyFilters(ascending: value),
              activeColor: const Color(0xFF00FF7F),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _applyFilters({
    List<String>? statuses,
    List<String>? languages,
    List<String>? maturityRatings,
    DateTime? releaseYearFrom,
    DateTime? releaseYearTo,
    Duration? durationMin,
    Duration? durationMax,
    String? titleSearch,
    String? sortBy,
    bool? ascending,
  }) {
    final provider = context.read<MovieProvider>();
    final currentFilters = provider.currentFilters;

    final newFilters = currentFilters.copyWith(
      statuses: statuses,
      languages: languages,
      maturityRatings: maturityRatings,
      releaseYearFrom: releaseYearFrom,
      releaseYearTo: releaseYearTo,
      durationMin: durationMin,
      durationMax: durationMax,
      titleSearch: titleSearch,
      sortBy: sortBy,
      ascending: ascending,
    );

    provider.applyFilters(newFilters);
  }
}