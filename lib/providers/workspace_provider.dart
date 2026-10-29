import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';

enum WorkspaceType { personal, business }

class WorkspaceItem {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String prefix;

  const WorkspaceItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.prefix,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorValue': color.value,
        'prefix': prefix,
      };

  factory WorkspaceItem.fromMap(Map<String, dynamic> map) => WorkspaceItem(
        id: map['id'] ?? '',
        name: map['name'] ?? 'Yeni Kasa',
        emoji: map['emoji'] ?? '📁',
        color: Color(map['colorValue'] ?? 0xFF8B5CF6),
        prefix: map['prefix'] ?? '',
      );
}

class WorkspaceProvider extends ChangeNotifier {
  List<WorkspaceItem> _workspaces = [
    const WorkspaceItem(
      id: 'personal',
      name: 'Kişisel Cüzdan',
      emoji: '👤',
      color: Color(0xFF8B5CF6),
      prefix: '',
    ),
    const WorkspaceItem(
      id: 'business',
      name: 'Şirket Kasası',
      emoji: '🏢',
      color: Color(0xFF0F766E),
      prefix: 'business_',
    ),
  ];

  String _currentId = 'personal';

  List<WorkspaceItem> get workspaces => _workspaces;
  WorkspaceItem get currentItem =>
      _workspaces.firstWhere((w) => w.id == _currentId, orElse: () => _workspaces.first);

  WorkspaceType get currentWorkspace =>
      _currentId == 'business' ? WorkspaceType.business : WorkspaceType.personal;
  bool get isPersonal => _currentId == 'personal';
  bool get isBusiness => _currentId == 'business';

  String get workspaceName => currentItem.name;
  String get workspaceEmoji => currentItem.emoji;
  Color get workspaceColor => currentItem.color;
  String get collectionPrefix => currentItem.prefix;

  WorkspaceProvider() {
    FirestoreService.currentPrefix = collectionPrefix;
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Yükle: Özel eklenen veya düzenlenen alanlar
    final customListJson = prefs.getStringList('custom_workspaces_v2') ?? prefs.getStringList('custom_workspaces') ?? [];
    for (final jsonStr in customListJson) {
      try {
        final item = WorkspaceItem.fromMap(json.decode(jsonStr));
        final idx = _workspaces.indexWhere((w) => w.id == item.id);
        if (idx != -1) {
          _workspaces[idx] = item;
        } else {
          _workspaces.add(item);
        }
      } catch (_) {}
    }

    // Silinen kimlikleri denetle
    final deletedIds = prefs.getStringList('deleted_workspaces') ?? [];
    _workspaces.removeWhere((w) => deletedIds.contains(w.id) && w.id != 'personal');

    final savedId = prefs.getString('workspace_id') ?? prefs.getString('workspace_type');
    if (savedId != null && _workspaces.any((w) => w.id == savedId)) {
      _currentId = savedId;
    } else if (savedId == 'business' && _workspaces.any((w) => w.id == 'business')) {
      _currentId = 'business';
    } else {
      _currentId = _workspaces.first.id;
    }
    
    FirestoreService.currentPrefix = collectionPrefix;
    notifyListeners();
  }

  Future<void> _saveCustomWorkspaces() async {
    final prefs = await SharedPreferences.getInstance();
    final allItems = _workspaces.map((w) => json.encode(w.toMap())).toList();
    await prefs.setStringList('custom_workspaces_v2', allItems);
  }

  Future<void> setWorkspaceById(String id) async {
    if (_currentId == id || !_workspaces.any((w) => w.id == id)) return;
    _currentId = id;
    FirestoreService.currentPrefix = collectionPrefix;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('workspace_id', id);
    await prefs.setString(
        'workspace_type', id == 'business' ? 'business' : 'personal');
  }

  Future<void> setWorkspace(WorkspaceType type) async {
    final targetId = type == WorkspaceType.business ? 'business' : 'personal';
    await setWorkspaceById(targetId);
  }

  Future<void> addWorkspace(String name, String emoji) async {
    if (name.trim().isEmpty) return;
    final id = 'ws_${DateTime.now().millisecondsSinceEpoch}';
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF6366F1),
    ];
    final color = colors[_workspaces.length % colors.length];
    final newItem = WorkspaceItem(
      id: id,
      name: name.trim(),
      emoji: emoji.trim().isEmpty ? '📁' : emoji.trim(),
      color: color,
      prefix: '${id}_',
    );
    _workspaces.add(newItem);
    await _saveCustomWorkspaces();
    await setWorkspaceById(id);
  }

  Future<void> updateWorkspace(String id, String newName, String newEmoji) async {
    final idx = _workspaces.indexWhere((w) => w.id == id);
    if (idx == -1 || newName.trim().isEmpty) return;

    final old = _workspaces[idx];
    _workspaces[idx] = WorkspaceItem(
      id: old.id,
      name: newName.trim(),
      emoji: newEmoji.trim().isEmpty ? '📁' : newEmoji.trim(),
      color: old.color,
      prefix: old.prefix,
    );

    await _saveCustomWorkspaces();
    notifyListeners();
  }

  Future<bool> deleteWorkspace(String id) async {
    if (id == 'personal' || _workspaces.length <= 1) {
      return false; // Ana cüzdan veya tek kalan cüzdan silinemez
    }

    _workspaces.removeWhere((w) => w.id == id);
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_workspaces') ?? [];
    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList('deleted_workspaces', deletedIds);
    }

    if (_currentId == id) {
      _currentId = _workspaces.first.id;
      FirestoreService.currentPrefix = collectionPrefix;
      await prefs.setString('workspace_id', _currentId);
    }

    await _saveCustomWorkspaces();
    notifyListeners();
    return true;
  }

  void toggleWorkspace() {
    if (_workspaces.isEmpty) return;
    final idx = _workspaces.indexWhere((w) => w.id == _currentId);
    final nextIdx = (idx + 1) % _workspaces.length;
    setWorkspaceById(_workspaces[nextIdx].id);
  }
}


