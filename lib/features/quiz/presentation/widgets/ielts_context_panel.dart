import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/models/quiz_question.dart';

/// Displays an IELTS reading passage or listening transcript above questions.
class IeltsContextPanel extends StatefulWidget {
  const IeltsContextPanel({
    super.key,
    required this.question,
  });

  final QuizQuestion question;

  @override
  State<IeltsContextPanel> createState() => _IeltsContextPanelState();
}

class _IeltsContextPanelState extends State<IeltsContextPanel> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  bool _showTranscript = false;
  bool _passageExpanded = true;

  @override
  void didUpdateWidget(covariant IeltsContextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id ||
        oldWidget.question.contextSetId != widget.question.contextSetId) {
      _stopPlayback();
      _isPlaying = false;
      // Keep passage open across questions in the same set.
      if (oldWidget.question.contextSetId != widget.question.contextSetId) {
        _passageExpanded = true;
        _showTranscript = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }

  Future<void> _stopPlayback() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _stopPlayback();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.speak(widget.question.contextBody ?? '');
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _showTranscript = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Audio unavailable — read the transcript below.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    if (!q.hasContext) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isListening = q.contextType == QuestionContextType.transcript;
    final isWriting = (q.examType == 'ielts' &&
            (q.skillArea?.toLowerCase().contains('task') ?? false)) ||
        (q.contextTitle?.toLowerCase().contains('writing') ?? false) ||
        (q.contextTitle?.toLowerCase().contains('task 1') ?? false) ||
        (q.contextTitle?.toLowerCase().contains('task 2') ?? false);
    final showBody = isListening ? _showTranscript : _passageExpanded;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isListening
                      ? Icons.headphones
                      : (isWriting
                          ? Icons.edit_note_outlined
                          : Icons.menu_book_outlined),
                  size: 22,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isListening
                            ? 'Listening'
                            : (isWriting ? 'Writing task' : 'Reading passage'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        q.contextTitle ??
                            (isListening
                                ? 'Audio transcript'
                                : (isWriting
                                    ? 'Read the task, then answer'
                                    : 'Read carefully, then answer')),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isListening)
                  FilledButton.tonalIcon(
                    onPressed: _togglePlayback,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Stop' : 'Play'),
                  )
                else
                  IconButton(
                    tooltip: _passageExpanded ? 'Collapse' : 'Expand',
                    onPressed: () =>
                        setState(() => _passageExpanded = !_passageExpanded),
                    icon: Icon(
                      _passageExpanded
                          ? Icons.unfold_less
                          : Icons.unfold_more,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isListening
                  ? 'Play the audio, then answer the questions. Use the transcript only if you need it.'
                  : (isWriting
                      ? 'Study the Academic Writing prompt (Task 1 or Task 2), then answer the practice question.'
                      : 'Use the passage to answer the question below. Scroll within the passage if needed.'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isListening) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _showTranscript = !_showTranscript),
                  icon: Icon(
                    _showTranscript ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  label: Text(
                    _showTranscript ? 'Hide transcript' : 'Show transcript',
                  ),
                ),
              ),
            ],
            if (showBody) ...[
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxHeight: isListening ? 220 : 320,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: _ContextBody(
                      body: q.contextBody!,
                      isTranscript: isListening,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContextBody extends StatelessWidget {
  const _ContextBody({
    required this.body,
    required this.isTranscript,
  });

  final String body;
  final bool isTranscript;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paragraphs = body
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (!isTranscript && paragraphs.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Text(
              paragraphs[i].replaceAll('\n', ' '),
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.55,
              ),
            ),
          ],
        ],
      );
    }

    final lines = body.split('\n').where((l) => l.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (isTranscript && line.contains(':')) {
          final colonIndex = line.indexOf(':');
          final speaker = line.substring(0, colonIndex).trim();
          final text = line.substring(colonIndex + 1).trim();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                children: [
                  TextSpan(
                    text: '$speaker: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            line,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        );
      }).toList(),
    );
  }
}
