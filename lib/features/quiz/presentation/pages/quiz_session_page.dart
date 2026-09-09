import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/question_difficulty.dart';
import '../../../../core/widgets/app_views.dart';
import '../../../../injection.dart';
import '../../domain/entities/quiz_session_args.dart';
import '../bloc/quiz_session_bloc.dart';
import '../widgets/ielts_context_panel.dart';
import 'quiz_result_page.dart';

class QuizSessionPage extends StatelessWidget {
  const QuizSessionPage({super.key, required this.args});

  final QuizSessionArgs args;

  static Future<void> open(BuildContext context, QuizSessionArgs args) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizSessionPage(args: args),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuizSessionBloc>()..add(StartQuizSession(args)),
      child: _QuizSessionView(args: args),
    );
  }
}

class _QuizSessionView extends StatefulWidget {
  const _QuizSessionView({required this.args});

  final QuizSessionArgs args;

  @override
  State<_QuizSessionView> createState() => _QuizSessionViewState();
}

class _QuizSessionViewState extends State<_QuizSessionView> {
  List<String>? _options;
  int _lastIndex = -1;
  Timer? _timer;
  int? _remainingSeconds;
  bool _warnedFive = false;
  bool _warnedOne = false;

  @override
  void initState() {
    super.initState();
    final minutes = widget.args.timeLimitMinutes;
    if (minutes != null && minutes > 0) {
      _remainingSeconds = minutes * 60;
      _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    if (!mounted || _remainingSeconds == null) return;
    if (_remainingSeconds! <= 0) {
      timer.cancel();
      context.read<QuizSessionBloc>().add(const ForceFinishQuiz());
      return;
    }

    setState(() => _remainingSeconds = _remainingSeconds! - 1);

    final secs = _remainingSeconds!;
    if (!_warnedFive && secs == 5 * 60) {
      _warnedFive = true;
      _showTimeSnack('5 minutes remaining');
    } else if (!_warnedOne && secs == 60) {
      _warnedOne = true;
      _showTimeSnack('1 minute remaining');
    }
  }

  void _showTimeSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  List<String> _optionsFor(QuizSessionActive state) {
    if (_lastIndex != state.currentIndex) {
      _lastIndex = state.currentIndex;
      _options = state.currentQuestion.shuffledOptions;
    }
    return _options!;
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _onWillPopAttempt() async {
    if (!widget.args.isTimed) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final navigator = Navigator.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave timed exam?'),
        content: const Text(
          'Your progress for this attempt will be lost if you leave now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.args.isTimed,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onWillPopAttempt();
      },
      child: BlocConsumer<QuizSessionBloc, QuizSessionState>(
        listener: (context, state) {
          if (state is QuizSessionFinished) {
            _timer?.cancel();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => QuizResultPage(result: state),
              ),
            );
          }
        },
        builder: (context, state) {
          final adaptiveLabel = state is QuizSessionActive && state.adaptive
              ? 'Adaptive · ${QuestionDifficulty.label(state.currentDifficulty ?? QuestionDifficulty.medium)}'
              : null;

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.args.title),
              actions: [
                if (_remainingSeconds != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: Text(
                        _formatTime(_remainingSeconds!),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _remainingSeconds! <= 60
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ),
                  ),
              ],
              bottom: adaptiveLabel == null
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(28),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          adaptiveLabel,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ),
            ),
            body: Builder(
              builder: (context) {
                if (state is QuizSessionLoading ||
                    state is QuizSessionInitial) {
                  return const AppLoadingView(message: 'Loading questions…');
                }
                if (state is QuizSessionError) {
                  return AppErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<QuizSessionBloc>()
                        .add(StartQuizSession(widget.args)),
                  );
                }
                if (state is QuizSessionActive) {
                  return _buildQuestion(context, state);
                }
                if (state is QuizSessionFinished) {
                  return const AppLoadingView(message: 'Calculating score…');
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, QuizSessionActive state) {
    final options = _optionsFor(state);
    final q = state.currentQuestion;
    final progress = (state.currentIndex + 1) / state.displayTotal;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text(
            'Question ${state.currentIndex + 1} of ${state.displayTotal}',
            style: theme.textTheme.labelLarge,
          ),
          if (q.skillArea != null || state.adaptive) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (q.skillArea != null) q.skillArea!,
                if (state.adaptive)
                  QuestionDifficulty.label(q.difficulty),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                if (q.hasContext) ...[
                  IeltsContextPanel(question: q),
                  const SizedBox(height: 16),
                ],
                Text(
                  q.question,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(options.length, (i) {
                  final option = options[i];
                  final selected = state.selectedOption == option;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => context
                          .read<QuizSessionBloc>()
                          .add(SelectAnswer(option)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected
                            ? theme.colorScheme.primaryContainer
                            : null,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(option),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: state.selectedOption == null
                ? null
                : () => context
                    .read<QuizSessionBloc>()
                    .add(const NextQuestion()),
            child: Text(state.isLastPlanned ? 'Finish' : 'Next'),
          ),
        ],
      ),
    );
  }
}
