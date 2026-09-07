import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection.dart';
import '../../../progress/presentation/bloc/progress_bloc.dart';
import '../../domain/usecases/record_quiz_session.dart';
import '../bloc/quiz_session_bloc.dart';

class QuizResultPage extends StatefulWidget {
  const QuizResultPage({super.key, required this.result});

  final QuizSessionFinished result;

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  bool _saving = true;
  String? _saveError;
  int? _xpEarned;

  @override
  void initState() {
    super.initState();
    _persistResult();
  }

  Future<void> _persistResult() async {
    final result = widget.result;
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final recordResult = await sl<RecordQuizSession>()(
      RecordQuizSessionParams(
        sessionId: sessionId,
        title: result.title,
        examType: result.examType,
        section: result.section,
        mockTestId: result.mockTestId,
        score: result.score,
        totalQuestions: result.questions.length,
      ),
    );

    if (!mounted) return;

    recordResult.fold(
      (failure) => setState(() {
        _saving = false;
        _saveError = failure.message;
      }),
      (progress) {
        setState(() {
          _saving = false;
          _xpEarned = 20 + result.score * 10;
        });
        // Refresh progress tab if bloc is available above in tree.
        try {
          context.read<ProgressBloc>().add(const LoadUserProgress());
        } catch (_) {}
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;
    final score = result.score;
    final total = result.questions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            score >= total * 0.7 ? Icons.emoji_events : Icons.school_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            result.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$score / $total correct (${result.percent.toStringAsFixed(0)}%)',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (_saving)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Saving progress…'),
              ],
            )
          else if (_saveError != null)
            Text(
              'Could not save progress: $_saveError',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            )
          else if (_xpEarned != null)
            Text(
              '+$_xpEarned XP earned',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          Text('Review', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...List.generate(result.questions.length, (i) {
            final q = result.questions[i];
            final chosen = result.answers[i];
            final correct = chosen == q.correctAnswer;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          correct ? Icons.check_circle : Icons.cancel,
                          color: correct ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.question,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (!correct) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Your answer: ${chosen ?? "—"}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Correct: ${q.correctAnswer}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                    if (q.explanation != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        q.explanation!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}
