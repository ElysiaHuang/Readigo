import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../util/constants.dart';
import '../util/firebase_utils.dart';

class ChatPage extends StatefulWidget {
  final String friendCode;
  const ChatPage({super.key, required this.friendCode});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _composer = TextEditingController();
  final _messages = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
  StreamSubscription? _relationshipSubscription;
  StreamSubscription? _messageSubscription;
  String? _ownCode;
  String? _chatId;
  String? _error;
  String _name = 'Reader';
  bool _loading = true,
      _blocked = false,
      _sending = false,
      _olderLoading = false,
      _hasOlder = true;
  DocumentReference<Map<String, dynamic>>? _pendingMessage;
  String? _pendingText;
  Query<Map<String, dynamic>> get _query => FirebaseFirestore.instance
      .collection('chat')
      .doc(_chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _ownCode = await FirebaseUtils.getCurrentUserFriendCode();
      if (_ownCode == null) throw Exception('Please sign in again.');
      final friend = await FirebaseUtils.getUserData(widget.friendCode);
      if (friend == null) {
        throw Exception('This account is no longer available.');
      }
      _name = friend['username']?.toString() ?? 'Reader';
      _chatId = ([_ownCode!, widget.friendCode]..sort()).join('_');
      final relationship = await FirebaseUtils.relationship(widget.friendCode);
      if (!mounted) return;
      _blocked =
          relationship['blockedByMe'] == true ||
          relationship['blockedByFriend'] == true;
      await _relationshipSubscription?.cancel();
      _relationshipSubscription = FirebaseFirestore.instance
          .collection('relationships')
          .doc(_chatId)
          .snapshots()
          .listen(
            (snapshot) {
              if (!mounted) return;
              final blocked =
                  !snapshot.exists ||
                  (snapshot.data()?['blockedBy'] as List? ?? []).isNotEmpty;
              if (blocked != _blocked) {
                setState(() {
                  _blocked = blocked;
                  _error = null;
                });
                if (blocked) {
                  _messageSubscription?.cancel();
                  setState(_messages.clear);
                } else {
                  _listen();
                }
              }
            },
            onError: (_) {
              if (mounted) {
                setState(() {
                  _blocked = true;
                  _messages.clear();
                  _error = 'Conversation unavailable. Please retry.';
                });
              }
            },
          );
      if (!_blocked) _listen();
      setState(() => _loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  void _listen() {
    _messageSubscription?.cancel();
    _messageSubscription = _query
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted || _blocked) return;
            setState(() {
              for (final doc in snapshot.docs) {
                _messages[doc.id] = doc;
              }
              _hasOlder = snapshot.docs.length == 50 || _messages.length > 50;
              _error = null;
            });
          },
          onError: (_) {
            if (mounted) {
              setState(() {
                _error = 'Could not load messages. Please retry.';
                _messages.clear();
              });
            }
          },
        );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _sorted =>
      _messages.values.toList()..sort((a, b) {
        final first =
            (a.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;
        final second =
            (b.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;
        return second.compareTo(first);
      });

  Future<void> _loadOlder() async {
    if (_olderLoading || _messages.isEmpty || _blocked) return;
    setState(() => _olderLoading = true);
    try {
      final page =
          await _query.startAfterDocument(_sorted.last).limit(50).get();
      if (!mounted || _blocked) return;
      setState(() {
        for (final doc in page.docs) {
          _messages[doc.id] = doc;
        }
        _hasOlder = page.docs.length == 50;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load older messages.')),
        );
      }
    } finally {
      if (mounted) setState(() => _olderLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (_sending || _blocked || text.isEmpty || _chatId == null) return;
    if (text.length > 2000) return;
    setState(() => _sending = true);
    // Retain the same document ID when retrying a failed delivery.
    if (_pendingText != text) {
      _pendingMessage =
          FirebaseFirestore.instance
              .collection('chat')
              .doc(_chatId)
              .collection('messages')
              .doc();
      _pendingText = text;
    }
    try {
      final existing = await _pendingMessage!
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (!existing.exists) {
        await _pendingMessage!
            .set({
              'senderId': _ownCode,
              'receiverId': widget.friendCode,
              'text': text,
              'timestamp': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 20));
      }
      if (!mounted) return;
      if (_composer.text.trim() == text) _composer.clear();
      _pendingMessage = null;
      _pendingText = null;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery not confirmed. Your draft is saved here; tap send to retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _relationshipSubscription?.cancel();
    _messageSubscription?.cancel();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _sorted;
    return Scaffold(
      appBar: AppBar(title: Text(_name)),
      body: SafeArea(
        child: Column(
          children: [
            if (_blocked)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Messaging is unavailable because this conversation is blocked or the account was deleted.',
                ),
              ),
            if (_error != null)
              ListTile(
                title: Text(_error!),
                trailing: TextButton(
                  onPressed: _initialize,
                  child: const Text('Retry'),
                ),
              ),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _blocked
                      ? const SizedBox.shrink()
                      : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return _hasOlder && messages.isNotEmpty
                                ? TextButton(
                                  onPressed: _olderLoading ? null : _loadOlder,
                                  child: Text(
                                    _olderLoading
                                        ? 'Loading…'
                                        : 'Load older messages',
                                  ),
                                )
                                : const SizedBox.shrink();
                          }
                          final data = messages[index].data(),
                              isMe = data['senderId'] == _ownCode;
                          return Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isMe ? Constants.sky : Constants.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(data['text']?.toString() ?? ''),
                            ),
                          );
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      enabled: !_blocked && !_loading && !_sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send message',
                    onPressed: _blocked || _sending || _loading ? null : _send,
                    icon:
                        _sending
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
