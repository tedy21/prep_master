import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      create: (_) =>
          sl<QuizSessionBloc>()..add(StartQuizSession(args)),
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

  List<String> _optionsFor(QuizSessionActive state) {
    if (_lastIndex != state.currentIndex) {
      _lastIndex = state.currentIndex;
      _options = state.currentQuestion.shuffledOptions;
    }
    return _options!;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizSessionBloc, QuizSessionState>(
      listener: (context, state) {
        if (state is QuizSessionFinished) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => QuizResultPage(result: state),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.args.title)),
          body: Builder(
            builder: (context) {
              if (state is QuizSessionLoading || state is QuizSessionInitial) {
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
    );
  }

  Widget _buildQuestion(BuildContext context, QuizSessionActive state) {
    final options = _optionsFor(state);
    final q = state.currentQuestion;
    final progress = (state.currentIndex + 1) / state.questions.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text(
            'Question ${state.currentIndex + 1} of ${state.questions.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (q.skillArea != null) ...[
            const SizedBox(height: 4),
            Text(
              q.skillArea!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (q.hasContext) ...[
            const SizedBox(height: 16),
            IeltsContextPanel(question: q),
          ],
          const SizedBox(height: 16),
          Text(
            q.question,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final option = options[i];
                final selected = state.selectedOption == option;
                return OutlinedButton(
                  onPressed: () => context
                      .read<QuizSessionBloc>()
                      .add(SelectAnswer(option)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(option),
                );
              },
            ),
          ),
          FilledButton(
            onPressed: state.selectedOption == null
                ? null
                : () => context.read<QuizSessionBloc>().add(const NextQuestion()),
            child: Text(
              state.currentIndex >= state.questions.length - 1
                  ? 'Finish'
                  : 'Next',
            ),
          ),
        ],
      ),
    );
  }
}
