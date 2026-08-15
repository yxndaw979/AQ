import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:math';

//====新增导入====
import 'llm/local_llm_service.dart';
import 'pages/model_manager_page.dart';

part 'main.g.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
  });
}

//M：记忆实体
@HiveType(typeId: 2)
class AiMemory extends HiveObject {
  @HiveField(0)
  String content;

  @HiveField(1)
  DateTime createTime;

  @HiveField(2)
  int importance; //1‑5

  AiMemory({
    required this.content,
    required this.createTime,
    required this.importance,
  });
}

//会话模型
@HiveType(typeId: 0)
class ChatSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String previewText;

  @HiveField(3)
  String timeLabel;

  @HiveField(4)
  int unreadCount;

  @HiveField(5)
  int favorValue;

  @HiveField(6)
  List<ChatMessage> messages;

  @HiveField(7)
  String persona;

  @HiveField(8)
  List<AiMemory> memoryList;

  ChatSession({
    required this.id,
    required this.title,
    required this.previewText,
    required this.timeLabel,
    required this.unreadCount,
    required this.favorValue,
    this.persona = "",
    List<ChatMessage>? messages,
    List<AiMemory>? memoryList,
  })  : messages = messages ?? [],
        memoryList = memoryList ?? [];
}

//消息模型
@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final bool isUser;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime time;

  ChatMessage({
    required this.isUser,
    required this.content,
    required this.time,
  });
}

class AiStatusItem {
  final String emoji;
  final String label;
  AiStatusItem({required this.emoji, required this.label});
}

Color getFavorBgColor(int favor) {
  if (favor >= 100) {
    return const Color(0xff27ae60);
  } else if (favor >= 40) {
    return const Color(0xff2980b9);
  } else if (favor >= 0) {
    return const Color(0xfff39c12);
  } else {
    return const Color(0xffc0392b);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ChatSessionAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(AiMemoryAdapter());
  await Hive.openBox<ChatSession>("sessionBox");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AI好友",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;
  String _userName = "用户";
  String _userDesc = "AI聊天好友使用者";
  late Box<ChatSession> _sessionBox;
  List<ChatSession> _sessionList = [];

  @override
  void initState() {
    super.initState();
    _sessionBox = Hive.box<ChatSession>("sessionBox");
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() {
      _sessionList = _sessionBox.values.toList();
    });
  }

  Future<void> _removeSessionById(String id) async {
    final find = _sessionList.where((s) => s.id == id).firstOrNull;
    if (find != null) {
      await find.delete();
    }
    await _loadSession();
  }

  Future<void> _showCreateDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                title: const Text("新建人物"),
                onTap: () async {
                  Navigator.pop(ctx);
                  ChatSession newSession = ChatSession(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: "新人物对话",
                    previewText: "开启新对话！",
                    timeLabel: "现在",
                    unreadCount: 0,
                    favorValue: 20,
                    persona: "",
                  );
                  await _sessionBox.add(newSession);
                  await _loadSession();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChatPage(
                        onGlobalRefresh: _loadSession,
                        session: newSession,
                        onSessionDestroy: (sid) {
                          _removeSessionById(sid);
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.group_add_outlined, color: Colors.blue),
                title: const Text("新建群聊"),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("群聊功能开发中")),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionItem(ChatSession item) {
    double progressUiValue;
    if (item.favorValue <= 0) {
      progressUiValue = 0;
    } else {
      progressUiValue = (item.favorValue / 100).clamp(0.0, 1.0);
    }
    Color progressColor = getFavorBgColor(item.favorValue);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ChatPage(
              onGlobalRefresh: _loadSession,
              session: item,
              onSessionDestroy: (sid) {
                _removeSessionById(sid);
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Text("AI", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.timeLabel,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progressUiValue,
                            backgroundColor: Colors.grey.shade200,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.previewText,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${item.unreadCount}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            )
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editUserName() {
    final ctrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("修改昵称"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () {
              setState(() {
                _userName = ctrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text("确定"),
          )
        ],
      ),
    );
  }

  void _editUserDesc() {
    final ctrl = TextEditingController(text: _userDesc);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("修改账号简介"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () {
              setState(() {
                _userDesc = ctrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text("确定"),
          )
        ],
      ),
    );
  }

  void _changeAvatarTip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("更换头像"),
        content: const Text("图片选择功能待后续开发"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("确定"))
        ],
      ),
    );
  }

  Widget _buildFavorListItem(ChatSession session, BuildContext drCtx) {
    double progressUiValue;
    if (session.favorValue <= 0) {
      progressUiValue = 0;
    } else {
      progressUiValue = (session.favorValue / 100).clamp(0.0, 1.0);
    }
    Color progressColor = getFavorBgColor(session.favorValue);
    return InkWell(
      onTap: () {
        Navigator.pop(drCtx);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ChatPage(
              onGlobalRefresh: _loadSession,
              session: session,
              onSessionDestroy: (sid) {
                _removeSessionById(sid);
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFDDEAF7), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 24, child: Text("AI")),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progressUiValue,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("好感：${session.favorValue}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe8f2fc),
      drawer: Drawer(
        backgroundColor: const Color(0xffe8f2fc),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration:
                  BoxDecoration(color: Colors.blue.withValues(alpha: 0.15)),
              currentAccountPicture: InkWell(
                onTap: _changeAvatarTip,
                child: const CircleAvatar(child: Text("我")),
              ),
              accountName: InkWell(
                onTap: _editUserName,
                child: Text(_userName),
              ),
              accountEmail: InkWell(
                onTap: _editUserDesc,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_userDesc),
                    const SizedBox(height: 2),
                    Text(
                      "点击头像/昵称/简介编辑",
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _sessionList.length,
                itemBuilder: (drCtx, idx) {
                  return _buildFavorListItem(_sessionList[idx], drCtx);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child:
                  Text("Version:1.0.0", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.blue.withValues(alpha: 0.12),
        leading: Builder(
          builder: (ctx) {
            return InkWell(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(child: Text("我")),
              ),
            );
          },
        ),
        title: const SizedBox(),
        actions: [
          const Icon(Icons.notifications_outlined, color: Colors.blue),
          const SizedBox(width: 12),
          const Icon(Icons.more_horiz, color: Colors.blue),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _sessionList.isEmpty
                ? const Center(child: Text("暂无会话，点击加号新建角色"))
                : ListView.builder(
                    itemCount: _sessionList.length,
                    itemBuilder: (ctx, idx) {
                      return _buildSessionItem(_sessionList[idx]);
                    },
                  ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        currentIndex: _currentTabIndex,
        onTap: (idx) {
          setState(() {
            _currentTabIndex = idx;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: "聊天"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: "联系人"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: "设置"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), label: "个人资料"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.withValues(alpha: 0.75),
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add_circle_outline, color: Colors.white),
      ),
    );
  }
}

// ==========记忆编辑页面==========
class MemoryEditPage extends StatefulWidget {
  final ChatSession session;
  const MemoryEditPage({super.key, required this.session});

  @override
  State<MemoryEditPage> createState() => _MemoryEditPageState();
}

class _MemoryEditPageState extends State<MemoryEditPage> {
  List<AiMemory> get _memories => widget.session.memoryList;

  void _openMemoryEditDialog({AiMemory? editMem}) {
    final contentCtrl = TextEditingController(text: editMem?.content ?? "");
    int selectImportance = editMem?.importance ?? 3;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editMem == null ? "新增记忆" : "编辑记忆"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                minLines: 3,
                decoration: const InputDecoration(
                    hintText: "输入记忆内容", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (dialogCtx, setDialogState) {
                  return Row(
                    children: [
                      const Text("重要度："),
                      ...List.generate(5, (i) {
                        int val = i + 1;
                        return Radio<int>(
                          value: val,
                          groupValue: selectImportance,
                          onChanged: (v) {
                            setDialogState(() {
                              selectImportance = v!;
                            });
                          },
                        );
                      })
                    ],
                  );
                },
              )
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () async {
              final txt = contentCtrl.text.trim();
              if (txt.isEmpty) return;
              if (editMem != null) {
                editMem.content = txt;
                editMem.importance = selectImportance;
              } else {
                AiMemory newM = AiMemory(
                    content: txt,
                    createTime: DateTime.now(),
                    importance: selectImportance);
                _memories.add(newM);
              }
              await widget.session.save();
              if (mounted) setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text("保存"),
          )
        ],
      ),
    );
  }

  void _deleteMemoryDialog(AiMemory mem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("删除记忆"),
        content: const Text("确定删除这条记忆？该操作不可恢复。"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () async {
              _memories.remove(mem);
              await widget.session.save();
              if (mounted) setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("记忆管理"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _openMemoryEditDialog(),
      ),
      body: _memories.isEmpty
          ? const Center(child: Text("暂无记忆，点击右下角加号新增"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _memories.length,
              itemBuilder: (ctx, idx) {
                final m = _memories[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    onTap: () => _openMemoryEditDialog(editMem: m),
                    onLongPress: () => _deleteMemoryDialog(m),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.content, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("重要度：${m.importance}/5",
                                  style: const TextStyle(
                                      color: Colors.blueGrey, fontSize: 12)),
                              Text(
                                  "${m.createTime.month}/${m.createTime.day} ${m.createTime.hour}:${m.createTime.minute}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey))
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text("点击编辑｜长按删除",
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey))
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final ChatSession session;
  final Future<void> Function() onGlobalRefresh;
  final Function(String sessionId) onSessionDestroy;

  const ChatPage({
    super.key,
    required this.session,
    required this.onGlobalRefresh,
    required this.onSessionDestroy,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  //====本地LLM服务实例====
  final LocalLlmService _llmService = LocalLlmService();

  late String _roleName;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _aiLoading = false;
  bool _dissolving = false;
  late AnimationController _dissolveAnimCtrl;
  final List<Particle> _particles = [];

  final List<AiStatusItem> _aiStatusList = [
    AiStatusItem(emoji: "🟢", label: "在线"),
    AiStatusItem(emoji: "🥰", label: "超级开心"),
    AiStatusItem(emoji: "😊", label: "开心"),
    AiStatusItem(emoji: "🤔", label: "思考中"),
    AiStatusItem(emoji: "💬", label: "输入中"),
    AiStatusItem(emoji: "😐", label: "平淡"),
    AiStatusItem(emoji: "😒", label: "不耐烦"),
  ];
  late AiStatusItem _currentAiStatus;

  @override
  void initState() {
    super.initState();
    _roleName = widget.session.title;
    _currentAiStatus = _aiStatusList[0];
    _dissolveAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
  }

  @override
  void dispose() {
    //释放模型内存
    _llmService.unloadModel();

    _dissolveAnimCtrl.dispose();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _generateParticles(double width, double height) {
    _particles.clear();
    Random rnd = Random();
    for (int i = 0; i < 220; i++) {
      _particles.add(Particle(
        x: rnd.nextDouble() * width,
        y: rnd.nextDouble() * height,
        vx: (rnd.nextDouble() - 0.5) * 2.2,
        vy: (rnd.nextDouble() - 0.5) * 2.2,
        size: 2 + rnd.nextDouble() * 4,
        alpha: 0.85,
      ));
    }
  }

  Future<void> _triggerDissolve() async {
    if (_dissolving) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red[700],
        title: const Text(
          "警告",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "我讨厌你……",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "确认",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _dissolving = true;
    });
    final size = MediaQuery.of(context).size;
    _generateParticles(size.width, size.height);
    _dissolveAnimCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      await widget.session.delete();
      await widget.onGlobalRefresh();
      widget.onSessionDestroy(widget.session.id);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => route.isFirst,
      );
    }
  }

  AiStatusItem _getStatusByFavor(int favor) {
    if (favor >= 120) {
      return _aiStatusList[1];
    } else if (favor >= 70) {
      return _aiStatusList[2];
    } else if (favor >= 35) {
      return _aiStatusList[5];
    } else {
      return _aiStatusList[6];
    }
  }

  void _simExtractMemory(String userText) {
    List<String> keywords = ["我叫", "我喜欢", "我的", "以后", "我想要", "我讨厌"];
    bool needMem = keywords.any((k) => userText.contains(k));
    if (needMem) {
      AiMemory mem = AiMemory(
        content: "用户提到：$userText",
        createTime: DateTime.now(),
        importance: Random().nextInt(3) + 3,
      );
      widget.session.memoryList.add(mem);
    }
  }

  Future<void> _editRoleName() async {
    final ctrl = TextEditingController(text: _roleName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("修改角色名称"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _roleName = newName;
                });
                widget.session.title = newName;
                await widget.session.save();
                await widget.onGlobalRefresh();
              }
              Navigator.pop(ctx);
            },
            child: const Text("确定"),
          )
        ],
      ),
    );
  }

  void _editRoleAvatar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("更换角色头像"),
        content: const Text("头像选择功能待开发"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("确定"))
        ],
      ),
    );
  }

  void _openPersonaEditDialog() {
    final TextEditingController personaCtrl =
        TextEditingController(text: widget.session.persona);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("角色设定"),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: personaCtrl,
            maxLines: 10,
            minLines: 6,
            decoration: const InputDecoration(
              hintText: "填写角色性格、背景、说话风格、经历等\n示例：性格傲娇，说话简短，容易生气...",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () async {
              setState(() {
                widget.session.persona = personaCtrl.text;
              });
              await widget.session.save();
              await widget.onGlobalRefresh();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("角色设定已保存")));
            },
            child: const Text("保存"),
          )
        ],
      ),
    );
  }

  void _showStatusSelectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("切换角色状态"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _aiStatusList.length,
            itemBuilder: (dCtx, idx) {
              final item = _aiStatusList[idx];
              return ListTile(
                title: Text("${item.emoji}  ${item.label}"),
                onTap: () {
                  setState(() {
                    _currentAiStatus = item;
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _onSideMenuItemTap(String name) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("点击：$name，页面待开发")),
    );
  }

  //====完整新版sendMessage====
  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _aiLoading || _dissolving) return;

    if (!_llmService.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请先到侧边栏【本地模型管理】加载模型！")),
      );
      return;
    }

    setState(() {
      widget.session.messages.add(ChatMessage(
        isUser: true,
        content: text,
        time: DateTime.now(),
      ));
      _inputCtrl.clear();
      _aiLoading = true;
      _currentAiStatus = _aiStatusList[3];
    });

    _simExtractMemory(text);
    await widget.session.save();
    _scrollBottom();

    setState(() {
      _currentAiStatus = _aiStatusList[4];
    });

    try {
      String prompt = _llmService.buildChatPrompt(
          persona: widget.session.persona,
          memoryList: widget.session.memoryList,
          history: widget.session.messages,
          userInput: text);

      String aiResp = await _llmService.generateResponse(prompt);

      int delta = Random().nextInt(9) - 3;
      int newFavor = widget.session.favorValue + delta;
      newFavor = newFavor.clamp(-100, 200);
      widget.session.favorValue = newFavor;
      AiStatusItem endStatus = _getStatusByFavor(newFavor);

      setState(() {
        widget.session.messages.add(ChatMessage(
          isUser: false,
          content: aiResp,
          time: DateTime.now(),
        ));
        _aiLoading = false;
        _currentAiStatus = endStatus;
      });

      await widget.session.save();
      await widget.onGlobalRefresh();
      _scrollBottom();

      if (widget.session.favorValue <= -100) {
        await _triggerDissolve();
      }
    } catch (e) {
      setState(() {
        _aiLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("推理异常：$e")),
        );
      }
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xffe8f2fc),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration:
                  BoxDecoration(color: Colors.blue.withValues(alpha: 0.15)),
              currentAccountPicture: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _editRoleAvatar();
                },
                child: const CircleAvatar(child: Text("AI")),
              ),
              accountName: InkWell(
                onTap: _editRoleName,
                child: Text(
                  _roleName,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              accountEmail: const Text("点击头像/名字进行自定义"),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    title: const Text("角色设定"),
                    onTap: () {
                      Navigator.pop(context);
                      _openPersonaEditDialog();
                    },
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  ListTile(
                    title: const Text("长期记忆"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  MemoryEditPage(session: widget.session)));
                    },
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  ListTile(
                    title: const Text("短期记忆"),
                    onTap: () => _onSideMenuItemTap("短期记忆"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  ListTile(
                    title: const Text("记忆胶囊"),
                    onTap: () => _onSideMenuItemTap("记忆胶囊"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  //====新增本地模型管理入口====
                  ListTile(
                    title: const Text("本地模型管理"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ModelManagerPage()));
                    },
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("当前人设预览：",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                          widget.session.persona.isNotEmpty
                              ? widget.session.persona
                              : "暂无设定，请点击【角色设定】编辑",
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text("已保存记忆：",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          widget.session.memoryList.isNotEmpty
                              ? widget.session.memoryList
                                  .map((e) => "• ${e.content}")
                                  .join("\n")
                              : "暂无记忆",
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: const Color(0xFFE1EDFA),
        centerTitle: true,
        leading: Builder(
          builder: (ctx) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: const CircleAvatar(
                    radius: 18,
                    child: Text("AI", style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showStatusSelectDialog,
                  child: Text(_currentAiStatus.emoji,
                      style: const TextStyle(fontSize: 20)),
                ),
              ],
            );
          },
        ),
        title: Text(
          _roleName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: widget.session.messages.isEmpty
                    ? const Center(
                        child: Text("开始和角色对话吧",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(12),
                        itemCount: widget.session.messages.length +
                            (_aiLoading ? 1 : 0),
                        itemBuilder: (ctx, idx) {
                          if (_aiLoading &&
                              idx == widget.session.messages.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("AI输入中...",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            );
                          }
                          final msg = widget.session.messages[idx];
                          if (msg.isUser) {
                            return _buildUserBubble(msg);
                          } else {
                            return _buildAiBubble(msg);
                          }
                        },
                      ),
              ),
              SafeArea(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 3)
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: "输入消息...",
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(24)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: !_dissolving,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _dissolving ? null : _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.blue),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          if (_dissolving)
            AnimatedBuilder(
              animation: _dissolveAnimCtrl,
              builder: (ctx, child) {
                double progress = _dissolveAnimCtrl.value;
                for (var p in _particles) {
                  p.x += p.vx;
                  p.y += p.vy;
                  p.alpha = 0.85 * (1 - progress);
                }
                return Opacity(
                  opacity: 1 - progress * 0.95,
                  child: CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: ParticlePainter(_particles),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 270),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(msg.content,
                style: const TextStyle(color: Colors.white, height: 1.3)),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.time),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 270),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.content, style: const TextStyle(height: 1.3)),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.time),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    for (var p in particles) {
      paint.color = Colors.white.withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
