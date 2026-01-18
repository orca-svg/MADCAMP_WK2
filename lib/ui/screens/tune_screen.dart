import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/board_provider.dart';

enum _TuneStage { idle, sending, confirm }

class TuneScreen extends ConsumerStatefulWidget {
  const TuneScreen({super.key});

  @override
  ConsumerState<TuneScreen> createState() => _TuneScreenState();
}

class _TuneScreenState extends ConsumerState<TuneScreen> {
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  _TuneStage _stage = _TuneStage.idle;

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final story = _storyController.text.trim();
    if (story.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사연을 입력해주세요.')),
      );
      return;
    }
    setState(() => _stage = _TuneStage.sending);
    await Future<void>.delayed(const Duration(milliseconds: 720));
    if (!mounted) return;
    setState(() => _stage = _TuneStage.confirm);
  }

  void _publish(bool publish) {
    ref.read(boardControllerProvider.notifier).submitStory(
          title: _titleController.text.trim(),
          body: _storyController.text.trim(),
          publish: publish,
        );
    _titleController.clear();
    _storyController.clear();
    setState(() => _stage = _TuneStage.idle);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(publish ? '게시판에 등록했어요.' : '내 방송에 저장했어요.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('TUNE', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            '사연을 입력하면 잠시 송수신 화면으로 전환됩니다.',
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _buildStage(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildStage(ThemeData theme) {
    switch (_stage) {
      case _TuneStage.sending:
        return _StageCard(
          key: const ValueKey('sending'),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  '주파수를 맞추는 중…',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        );
      case _TuneStage.confirm:
        return _StageCard(
          key: const ValueKey('confirm'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '송신 완료. 게시판에 등록할까요?',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _publish(false),
                      child: const Text('나중에'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _publish(true),
                      child: const Text('등록하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case _TuneStage.idle:
      default:
        return _StageCard(
          key: const ValueKey('idle'),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '사연 제목 (선택)',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _storyController,
                  decoration: const InputDecoration(
                    labelText: '사연을 들려주세요',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _send,
                    child: const Text('보내기'),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}
