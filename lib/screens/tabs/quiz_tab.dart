import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/quiz.dart';
import '../../utils/uuid.dart';

class QuizTab extends StatelessWidget {
  const QuizTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final quizzes = appState.activeQuizzes;

    return Scaffold(
      body: quizzes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No quizzes for this lesson', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                final attempt = appState.getAttemptForQuiz(quiz.id);
                return _QuizCard(quiz: quiz, attempt: attempt);
              },
            ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final QuizAttempt? attempt;
  const _QuizCard({required this.quiz, this.attempt});

  @override
  Widget build(BuildContext context) {
    final completed = attempt?.submittedAt != null;
    final inProgress = attempt != null && !completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completed ? Icons.check_circle : (inProgress ? Icons.timer : Icons.quiz),
                  color: completed ? Colors.green : (inProgress ? Colors.orange : Colors.indigo),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${attempt!.score}/${attempt!.totalQuestions}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
            if (quiz.description != null && quiz.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(quiz.description!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip(Icons.timer_outlined, '${quiz.durationMinutes} min'),
                const SizedBox(width: 8),
                _infoChip(Icons.help_outline, '${quiz.questions.length} questions'),
                const SizedBox(width: 8),
                if (quiz.dueDate != null)
                  _infoChip(Icons.event, '${quiz.dueDate!.day}/${quiz.dueDate!.month}'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (completed) {
                    _showResult(context, quiz, attempt!);
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _QuizPlayerScreen(quiz: quiz),
                    ));
                  }
                },
                child: Text(completed ? 'View Results' : (inProgress ? 'Continue Quiz' : 'Start Quiz')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  void _showResult(BuildContext context, Quiz quiz, QuizAttempt attempt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${quiz.title} - Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: attempt.percentage >= 50 ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
              ),
              child: Center(
                child: Text(
                  '${attempt.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold,
                    color: attempt.percentage >= 50 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Score: ${attempt.score} / ${attempt.totalQuestions}'),
            Text('Submitted: ${attempt.submittedAt?.hour ?? "—"}:${attempt.submittedAt?.minute.toString().padLeft(2, '0') ?? "—"}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _QuizPlayerScreen extends StatefulWidget {
  final Quiz quiz;
  const _QuizPlayerScreen({required this.quiz});

  @override
  State<_QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<_QuizPlayerScreen> {
  int _currentQuestion = 0;
  final Map<int, String> _answers = {};
  int? _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final questions = quiz.questions;
    final isLast = _currentQuestion == questions.length - 1;
    final q = questions[_currentQuestion];
    final selected = _answers[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text('${_currentQuestion + 1}/${questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: questions.isEmpty
          ? const Center(child: Text('No questions in this quiz'))
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentQuestion + 1) / questions.length,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Question ${_currentQuestion + 1}', style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          )),
                        ),
                        const SizedBox(height: 16),
                        Text(q.questionText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        ...List.generate(4, (i) {
                          final optionKey = String.fromCharCode(97 + i); // a, b, c, d
                          final isSelected = selected == optionKey;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => setState(() => _answers[_currentQuestion] = optionKey),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[400]!),
                                      ),
                                      child: Center(
                                        child: Text(
                                          q.labelAt(i),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(child: Text(q.optionAt(i), style: const TextStyle(fontSize: 15))),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      if (_currentQuestion > 0)
                        OutlinedButton(
                          onPressed: () => setState(() => _currentQuestion--),
                          child: const Text('Previous'),
                        ),
                      if (_currentQuestion > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selected == null ? null : () {
                            if (isLast) {
                              _submitQuiz(context);
                            } else {
                              setState(() => _currentQuestion++);
                            }
                          },
                          child: Text(isLast ? 'Submit Quiz' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _submitQuiz(BuildContext context) {
    final quiz = widget.quiz;
    final questions = quiz.questions;
    int score = 0;
    final answersMap = <String, String>{};

    for (int i = 0; i < questions.length; i++) {
      final selected = _answers[i] ?? '';
      answersMap[questions[i].id] = selected;
      if (selected == questions[i].correctAnswer) {
        score++;
      }
    }

    final attempt = QuizAttempt(
      id: uuid(),
      quizId: quiz.id,
      studentId: context.read<AppState>().currentUser?.username ?? '',
      score: score,
      totalQuestions: questions.length,
      answers: answersMap,
      startedAt: DateTime.fromMillisecondsSinceEpoch(_startedAt ?? 0),
      submittedAt: DateTime.now(),
    );

    context.read<AppState>().submitQuizAttempt(attempt);

    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Submitted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: attempt.percentage >= 50 ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
              ),
              child: Center(
                child: Text(
                  '${attempt.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: attempt.percentage >= 50 ? Colors.green : Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('You scored $score out of ${questions.length}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class AdminQuizPage extends StatelessWidget {
  const AdminQuizPage({super.key});
  void _createQuizDialog(BuildContext context) {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final durationCtl = TextEditingController(text: '10');
    final appState = context.read<AppState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Create Quiz'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'Quiz Title', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 8),
            TextField(controller: durationCtl, decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (titleCtl.text.isEmpty) return;
            final quiz = Quiz(
              id: uuid(),
              lessonId: appState.activeLessonId,
              title: titleCtl.text,
              description: descCtl.text.isNotEmpty ? descCtl.text : null,
              durationMinutes: int.tryParse(durationCtl.text) ?? 10,
            );
            appState.addQuiz(quiz);
            Navigator.pop(ctx);
            _addQuestions(context, quiz);
          }, child: const Text('Create & Add Questions')),
        ],
      ),
    ));
  }

  void _addQuestions(BuildContext context, Quiz quiz) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _QuestionEditorScreen(quiz: quiz),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createQuizDialog(context),
        child: const Icon(Icons.add),
      ),
      body: appState.quizzes.isEmpty
          ? Center(child: Text('No quizzes yet', style: TextStyle(color: Colors.grey[500])))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: appState.quizzes.length,
              itemBuilder: (context, index) {
                final q = appState.quizzes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${q.questions.length}')),
                    title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${q.durationMinutes} min  •  Lesson ${q.lessonId}', style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _addQuestions(context, q),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => appState.deleteQuiz(q.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _QuestionEditorScreen extends StatefulWidget {
  final Quiz quiz;
  const _QuestionEditorScreen({required this.quiz});

  @override
  State<_QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<_QuestionEditorScreen> {
  void _addQuestion() {
    final qTextCtl = TextEditingController();
    final aCtl = TextEditingController();
    final bCtl = TextEditingController();
    final cCtl = TextEditingController();
    final dCtl = TextEditingController();
    String correct = 'a';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add Question'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: qTextCtl, decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 6),
            TextField(controller: aCtl, decoration: const InputDecoration(labelText: 'Option A', border: OutlineInputBorder(), prefixText: 'A) ')),
            const SizedBox(height: 6),
            TextField(controller: bCtl, decoration: const InputDecoration(labelText: 'Option B', border: OutlineInputBorder(), prefixText: 'B) ')),
            const SizedBox(height: 6),
            TextField(controller: cCtl, decoration: const InputDecoration(labelText: 'Option C', border: OutlineInputBorder(), prefixText: 'C) ')),
            const SizedBox(height: 6),
            TextField(controller: dCtl, decoration: const InputDecoration(labelText: 'Option D', border: OutlineInputBorder(), prefixText: 'D) ')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: correct,
              decoration: const InputDecoration(labelText: 'Correct Answer', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'a', child: Text('A')),
                DropdownMenuItem(value: 'b', child: Text('B')),
                DropdownMenuItem(value: 'c', child: Text('C')),
                DropdownMenuItem(value: 'd', child: Text('D')),
              ],
              onChanged: (v) => setState(() => correct = v!),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (qTextCtl.text.isEmpty || aCtl.text.isEmpty || bCtl.text.isEmpty) return;
            context.read<AppState>().addQuestionToQuiz(widget.quiz.id, QuizQuestion(
              id: uuid(),
              quizId: widget.quiz.id,
              questionText: qTextCtl.text,
              optionA: aCtl.text,
              optionB: bCtl.text,
              optionC: cCtl.text.isNotEmpty ? cCtl.text : 'None of the above',
              optionD: dCtl.text.isNotEmpty ? dCtl.text : 'All of the above',
              correctAnswer: correct,
              sortOrder: widget.quiz.questions.length,
            ));
            Navigator.pop(ctx);
            setState(() {});
          }, child: const Text('Add Question')),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final quiz = appState.quizzes.firstWhere(
      (q) => q.id == widget.quiz.id,
      orElse: () => widget.quiz,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Questions: ${quiz.title}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text('${quiz.questions.length} questions', style: const TextStyle(fontSize: 13))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        child: const Icon(Icons.add),
      ),
      body: quiz.questions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No questions yet', style: TextStyle(color: Colors.grey[500])),
                  Text('Tap + to add', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: quiz.questions.length,
              itemBuilder: (context, index) {
                final q = quiz.questions[index];
                final answerLabels = ['A', 'B', 'C', 'D'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w600))),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () => appState.removeQuestionFromQuiz(quiz.id, index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(4, (i) {
                          final key = String.fromCharCode(97 + i);
                          final isCorrect = key == q.correctAnswer;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Row(
                              children: [
                                Icon(isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                     size: 16, color: isCorrect ? Colors.green : Colors.grey[400]),
                                const SizedBox(width: 6),
                                Text('${answerLabels[i]}: ${q.optionAt(i)}',
                                    style: TextStyle(fontSize: 13, color: isCorrect ? Colors.green[700] : Colors.grey[700])),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
