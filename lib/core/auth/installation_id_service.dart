import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class InstallationIdService {
  static const String _key = 'installation_id';
  String? _cachedId;

  Future<String> getInstallationId() async {
    if (_cachedId != null) return _cachedId!;
    
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) {
      _cachedId = existing;
      return existing;
    }

    final newId = const Uuid().v4();
    await prefs.setString(_key, newId);
    _cachedId = newId;
    return newId;
  }
}

