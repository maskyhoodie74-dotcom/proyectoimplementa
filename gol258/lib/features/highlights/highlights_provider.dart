import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../models/highlight.dart';

class HighlightsProvider extends ChangeNotifier {
  List<Highlight> _highlights = [];
  bool _loading = false;
  String? _error;

  List<Highlight> get highlights => _highlights;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchHighlightsPartido(int partidoId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await supabase
          .from('highlights')
          .select()
          .eq('partido_id', partidoId)
          .order('created_at', ascending: false);
      _highlights = (data as List).map((e) => Highlight.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> agregarHighlight(Highlight highlight) async {
    try {
      await supabase.from('highlights').insert(highlight.toJson());
      if (highlight.partidoId != null) {
        await fetchHighlightsPartido(highlight.partidoId!);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
