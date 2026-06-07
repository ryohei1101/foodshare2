import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/user_model.dart';
import 'package:http/http.dart' as http;

class DmPage extends StatefulWidget {
  const DmPage({super.key, required this.currentEmail});

  final String currentEmail;

  @override
  State<DmPage> createState() => _DmPageState();
}

class _DmPageState extends State<DmPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late Future<List<DmThread>> _threadsFuture;
  Future<List<FoodUser>>? _suggestionsFuture;

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

  Future<List<FoodUser>> _fetchSuggestions() async {
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

    return users
        .map((user) => FoodUser.fromJson(user as Map<String, dynamic>))
        .toList();
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

  Future<void> _openThreadWithUser(FoodUser user) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/dm/threads'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'current_email': widget.currentEmail,
        'target_email': user.email,
      }),
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
      otherUser: user,
      lastMessage: '',
      lastMessageAt: data['updated_at'] as String? ?? '',
      updatedAt: data['updated_at'] as String? ?? '',
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
              const Text(
                'メッセージ',
                style: TextStyle(
                  color: foodInk,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
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
                        onUserPressed: _openThreadWithUser,
                      )
                    : _ThreadList(
                        threadsFuture: _threadsFuture,
                        onThreadPressed: _openThread,
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
      {'email': widget.currentEmail},
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
      Uri.parse('http://10.0.2.2:8000/dm/threads/${widget.thread.id}/messages'),
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

  @override
  Widget build(BuildContext context) {
    final displayName = widget.thread.otherUser.username.isEmpty
        ? widget.thread.otherUser.email
        : widget.thread.otherUser.username;

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
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
    required this.onUserPressed,
  });

  final Future<List<FoodUser>>? suggestionsFuture;
  final ValueChanged<FoodUser> onUserPressed;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodUser>>(
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

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'DMできるフォロー中アカウントがありません',
              style: TextStyle(color: foodMuted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserRow(
              user: user,
              trailing: const Icon(Icons.chat_bubble_outline),
              onPressed: () => onUserPressed(user),
            );
          },
        );
      },
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({
    required this.threadsFuture,
    required this.onThreadPressed,
    required this.onRefresh,
  });

  final Future<List<DmThread>> threadsFuture;
  final ValueChanged<DmThread> onThreadPressed;
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
              return _UserRow(
                user: thread.otherUser,
                subtitle: thread.lastMessage.isEmpty
                    ? 'メッセージを開始'
                    : thread.lastMessage,
                trailing: const Icon(Icons.chevron_right),
                onPressed: () => onThreadPressed(thread),
              );
            },
          ),
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onPressed,
    this.subtitle,
    this.trailing,
  });

  final FoodUser user;
  final VoidCallback onPressed;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final displayName = user.username.isEmpty ? user.email : user.username;

    return InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                user.profileImageUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 46,
                    height: 46,
                    color: foodLine,
                    alignment: Alignment.center,
                    child: const Icon(Icons.person, color: foodMuted),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: foodInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: foodMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

class DmThread {
  const DmThread({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.updatedAt,
  });

  final int id;
  final FoodUser otherUser;
  final String lastMessage;
  final String lastMessageAt;
  final String updatedAt;

  factory DmThread.fromJson(Map<String, dynamic> json) {
    return DmThread(
      id: json['id'] as int? ?? 0,
      otherUser: FoodUser.fromJson(
        json['other_user'] as Map<String, dynamic>? ?? {},
      ),
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageAt: json['last_message_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class DmMessage {
  const DmMessage({
    required this.id,
    required this.senderEmail,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final String senderEmail;
  final String body;
  final String createdAt;

  factory DmMessage.fromJson(Map<String, dynamic> json) {
    return DmMessage(
      id: json['id'] as int? ?? 0,
      senderEmail: json['sender_email'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
