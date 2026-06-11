import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/map_selection_store.dart';
import 'package:foodshare/user_model.dart';
import 'package:http/http.dart' as http;

class DmPage extends StatefulWidget {
  const DmPage({super.key, required this.currentEmail, this.onUnreadChanged});

  final String currentEmail;
  final VoidCallback? onUnreadChanged;

  @override
  State<DmPage> createState() => _DmPageState();
}

class _DmPageState extends State<DmPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late Future<List<DmThread>> _threadsFuture;
  Future<List<DmCandidate>>? _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _threadsFuture = _fetchThreads();
    _suggestionsFuture = _fetchSuggestions();
    _searchController.addListener(_scheduleSuggestionSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_scheduleSuggestionSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<DmThread>> _fetchThreads() async {
    final uri = Uri.http('10.0.2.2:8000', '/dm/threads', {
      'email': widget.currentEmail,
    });
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('DMを取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final threads = data['threads'] as List<dynamic>? ?? [];

    return threads
        .map((thread) => DmThread.fromJson(thread as Map<String, dynamic>))
        .toList();
  }

  Future<List<DmCandidate>> _fetchSuggestions() async {
    final query = _searchController.text.trim();
    final uri = Uri.http('10.0.2.2:8000', '/dm/search-users', {
      'email': widget.currentEmail,
      if (query.isNotEmpty) 'query': query,
      'limit': '20',
    });
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('候補を取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final users = data['users'] as List<dynamic>? ?? [];
    final groups = data['groups'] as List<dynamic>? ?? [];

    return [
      ...users.map(
        (user) =>
            DmCandidate.user(FoodUser.fromJson(user as Map<String, dynamic>)),
      ),
      ...groups.map(
        (group) => DmCandidate.group(group as Map<String, dynamic>),
      ),
    ];
  }

  void _scheduleSuggestionSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _suggestionsFuture = _fetchSuggestions();
      });
    });
  }

  Future<void> _reloadThreads() async {
    final nextThreads = _fetchThreads();
    setState(() {
      _threadsFuture = nextThreads;
    });
    await nextThreads;
  }

  Future<void> _openThreadWithCandidate(DmCandidate candidate) async {
    final uri = candidate.isGroup
        ? Uri.parse('http://10.0.2.2:8000/dm/group-threads')
        : Uri.parse('http://10.0.2.2:8000/dm/threads');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        candidate.isGroup
            ? {
                'current_email': widget.currentEmail,
                'group_id': candidate.groupId,
              }
            : {
                'current_email': widget.currentEmail,
                'target_email': candidate.user!.email,
              },
      ),
    );

    if (!mounted) return;

    if (response.statusCode != 200) {
      var message = 'DMを開始できませんでした';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        message = data['detail'] as String? ?? message;
      } catch (_) {}

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final thread = DmThread(
      id: data['id'] as int? ?? 0,
      threadType: candidate.isGroup ? 'group' : 'direct',
      otherUser: candidate.user,
      groupName: candidate.isGroup ? candidate.title : '',
      groupMemberCount: candidate.memberCount,
      lastMessage: '',
      lastMessageAt: data['updated_at'] as String? ?? '',
      updatedAt: data['updated_at'] as String? ?? '',
      unreadCount: 0,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DmThreadPage(thread: thread, currentEmail: widget.currentEmail),
      ),
    );

    _searchController.clear();
    await _reloadThreads();
    widget.onUnreadChanged?.call();
  }

  Future<void> _openThread(DmThread thread) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DmThreadPage(thread: thread, currentEmail: widget.currentEmail),
      ),
    );
    await _reloadThreads();
    widget.onUnreadChanged?.call();
  }

  Future<bool> _deleteThread(DmThread thread) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DMを削除しますか？'),
        content: Text('${thread.displayName}とのDMを一覧から削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return false;

    final uri = Uri.http('10.0.2.2:8000', '/dm/threads/${thread.id}', {
      'email': widget.currentEmail,
      'thread_type': thread.threadType,
    });
    final response = await http.delete(uri);

    if (!mounted) return false;

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('DMを削除できませんでした')));
      return false;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('DMを削除しました')));
    widget.onUnreadChanged?.call();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return ColoredBox(
      color: foodSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 54,
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'フォロー中のアカウントを検索',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: hasQuery
                        ? IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: foodLine),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: foodLine),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: hasQuery
                    ? _SuggestionList(
                        suggestionsFuture: _suggestionsFuture,
                        onCandidatePressed: _openThreadWithCandidate,
                      )
                    : _ThreadList(
                        threadsFuture: _threadsFuture,
                        onThreadPressed: _openThread,
                        onThreadDeleted: _deleteThread,
                        onRefresh: _reloadThreads,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DmThreadPage extends StatefulWidget {
  const DmThreadPage({
    super.key,
    required this.thread,
    required this.currentEmail,
  });

  final DmThread thread;
  final String currentEmail;

  @override
  State<DmThreadPage> createState() => _DmThreadPageState();
}

class _DmThreadPageState extends State<DmThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  late Future<List<DmMessage>> _messagesFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<List<DmMessage>> _fetchMessages() async {
    final uri = Uri.http(
      '10.0.2.2:8000',
      '/dm/threads/${widget.thread.id}/messages',
      {'email': widget.currentEmail, 'thread_type': widget.thread.threadType},
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('メッセージを取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = data['messages'] as List<dynamic>? ?? [];

    return messages
        .map((message) => DmMessage.fromJson(message as Map<String, dynamic>))
        .toList();
  }

  Future<List<FoodUser>> _fetchMembers() async {
    final uri = Uri.http(
      '10.0.2.2:8000',
      '/dm/threads/${widget.thread.id}/members',
      {'email': widget.currentEmail, 'thread_type': widget.thread.threadType},
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('メンバーを取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>? ?? [];

    return members
        .map((member) => FoodUser.fromJson(member as Map<String, dynamic>))
        .toList();
  }

  void _reloadMessages() {
    setState(() {
      _messagesFuture = _fetchMessages();
    });
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    final response = await http.post(
      Uri.http('10.0.2.2:8000', '/dm/threads/${widget.thread.id}/messages', {
        'thread_type': widget.thread.threadType,
      }),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sender_email': widget.currentEmail, 'body': body}),
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('メッセージを送信できませんでした')));
      return;
    }

    _messageController.clear();
    _reloadMessages();
  }

  Future<void> _sendPoll() async {
    final selections = MapSelectionStore.pollSelections.value;

    if (selections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('地図でアンケート候補を選択してください')));
      return;
    }

    final selectedKeys = <String>{};
    final chosen = await showModalBottomSheet<List<MapShopSelection>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'アンケート店舗を選択',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: selections.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final selection = selections[index];
                          final selected = selectedKeys.contains(selection.key);

                          return CheckboxListTile(
                            value: selected,
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selectedKeys.add(selection.key);
                                } else {
                                  selectedKeys.remove(selection.key);
                                }
                              });
                            },
                            title: Text(selection.shopName),
                            subtitle: Text(selection.location),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: selectedKeys.isEmpty
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                selections
                                    .where(
                                      (selection) =>
                                          selectedKeys.contains(selection.key),
                                    )
                                    .toList(),
                              );
                            },
                      icon: const Icon(Icons.how_to_vote),
                      label: const Text('アンケートを送信'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (chosen == null || chosen.isEmpty) return;
    if (!mounted) return;

    if (chosen.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('アンケート候補は2つ以上選択してください')));
      return;
    }

    final response = await http.post(
      Uri.http('10.0.2.2:8000', '/dm/threads/${widget.thread.id}/polls', {
        'thread_type': widget.thread.threadType,
      }),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_email': widget.currentEmail,
        'options': chosen
            .map(
              (selection) => {
                'shop_key': selection.key,
                'shop_name': selection.shopName,
                'location': selection.location,
              },
            )
            .toList(),
      }),
    );

    if (!mounted) return;

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('アンケートを送信できませんでした')));
      return;
    }

    _reloadMessages();
  }

  Future<void> _openRoulette() async {
    List<FoodUser> members;

    try {
      members = await _fetchMembers();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('メンバーを取得できませんでした')));
      return;
    }

    if (!mounted) return;

    if (members.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ルーレットには2人以上必要です')));
      return;
    }

    final selectedEmails = members.map((member) => member.email).toSet();
    final selectedMembers = await showModalBottomSheet<List<FoodUser>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ルーレットメンバー',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final selected = selectedEmails.contains(
                            member.email,
                          );

                          return CheckboxListTile(
                            value: selected,
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selectedEmails.add(member.email);
                                } else {
                                  selectedEmails.remove(member.email);
                                }
                              });
                            },
                            secondary: _RouletteAvatar(user: member, size: 42),
                            title: Text(_displayUserName(member)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: selectedEmails.length < 2
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                members
                                    .where(
                                      (member) =>
                                          selectedEmails.contains(member.email),
                                    )
                                    .toList(),
                              );
                            },
                      icon: const Icon(Icons.casino_outlined),
                      label: const Text('ルーレット開始'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selectedMembers == null || selectedMembers.length < 2) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RouletteResultDialog(members: selectedMembers),
    );
  }

  Future<void> _votePoll(DmPoll poll, Set<int> optionIds) async {
    if (optionIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('回答を選択してください')));
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/dm/polls/${poll.id}/vote'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_email': widget.currentEmail,
        'option_ids': optionIds.toList(),
      }),
    );

    if (!mounted) return;

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('アンケートに回答できませんでした')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('回答しました')));
    _reloadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.thread.displayName)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<DmMessage>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: foodMuted),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      '最初のメッセージを送ってみよう',
                      style: TextStyle(color: foodMuted),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMine = message.senderEmail == widget.currentEmail;

                    final poll = message.poll;

                    if (poll != null) {
                      return _PollMessageCard(
                        poll: poll,
                        isMine: isMine,
                        onVote: (optionIds) => _votePoll(poll, optionIds),
                      );
                    }

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? foodPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: isMine ? null : Border.all(color: foodLine),
                        ),
                        child: Text(
                          message.body,
                          style: TextStyle(
                            color: isMine ? Colors.white : foodInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: foodLine)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'メッセージを入力',
                        filled: true,
                        fillColor: foodSurface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: foodLine),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: foodLine),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'ルーレット',
                    onPressed: _openRoulette,
                    icon: const Icon(Icons.casino_outlined),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'アンケート',
                    onPressed: _sendPoll,
                    icon: const Icon(Icons.how_to_vote_outlined),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.suggestionsFuture,
    required this.onCandidatePressed,
  });

  final Future<List<DmCandidate>>? suggestionsFuture;
  final ValueChanged<DmCandidate> onCandidatePressed;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DmCandidate>>(
      future: suggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: foodMuted),
            ),
          );
        }

        final candidates = snapshot.data ?? [];

        if (candidates.isEmpty) {
          return const Center(
            child: Text(
              'DMできるアカウント/グループがありません',
              style: TextStyle(color: foodMuted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: candidates.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final candidate = candidates[index];
            return _DmRow(
              title: candidate.title,
              subtitle: candidate.subtitle,
              isGroup: candidate.isGroup,
              trailing: const Icon(Icons.chat_bubble_outline),
              onPressed: () => onCandidatePressed(candidate),
            );
          },
        );
      },
    );
  }
}

class _RouletteResultDialog extends StatefulWidget {
  const _RouletteResultDialog({required this.members});

  final List<FoodUser> members;

  @override
  State<_RouletteResultDialog> createState() => _RouletteResultDialogState();
}

class _RouletteResultDialogState extends State<_RouletteResultDialog> {
  final _random = Random();
  Timer? _timer;
  late FoodUser _currentUser;
  bool _finished = false;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.members.first;
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) return;
      setState(() {
        _tick += 1;
        _currentUser = widget.members[_random.nextInt(widget.members.length)];
        if (_tick >= 28) {
          _finished = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_finished ? '当たり！' : 'ルーレット中'),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: Column(
          key: ValueKey('${_currentUser.email}-$_tick'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _RouletteAvatar(user: _currentUser, size: 176),
            const SizedBox(height: 18),
            Text(
              _displayUserName(_currentUser),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: foodInk,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _finished ? () => Navigator.pop(context) : null,
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

class _RouletteAvatar extends StatelessWidget {
  const _RouletteAvatar({required this.user, required this.size});

  final FoodUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: foodSurface,
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: foodLine),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.04),
          child: Image.network(
            user.profileImageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Center(child: Icon(Icons.person, color: foodMuted));
            },
          ),
        ),
      ),
    );
  }
}

String _displayUserName(FoodUser user) {
  return user.username.isEmpty ? 'ユーザー' : user.username;
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({
    required this.threadsFuture,
    required this.onThreadPressed,
    required this.onThreadDeleted,
    required this.onRefresh,
  });

  final Future<List<DmThread>> threadsFuture;
  final ValueChanged<DmThread> onThreadPressed;
  final Future<bool> Function(DmThread) onThreadDeleted;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DmThread>>(
      future: threadsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: foodMuted),
            ),
          );
        }

        final threads = snapshot.data ?? [];

        if (threads.isEmpty) {
          return const Center(
            child: Text('まだDMはありません', style: TextStyle(color: foodMuted)),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return Dismissible(
                key: ValueKey('${thread.threadType}-${thread.id}'),
                direction: DismissDirection.startToEnd,
                confirmDismiss: (_) => onThreadDeleted(thread),
                onDismissed: (_) => onRefresh(),
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: _DmRow(
                  title: thread.displayName,
                  subtitle: thread.lastMessage.isEmpty
                      ? 'メッセージを開始'
                      : thread.lastMessage,
                  isGroup: thread.isGroup,
                  unreadCount: thread.unreadCount,
                  trailing: const Icon(Icons.chevron_right),
                  onPressed: () => onThreadPressed(thread),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DmRow extends StatelessWidget {
  const _DmRow({
    required this.title,
    required this.onPressed,
    required this.isGroup,
    this.unreadCount = 0,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final VoidCallback onPressed;
  final bool isGroup;
  final int unreadCount;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: isGroup ? const Color(0xFFFFEFE3) : foodLine,
              child: Icon(
                isGroup ? Icons.groups_2_outlined : Icons.person,
                color: isGroup ? foodPrimary : foodMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: foodInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: foodMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              Badge.count(
                count: unreadCount,
                backgroundColor: Colors.redAccent,
                textColor: Colors.white,
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

class _PollMessageCard extends StatefulWidget {
  const _PollMessageCard({
    required this.poll,
    required this.isMine,
    required this.onVote,
  });

  final DmPoll poll;
  final bool isMine;
  final ValueChanged<Set<int>> onVote;

  @override
  State<_PollMessageCard> createState() => _PollMessageCardState();
}

class _PollMessageCardState extends State<_PollMessageCard> {
  late Set<int> _selectedOptionIds;

  @override
  void initState() {
    super.initState();
    _selectedOptionIds = widget.poll.votedOptionIds.toSet();
  }

  @override
  void didUpdateWidget(covariant _PollMessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poll.id != widget.poll.id) {
      _selectedOptionIds = widget.poll.votedOptionIds.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: foodLine),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_vote, color: foodPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.poll.question,
                    style: const TextStyle(
                      color: foodInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '合計 ${widget.poll.totalVotes}票',
              style: const TextStyle(color: foodMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            ...widget.poll.options.map((option) {
              final selected = _selectedOptionIds.contains(option.id);
              final ratio = widget.poll.totalVotes == 0
                  ? 0.0
                  : option.voteCount / widget.poll.totalVotes;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedOptionIds.remove(option.id);
                      } else {
                        _selectedOptionIds.add(option.id);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedOptionIds.add(option.id);
                              } else {
                                _selectedOptionIds.remove(option.id);
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.shopName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${option.percent(widget.poll.totalVotes)}% ・ ${option.voteCount}票',
                                    style: const TextStyle(
                                      color: foodMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                option.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: foodMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  backgroundColor: foodLine,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        foodPrimary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _selectedOptionIds.isEmpty
                  ? null
                  : () => widget.onVote(_selectedOptionIds),
              child: const Text('回答する'),
            ),
          ],
        ),
      ),
    );
  }
}

class DmThread {
  const DmThread({
    required this.id,
    required this.threadType,
    required this.otherUser,
    required this.groupName,
    required this.groupMemberCount,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.updatedAt,
    required this.unreadCount,
  });

  final int id;
  final String threadType;
  final FoodUser? otherUser;
  final String groupName;
  final int groupMemberCount;
  final String lastMessage;
  final String lastMessageAt;
  final String updatedAt;
  final int unreadCount;

  bool get isGroup => threadType == 'group';

  String get displayName {
    if (isGroup) return groupName;
    final user = otherUser;
    if (user == null) return '';
    return user.username.isEmpty ? 'ユーザー' : user.username;
  }

  factory DmThread.fromJson(Map<String, dynamic> json) {
    final threadType = json['thread_type'] as String? ?? 'direct';
    final group = json['group'] as Map<String, dynamic>? ?? {};

    return DmThread(
      id: json['id'] as int? ?? 0,
      threadType: threadType,
      otherUser: threadType == 'group'
          ? null
          : FoodUser.fromJson(
              json['other_user'] as Map<String, dynamic>? ?? {},
            ),
      groupName: group['name'] as String? ?? '',
      groupMemberCount: group['member_count'] as int? ?? 0,
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageAt: json['last_message_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class DmCandidate {
  const DmCandidate._({
    required this.isGroup,
    required this.user,
    required this.groupId,
    required this.groupName,
    required this.memberCount,
  });

  factory DmCandidate.user(FoodUser user) {
    return DmCandidate._(
      isGroup: false,
      user: user,
      groupId: 0,
      groupName: '',
      memberCount: 0,
    );
  }

  factory DmCandidate.group(Map<String, dynamic> json) {
    return DmCandidate._(
      isGroup: true,
      user: null,
      groupId: json['id'] as int? ?? 0,
      groupName: json['name'] as String? ?? '',
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  final bool isGroup;
  final FoodUser? user;
  final int groupId;
  final String groupName;
  final int memberCount;

  String get title {
    if (isGroup) return groupName;
    final foodUser = user;
    if (foodUser == null) return '';
    return foodUser.username.isEmpty ? 'ユーザー' : foodUser.username;
  }

  String get subtitle {
    if (isGroup) return '$memberCount人のグループ';
    return 'ユーザー';
  }
}

class DmMessage {
  const DmMessage({
    required this.id,
    required this.senderEmail,
    required this.body,
    required this.createdAt,
    required this.poll,
  });

  final int id;
  final String senderEmail;
  final String body;
  final String createdAt;
  final DmPoll? poll;

  factory DmMessage.fromJson(Map<String, dynamic> json) {
    final pollJson = json['poll'] as Map<String, dynamic>?;

    return DmMessage(
      id: json['id'] as int? ?? 0,
      senderEmail: json['sender_email'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      poll: pollJson == null ? null : DmPoll.fromJson(pollJson),
    );
  }
}

class DmPoll {
  const DmPoll({
    required this.id,
    required this.question,
    required this.createdBy,
    required this.options,
  });

  final int id;
  final String question;
  final String createdBy;
  final List<DmPollOption> options;

  int get totalVotes {
    return options.fold(0, (total, option) => total + option.voteCount);
  }

  List<int> get votedOptionIds => options
      .where((option) => option.votedByMe)
      .map((option) => option.id)
      .toList();

  factory DmPoll.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as List<dynamic>? ?? [];

    return DmPoll(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? 'アンケート',
      createdBy: json['created_by'] as String? ?? '',
      options: options
          .map(
            (option) => DmPollOption.fromJson(option as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class DmPollOption {
  const DmPollOption({
    required this.id,
    required this.shopName,
    required this.location,
    required this.voteCount,
    required this.votedByMe,
  });

  final int id;
  final String shopName;
  final String location;
  final int voteCount;
  final bool votedByMe;

  int percent(int totalVotes) {
    if (totalVotes == 0) return 0;
    return ((voteCount / totalVotes) * 100).round();
  }

  factory DmPollOption.fromJson(Map<String, dynamic> json) {
    return DmPollOption(
      id: json['id'] as int? ?? 0,
      shopName: json['shop_name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      voteCount: json['vote_count'] as int? ?? 0,
      votedByMe: json['voted_by_me'] as bool? ?? false,
    );
  }
}
