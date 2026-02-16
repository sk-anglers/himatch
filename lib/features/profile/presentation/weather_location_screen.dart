import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/features/profile/presentation/providers/location_providers.dart';
import 'package:himatch/services/geocoding_service.dart';

class WeatherLocationScreen extends ConsumerStatefulWidget {
  const WeatherLocationScreen({super.key});

  @override
  ConsumerState<WeatherLocationScreen> createState() =>
      _WeatherLocationScreenState();
}

class _WeatherLocationScreenState
    extends ConsumerState<WeatherLocationScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<GeocodingResult> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final service = ref.read(geocodingServiceProvider);
    final results = await service.search(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(weatherLocationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('天気の地域設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current setting
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.place, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '現在の設定',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (location.useCurrentLocation)
                    const Icon(Icons.gps_fixed,
                        size: 18, color: AppColors.success),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // GPS option
          Card(
            child: ListTile(
              leading: Icon(
                Icons.my_location,
                color: location.useCurrentLocation
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
              title: const Text('現在地を使う (GPS)'),
              subtitle: const Text(
                '端末の位置情報から自動取得',
                style: TextStyle(fontSize: 12),
              ),
              trailing: location.useCurrentLocation
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : const Icon(Icons.radio_button_unchecked,
                      color: AppColors.textHint),
              onTap: () {
                ref
                    .read(weatherLocationProvider.notifier)
                    .useCurrentLocation();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('現在地モードに切り替えました')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // City search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: '都市名で検索',
              hintText: '例: 大阪、札幌、福岡...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _results = [];
                          _isSearching = false;
                        });
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 8),

          // Search results
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_results.isNotEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < _results.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.location_city, color: AppColors.textSecondary),
                      title: Text(_results[i].name),
                      subtitle: Text(
                        [
                          if (_results[i].admin1 != null) _results[i].admin1!,
                          if (_results[i].country != null) _results[i].country!,
                        ].join(', '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        final r = _results[i];
                        ref
                            .read(weatherLocationProvider.notifier)
                            .setCity(r.name, r.latitude, r.longitude);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${r.name}に設定しました')),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ],
              ),
            )
          else if (_searchController.text.isNotEmpty && !_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '該当する都市が見つかりませんでした',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Help text
          const Text(
            'GPS を使用するには、端末の設定で位置情報サービスを有効にし、'
            'アプリに位置情報の利用を許可してください。'
            'GPS が利用できない場合は東京の天気が表示されます。',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
