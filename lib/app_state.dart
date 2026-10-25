import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'local_storage_service.dart';
import 'models.dart';
import 'services.dart';

class AppState extends ChangeNotifier {
  final weatherService = WeatherService();
  final alertService = AlertService();
  final shelterService = ShelterService();
  final localStorage = LocalStorageService();
  GeoPoint? location;
  WeatherSnapshot? weather;
  List<AlertItem> alerts = [];
  List<Shelter> shelters = [];
  bool locating = true,
      weatherLoading = false,
      alertsLoading = false,
      sheltersLoading = false;
  String? locationError, weatherError, alertsError, sheltersError;
  DateTime? weatherUpdated, alertsUpdated, sheltersUpdated;
  double shelterRadius = 25, alertRadius = 100;
  bool notificationsEnabled = true, quietHoursEnabled = true;
  int quietStart = 22, quietEnd = 7;
  bool storageReady = false, storageRestored = false;
  String storageLastOperation = 'Opening Hive local storage…';
  String? storageError;
  DateTime? storageChangedAt;
  List<SavedPlace> savedPlaces = [];
  List<EmergencyContact> emergencyContacts = [];
  List<KitItem> kit = [
    KitItem('water', 'Water for 3 days'),
    KitItem('food', 'Ready-to-eat food'),
    KitItem('first_aid', 'First aid kit'),
    KitItem('flashlight', 'Flashlight and batteries'),
    KitItem('radio', 'Battery-powered radio'),
    KitItem('documents', 'IDs and waterproof documents'),
    KitItem('meds', 'Prescription medicines'),
    KitItem('powerbank', 'Charged power bank'),
  ];
  Map<String, String> familyPlan = {
    'meetingPlace': '',
    'outOfTownContact': '',
    'medicalNotes': '',
  };

  Future<void> initialize() async {
    await _restore();
    await locate();
    await refreshAlerts();
  }

  Future<void> locate() async {
    locating = true;
    locationError = null;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please enable location services.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required for local weather and radar.',
        );
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      var label = 'Current location';
      try {
        final places = await placemarkFromCoordinates(p.latitude, p.longitude);
        if (places.isNotEmpty) {
          final x = places.first;
          label = [
            x.locality,
            x.administrativeArea,
            x.country,
          ].where((x) => x != null && x.isNotEmpty).join(', ');
        }
      } catch (_) {}
      location = GeoPoint(p.latitude, p.longitude, label);
      await refreshWeather();
    } catch (e) {
      locationError = e.toString().replaceFirst('Exception: ', '');
    }
    locating = false;
    notifyListeners();
  }

  Future<void> refreshWeather() async {
    if (location == null) return;
    weatherLoading = true;
    weatherError = null;
    notifyListeners();
    try {
      weather = await weatherService.fetch(location!);
      weatherUpdated = DateTime.now();
    } catch (e) {
      weatherError = e.toString().replaceFirst('Exception: ', '');
    }
    weatherLoading = false;
    notifyListeners();
  }

  Future<void> refreshAlerts() async {
    alertsLoading = true;
    alertsError = null;
    notifyListeners();
    try {
      alerts = await alertService.fetch();
      alertsUpdated = DateTime.now();
    } catch (e) {
      alertsError = 'Live alert providers are temporarily unavailable.';
    }
    alertsLoading = false;
    notifyListeners();
  }

  Future<void> refreshShelters([double? radius]) async {
    if (location == null) return;
    if (radius != null) shelterRadius = radius;
    sheltersLoading = true;
    sheltersError = null;
    notifyListeners();
    try {
      shelters = await shelterService.fetch(location!, shelterRadius);
      sheltersUpdated = DateTime.now();
    } catch (e) {
      sheltersError = e.toString().replaceFirst('Exception: ', '');
    }
    sheltersLoading = false;
    notifyListeners();
  }

  void toggleKit(String id) {
    final x = kit.firstWhere((x) => x.id == id);
    x.done = !x.done;
    _persist('Updated go-bag item');
    notifyListeners();
  }

  void updatePlan(String key, String value) {
    familyPlan[key] = value;
    _persist('Updated family plan');
    notifyListeners();
  }

  void saveCurrent() {
    final p = location;
    if (p == null) return;
    final id = '${p.label}-${p.latitude}-${p.longitude}';
    if (savedPlaces.any((x) => x.id == id)) return;
    savedPlaces.insert(0, SavedPlace(id, p.label, p.latitude, p.longitude));
    if (savedPlaces.length > 5) savedPlaces.removeLast();
    _persist('Saved current place');
    notifyListeners();
  }

  void removePlace(String id) {
    savedPlaces.removeWhere((x) => x.id == id);
    _persist('Deleted saved place');
    notifyListeners();
  }

  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    String relationship = '',
  }) async {
    if (name.trim().isEmpty) {
      throw const FormatException('Enter a contact name.');
    }
    final normalized = EmergencyContact.normalizedPhone(phone);
    if (!EmergencyContact.isValidPhone(normalized)) {
      throw const FormatException('Enter a valid phone number.');
    }
    if (emergencyContacts.any((contact) => contact.phone == normalized)) {
      throw const FormatException('That phone number is already saved.');
    }
    final contact = EmergencyContact(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      phone: normalized,
      relationship: relationship.trim(),
    );
    emergencyContacts.add(contact);
    await _persist('Added emergency contact');
    if (storageError != null) {
      emergencyContacts.remove(contact);
      throw StateError('The contact could not be saved on this device.');
    }
    notifyListeners();
  }

  Future<void> updateEmergencyContact(EmergencyContact updated) async {
    if (updated.name.trim().isEmpty) {
      throw const FormatException('Enter a contact name.');
    }
    final normalized = EmergencyContact.normalizedPhone(updated.phone);
    if (!EmergencyContact.isValidPhone(normalized)) {
      throw const FormatException('Enter a valid phone number.');
    }
    if (emergencyContacts.any(
      (contact) => contact.id != updated.id && contact.phone == normalized,
    )) {
      throw const FormatException('That phone number is already saved.');
    }
    final index = emergencyContacts.indexWhere(
      (contact) => contact.id == updated.id,
    );
    if (index < 0) throw StateError('Emergency contact was not found.');
    final previous = emergencyContacts[index];
    emergencyContacts[index] = updated.copyWith(
      name: updated.name.trim(),
      phone: normalized,
      relationship: updated.relationship.trim(),
    );
    await _persist('Updated emergency contact');
    if (storageError != null) {
      emergencyContacts[index] = previous;
      throw StateError('The contact changes could not be saved.');
    }
    notifyListeners();
  }

  Future<void> deleteEmergencyContact(String id) async {
    final index = emergencyContacts.indexWhere((contact) => contact.id == id);
    if (index < 0) return;
    final removed = emergencyContacts.removeAt(index);
    await _persist('Deleted emergency contact');
    if (storageError != null) {
      emergencyContacts.insert(index, removed);
      throw StateError('The contact could not be deleted from this device.');
    }
    notifyListeners();
  }

  void updateSettings({
    bool? enabled,
    double? radius,
    bool? quiet,
    int? start,
    int? end,
  }) {
    if (enabled != null) notificationsEnabled = enabled;
    if (radius != null) alertRadius = radius;
    if (quiet != null) quietHoursEnabled = quiet;
    if (start != null) quietStart = start;
    if (end != null) quietEnd = end;
    _persist('Updated alert settings');
    notifyListeners();
  }

  Future<Map<String, dynamic>> loadHotlines() => rootBundle
      .loadString('assets/data/hotlines.json')
      .then((s) => jsonDecode(s));
  Future<Map<String, dynamic>> loadGuides() => rootBundle
      .loadString('assets/data/survival_guides.json')
      .then((s) => jsonDecode(s));
  Future<void> _restore() async {
    try {
      await localStorage.initialize();
      storageReady = true;
      final raw = localStorage.readState();
      if (raw == null) {
        storageLastOperation = 'Hive ready — no saved data yet';
        notifyListeners();
        return;
      }
      final j = jsonDecode(raw);
      savedPlaces = (j['savedPlaces'] as List? ?? [])
          .map((x) => SavedPlace.fromJson(x))
          .toList();
      emergencyContacts = (j['emergencyContacts'] as List? ?? [])
          .map((x) => EmergencyContact.fromJson(Map<String, dynamic>.from(x)))
          .toList();
      kit = (j['kit'] as List? ?? []).map((x) => KitItem.fromJson(x)).toList();
      familyPlan = Map<String, String>.from(j['familyPlan'] ?? familyPlan);
      notificationsEnabled = j['notificationsEnabled'] ?? true;
      quietHoursEnabled = j['quietHoursEnabled'] ?? true;
      quietStart = j['quietStart'] ?? 22;
      quietEnd = j['quietEnd'] ?? 7;
      alertRadius = (j['alertRadius'] as num? ?? 100).toDouble();
      storageChangedAt = DateTime.tryParse(j['savedAt'] ?? '');
      storageRestored = true;
      storageLastOperation = 'Retrieved saved data after app start';
    } catch (e) {
      storageError = e.toString();
      storageLastOperation = 'Storage error handled safely';
    }
    notifyListeners();
  }

  Future<void> _persist([String operation = 'Saved locally']) async {
    try {
      if (!storageReady) await localStorage.initialize();
      storageReady = true;
      storageChangedAt = DateTime.now();
      await localStorage.writeState(
        jsonEncode({
          'savedPlaces': savedPlaces.map((x) => x.toJson()).toList(),
          'emergencyContacts': emergencyContacts
              .map((x) => x.toJson())
              .toList(),
          'kit': kit.map((x) => x.toJson()).toList(),
          'familyPlan': familyPlan,
          'notificationsEnabled': notificationsEnabled,
          'quietHoursEnabled': quietHoursEnabled,
          'quietStart': quietStart,
          'quietEnd': quietEnd,
          'alertRadius': alertRadius,
          'savedAt': storageChangedAt!.toIso8601String(),
        }),
      );
      storageError = null;
      storageLastOperation = operation;
    } catch (e) {
      storageError = e.toString();
      storageLastOperation = 'Storage error handled safely';
    }
    notifyListeners();
  }
}
