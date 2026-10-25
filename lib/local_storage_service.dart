import 'package:hive_flutter/hive_flutter.dart';

/// Stores the user's emergency-readiness data on the device with Hive.
class LocalStorageService {
  static const _boxName = 'kalasag_local_data';
  static const _stateKey = 'readiness_state';

  Box<dynamic>? _box;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  String? readState() => _box?.get(_stateKey) as String?;

  Future<void> writeState(String json) async {
    final box = _box;
    if (box == null) throw StateError('Hive storage is not initialized.');
    await box.put(_stateKey, json);
    await box.flush();
  }

  Future<void> deleteState() async {
    final box = _box;
    if (box == null) throw StateError('Hive storage is not initialized.');
    await box.delete(_stateKey);
    await box.flush();
  }
}
