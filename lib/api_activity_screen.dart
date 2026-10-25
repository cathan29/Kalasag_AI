import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiActivityScreen extends StatefulWidget {
  const ApiActivityScreen({super.key});
  @override
  State<ApiActivityScreen> createState() => _ApiActivityScreenState();
}

class _ApiActivityScreenState extends State<ApiActivityScreen> {
  bool loading = false;
  bool? success;
  int? status;
  String message = 'Run a request to inspect the API response.';
  String url = '';
  Map<String, dynamic>? data;

  Future<void> run({bool fail = false}) async {
    final uri = fail
        ? Uri.https('api.open-meteo.com', '/v1/invalid-endpoint')
        : Uri.https('api.open-meteo.com', '/v1/forecast', {
            'latitude': '15.894',
            'longitude': '120.632',
            'current':
                'temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation',
            'timezone': 'Asia/Manila',
          });
    setState(() {
      loading = true;
      success = null;
      status = null;
      data = null;
      url = uri.toString();
      message = fail
          ? 'Requesting an invalid endpoint…'
          : 'Requesting live weather data…';
    });
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          loading = false;
          success = false;
          status = response.statusCode;
          message = 'HTTP ${response.statusCode} was handled without crashing.';
        });
        return;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final current = Map<String, dynamic>.from(body['current'] ?? {});
      setState(() {
        loading = false;
        success = true;
        status = response.statusCode;
        message = 'Live response received, decoded, and displayed.';
        data = {
          'Temperature': '${current['temperature_2m'] ?? 'N/A'} °C',
          'Humidity': '${current['relative_humidity_2m'] ?? 'N/A'}%',
          'Wind speed': '${current['wind_speed_10m'] ?? 'N/A'} km/h',
          'Precipitation': '${current['precipitation'] ?? 'N/A'} mm',
          'Observed at': '${current['time'] ?? 'Unknown'}',
        };
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        success = false;
        message = 'Request failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = success == true
        ? const Color(0xFF42B978)
        : success == false
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('API Integration Evidence')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open-Meteo Forecast API',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _Info('Purpose', 'Live local weather'),
                  const _Info('HTTP method', 'GET'),
                  const _Info('Endpoint', 'api.open-meteo.com/v1/forecast'),
                  const _Info(
                    'Main data',
                    'Temperature, humidity, wind, precipitation',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('run-live-get'),
                  onPressed: loading ? null : run,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Run live GET'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('run-failed-get'),
                  onPressed: loading ? null : () => run(fail: true),
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Test failure'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: color.withValues(alpha: .12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (loading)
                        const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          success == true
                              ? Icons.check_circle
                              : success == false
                              ? Icons.error
                              : Icons.api,
                          color: color,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loading
                              ? 'Loading'
                              : success == true
                              ? 'API Request Successful'
                              : success == false
                              ? 'Failed Response Handled'
                              : 'Ready',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (status != null) Chip(label: Text('HTTP $status')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(message),
                ],
              ),
            ),
          ),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Request URL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SelectableText(url, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (data != null) ...[
            const SizedBox(height: 16),
            Text(
              'Parsed response data',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: data!.entries
                    .map(
                      (e) => ListTile(
                        dense: true,
                        title: Text(e.key),
                        trailing: Text(
                          '${e.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Data flow: KALASAG → HTTP GET → Open-Meteo API → JSON response → jsonDecode() → Weather UI',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
