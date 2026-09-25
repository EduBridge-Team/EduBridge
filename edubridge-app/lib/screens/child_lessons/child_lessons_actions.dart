part of 'child_lessons_screen.dart';

extension _ChildLessonsActions on _ChildLessonsScreenState {
  Future<void> _loadRole() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    _updateChildLessonsState(() {
      _canMarkDone = role == 'teacher' || role == 'specialist' || role == 'admin';
    });
  }

  Future<void> _loadStars() async {
    final stars = await RewardService.instance.getStars(widget.childId);
    if (!mounted) return;
    _updateChildLessonsState(() => _stars = stars);
  }

  Future<void> _loadLessons() async {
    _updateChildLessonsState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiService.authGet('/children/${widget.childId}/lessons'),
        ApiService.authGet('/progress/child/${widget.childId}'),
      ]);

      final lessonsRes = responses[0];
      final progressRes = responses[1];
      final lessonsData = jsonDecode(lessonsRes.body);

      if (lessonsRes.statusCode == 200) {
        _doneLessonIds.clear();
        if (progressRes.statusCode == 200) {
          final progress = jsonDecode(progressRes.body)['progress'] ?? [];
          for (final p in progress) {
            if (p['status'] == 'done' && p['lesson_id'] is int) {
              _doneLessonIds.add(p['lesson_id'] as int);
            }
          }
        }
        if (!mounted) return;
        _updateChildLessonsState(() {
          _lessons = lessonsData['lessons'] ?? [];
          _loading = false;
        });
      } else {
        if (!mounted) return;
        _updateChildLessonsState(() {
          _error = lessonsData['error'] ?? 'تعذّر جلب الدروس';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _updateChildLessonsState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _markLessonDone(int lessonId) async {
    _updateChildLessonsState(() => _savingLessonId = lessonId);

    try {
      final res = await ApiService.authPost('/progress', {
        'child_id': widget.childId,
        'lesson_id': lessonId,
        'status': 'done',
      });

      if (!mounted) return;
      if (res.statusCode == 201) {
        _updateChildLessonsState(() => _doneLessonIds.add(lessonId));

        await RewardService.instance.addStar(widget.childId);
        await _loadStars();

        if (!mounted) return;

        final profile = AccessibilityService.instance.profile.value;
        if (profile.rewardSystem) {
          await RewardService.showReward(
            context,
            message: 'أحسنت! +نجمة',
            emoji: '🏆',
            stars: 1,
          );
        } else {
          await VisualCelebration.show(
            context,
            message: 'أكملت الدرس!',
            emoji: '🏆',
            childName: widget.childName,
            duration: const Duration(seconds: 3),
          );
        }

        if (mounted && _doneLessonIds.length % 3 == 0) {
          _suggestGames();
        }
      }
    } catch (e) {
      // Silent
    } finally {
      if (mounted) _updateChildLessonsState(() => _savingLessonId = null);
    }
  }

  void _suggestGames() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdaptiveHelper.cardRadius),
        ),
        title: Row(
          children: [
            Icon(AppIcons.game, color: AppColors.orange, size: 26),
            const SizedBox(width: 8),
            const AdaptiveText('وقت اللعب!', type: AdaptiveTextType.title),
          ],
        ),
        content: const AdaptiveText(
          'أكملت 3 دروس! هل تريد اللعب قليلاً؟',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AdaptiveButton(
                  label: 'لاحقاً',
                  style: AdaptiveButtonStyle.outlined,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: AdaptiveHelper.spacing / 2),
              Expanded(
                child: AdaptiveButton(
                  label: 'هيا!',
                  backgroundColor: AppColors.orange,
                  onPressed: () {
                    Navigator.pop(context);
                    _openGames();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSpeak(Map lesson) async {
    final rawId = lesson['id'];
    if (_speakingLessonId == rawId) {
      await TtsService.instance.stop();
      if (mounted) _updateChildLessonsState(() => _speakingLessonId = null);
      return;
    }

    await TtsService.instance.stop();
    if (!mounted) return;
    _updateChildLessonsState(() => _speakingLessonId = rawId is int ? rawId : null);

    var text = [
      lesson['title'] ?? '',
      lesson['content'] ?? '',
    ].where((t) => t.toString().isNotEmpty).join('. ');

    if (text.trim().isEmpty) {
      if (mounted) _updateChildLessonsState(() => _speakingLessonId = null);
      return;
    }

    final profile = AccessibilityService.instance.profile.value;
    if (profile.verySimpleLanguage) {
      text = SimpleLanguageService.instance.simplify(text);
    }
    if (profile.shortSentences) {
      text = SimpleLanguageService.instance.shorten(text, maxWords: 10);
    }

    if (profile.slowSpeech) {
      await TtsService.instance.speakLineSlow(text);
    } else {
      await TtsService.instance.speakLine(text);
    }
    if (mounted) _updateChildLessonsState(() => _speakingLessonId = null);
  }

  Future<T?> _openOutsideChildScope<T>(Route<T> route) async {
    await AccessibilityService.instance.setActiveChild(null);
    if (!mounted) return null;

    final result = await Navigator.push<T>(context, route);

    if (mounted) {
      await AccessibilityService.instance.setActiveChild(
        widget.childId,
        disabilityTypeHint: widget.disabilityType,
      );
    }
    return result;
  }

  Future<void> _openGames() async {
    await _openOutsideChildScope(
      MaterialPageRoute(
        builder: (_) => EducationalGamesScreen(
          childName: widget.childName,
          age: widget.age,
        ),
      ),
    );
  }

  void _openSettings() async {
    await AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityType,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildAccessibilitySettingsScreen(
          childId: widget.childId,
          childName: widget.childName,
          disabilityTypeHint: widget.disabilityType,
          deactivateOnExit: false,
        ),
      ),
    );
    if (mounted) _updateChildLessonsState(() {});
  }

  void _openProgress() async {
    await _openOutsideChildScope(
      MaterialPageRoute(
        builder: (_) => ChildProgressScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
    _loadLessons();
  }

  void _openLesson(Map lesson) {
    final profile = AccessibilityService.instance.profile.value;
    var title = (lesson['title'] ?? '').toString();
    var content = (lesson['content'] ?? '').toString();

    if (profile.verySimpleLanguage) {
      title = SimpleLanguageService.instance.simplify(title);
      content = SimpleLanguageService.instance.simplify(content);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildLessonDetailModal(
        context: context,
        title: title,
        content: content,
        lesson: lesson,
        activeAudioUrl: _activeAudioUrl,
        onToggleAudio: _toggleLessonAudio,
        onOpenAssistant: _openAssistantFromLesson,
        onOpenVideo: _openVideoFromLesson,
      ),
    );
  }

  Future<void> _toggleLessonAudio(String url) async {
    if (_activeAudioUrl == url) {
      await _lessonAudioPlayer.stop();
      if (mounted) _updateChildLessonsState(() => _activeAudioUrl = null);
      return;
    }

    await _lessonAudioPlayer.stop();
    await _lessonAudioPlayer.play(UrlSource(url));
    if (mounted) _updateChildLessonsState(() => _activeAudioUrl = url);
  }

  void _openAssistantFromLesson(String title, String content) {
    _openOutsideChildScope(
      MaterialPageRoute(
        builder: (_) => AssistantScreen(
          lessonContext: 'عنوان: $title\n$content',
        ),
      ),
    );
  }

  void _openVideoFromLesson({
    required String videoUrl,
    String? captionUrl,
    String? signLanguageUrl,
    String? audioDescription,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdaptiveVideoPlayer(
          videoUrl: videoUrl,
          captionUrl: captionUrl,
          signLanguageUrl: signLanguageUrl,
          audioDescription: audioDescription,
          title: title,
        ),
      ),
    );
  }
}
