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

    final colorScheme = Theme.of(context).colorScheme;
    final isListening = q.contextType == QuestionContextType.transcript;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isListening ? Icons.headphones : Icons.article_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q.contextTitle ??
                        (isListening ? 'Listening Audio' : 'Reading Passage'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (isListening)
                  FilledButton.tonalIcon(
                    onPressed: _togglePlayback,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Stop' : 'Play'),
                  ),
              ],
            ),
            if (isListening) ...[
              const SizedBox(height: 8),
              Text(
                'Listen to the audio, then answer the questions below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
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
            ],
            if (!isListening || _showTranscript) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: _ContextBody(
                    body: q.contextBody!,
                    isTranscript: isListening,
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
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$speaker: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
        );
      }).toList(),
    );
  }
}
