import 'package:flutter/material.dart';
import '../llm/local_llm_service.dart';

class ModelManagerPage extends StatefulWidget {
  const ModelManagerPage({super.key});

  @override
  State<ModelManagerPage> createState() => _ModelManagerPageState();
}

class _ModelManagerPageState extends State<ModelManagerPage> {
  bool _fileExists = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isModelLoading = false;
  bool _modelLoaded = false;
  final LocalLlmService _llmService = LocalLlmService();

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final exist = await LocalLlmService.modelFileExists();
    setState(() {
      _fileExists = exist;
      _modelLoaded = _llmService.isLoaded;
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });
    try {
      await LocalLlmService.downloadModel(onProgress: (p) {
        setState(() {
          _downloadProgress = p;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("下载失败:$e")));
      }
    }
    setState(() {
      _isDownloading = false;
    });
    await _refreshStatus();
  }

  Future<void> _load() async {
    setState(() {
      _isModelLoading = true;
    });
    try {
      await _llmService.loadModel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("加载失败，内存不足？$e")));
      }
    }
    setState(() {
      _isModelLoading = false;
    });
    await _refreshStatus();
  }

  void _unload() {
    _llmService.unloadModel();
    setState(() {
      _modelLoaded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("本地大模型管理")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("模型：Qwen2.5‑4B‑Instruct Q4_K_M（≈2.3GB）"),
            const SizedBox(height: 12),
            Text("模型文件：${_fileExists ? "✅已存在" : "❌未下载"}"),
            Text("模型内存状态：${_modelLoaded ? "✅已加载到内存" : "❌未加载"}"),
            const SizedBox(height: 20),
            if (_isDownloading)
              Column(
                children: [
                  LinearProgressIndicator(value: _downloadProgress),
                  const SizedBox(height: 8),
                  Text("下载 ${(_downloadProgress * 100).toStringAsFixed(1)}%"),
                ],
              ),
            if (!_isDownloading && !_fileExists)
              ElevatedButton(
                  onPressed: _startDownload,
                  child: const Text("开始下载模型（建议WiFi）")),
            if (_fileExists && !_modelLoaded && !_isModelLoading)
              ElevatedButton(
                  onPressed: _load, child: const Text("加载模型到内存（等待几十秒）")),
            if (_isModelLoading)
              const Center(child: CircularProgressIndicator()),
            if (_fileExists && _modelLoaded)
              ElevatedButton(
                  onPressed: _unload,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("释放模型，释放内存")),
            const Spacer(),
            const Text(
                "⚠️注意：\n1.安卓需要8GB以上内存，否则加载直接闪退\n2.加载模型占用大量内存，退出聊天页建议释放\n3.推理会卡住UI，安卓CPU速度有限，回复生成慢"),
          ],
        ),
      ),
    );
  }
}
