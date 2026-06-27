import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_central/theme.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';
import '../services/chat_service.dart';

class GroupSettingsPage extends ConsumerStatefulWidget {
  final String conversationId;
  final Conversation conversation;

  const GroupSettingsPage({
    Key? key,
    required this.conversationId,
    required this.conversation,
  }) : super(key: key);

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.name ?? 'Group Settings', style: textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(text: 'Discussion'),
            Tab(text: 'Membres'),
            Tab(text: 'Fichiers'),
            Tab(text: 'Tâches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DiscussionTab(conversationId: widget.conversationId),
          _MembersTab(conversationId: widget.conversationId),
          _FilesTab(conversationId: widget.conversationId),
          _TasksTab(conversationId: widget.conversationId),
        ],
      ),
    );
  }
}

class _DiscussionTab extends ConsumerWidget {
  final String conversationId;

  const _DiscussionTab({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final messages = ref.watch(messagesStreamProvider(conversationId));

    return ListView(
      children: [
        messages.when(
          data: (messages) {
            if (messages.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No messages yet'),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Text(message.content ?? ''),
                  subtitle: Text(message.createdAt.toString()),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
          error: (err, st) => Text('Error: $err'),
        ),
      ],
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final String conversationId;

  const _MembersTab({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final participants = ref.watch(conversationParticipantsProvider(conversationId));

    return participants.when(
      data: (participants) {
        return ListView.builder(
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  participant.userId.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(participant.customName ?? participant.userId),
              subtitle: Text(participant.role.value),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  if (participant.role != UserRole.admin)
                    PopupMenuItem(
                      child: const Text('Make Admin'),
                      onTap: () {
                        ref.read(chatServiceProvider).updateParticipantRole(
                          conversationId: conversationId,
                          userId: participant.userId,
                          role: UserRole.admin,
                        );
                      },
                    ),
                  PopupMenuItem(
                    child: const Text('Remove'),
                    onTap: () {
                      ref.read(chatServiceProvider).removeParticipant(
                        conversationId: conversationId,
                        userId: participant.userId,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
    );
  }
}

class _FilesTab extends StatelessWidget {
  final String conversationId;

  const _FilesTab({required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.description),
          title: Text('Project_THIX_2024.pdf'),
          subtitle: Text('2.4 Mo • Uploaded by Aminata'),
          trailing: Icon(Icons.download),
        ),
        ListTile(
          leading: Icon(Icons.image),
          title: Text('Campagne_Visuels_Semaine_23.pdf'),
          subtitle: Text('1.8 Mo • Uploaded by David'),
          trailing: Icon(Icons.download),
        ),
      ],
    );
  }
}

class _TasksTab extends ConsumerWidget {
  final String conversationId;

  const _TasksTab({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(conversationTasksProvider(conversationId));
    final cs = Theme.of(context).colorScheme;

    return tasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No tasks yet'),
            ),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              leading: Checkbox(
                value: task.status == 'completed',
                onChanged: (value) {
                  // Update task status
                },
              ),
              title: Text(task.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.assignedTo != null)
                    Text('Assigned to: ${task.assignedTo}'),
                  if (task.dueDate != null)
                    Text('Due: ${task.dueDate}'),
                  Container(
                    width: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority, cs),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () {},
                  ),
                  PopupMenuItem(
                    child: const Text('Delete'),
                    onTap: () {},
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
    );
  }

  Color _getPriorityColor(String priority, ColorScheme cs) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return cs.primary;
    }
  }
}

// Poll creation dialog
class PollCreationDialog extends StatefulWidget {
  final Function(String question, List<String> options, bool isAnonymous) onCreatePoll;

  const PollCreationDialog({
    Key? key,
    required this.onCreatePoll,
  }) : super(key: key);

  @override
  State<PollCreationDialog> createState() => _PollCreationDialogState();
}

class _PollCreationDialogState extends State<PollCreationDialog> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _optionControllers = [TextEditingController(), TextEditingController()];
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Create Poll'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                hintText: 'Poll question',
                labelText: 'Question',
              ),
            ),
            const SizedBox(height: 16),
            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Option ${index + 1}',
                    labelText: 'Option ${index + 1}',
                    suffixIcon: _optionControllers.length > 2
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _optionControllers.removeAt(index);
                              });
                            },
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
              onPressed: () {
                setState(() {
                  _optionControllers.add(TextEditingController());
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value ?? false;
                });
              },
              title: const Text('Anonymous voting'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final question = _questionController.text;
            final options = _optionControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();

            if (question.isNotEmpty && options.length >= 2) {
              widget.onCreatePoll(question, options, _isAnonymous);
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// Task creation dialog
class TaskCreationDialog extends StatefulWidget {
  final Function(String title, String? description, String priority, DateTime? dueDate) onCreateTask;

  const TaskCreationDialog({
    Key? key,
    required this.onCreateTask,
  }) : super(key: key);

  @override
  State<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends State<TaskCreationDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _priority = 'medium';
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Task title',
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Task description',
                labelText: 'Description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _priority,
              isExpanded: true,
              items: ['low', 'medium', 'high']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) {
                setState(() => _priority = value ?? 'medium');
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_dueDate == null ? 'No due date' : 'Due: ${_dueDate!.toLocal()}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.onCreateTask(
                _titleController.text,
                _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
                _priority,
                _dueDate,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
