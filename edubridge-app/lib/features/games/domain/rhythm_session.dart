class RhythmSession {
  List<String> _words = [];
  int _index = 0;
  int get index => _index;
  int _tapCount = 0;
  int get tapCount => _tapCount;
  bool _playing = false;
  bool get playing => _playing;
  bool _paused = false;
  bool get paused => _paused;
  List<String> get words => List.unmodifiable(_words);
  bool get complete => _index >= _words.length;
  String get currentWord => _words[_index];

  void start(List<String> words) {
    if (words.isEmpty) throw ArgumentError('Rhythm requires words');
    _words = List.from(words);
    _index = 0; _tapCount = 0; _playing = true; _paused = false;
  }
  void tap() { if (_playing && !_paused && !complete) _tapCount++; }
  void advance() { if (_playing && !_paused && !complete) { _index++; _tapCount = 0; } }
  void pause() { if (_playing) _paused = true; }
  void resume() { if (_playing) _paused = false; }
  void finish() => _playing = false;
}
