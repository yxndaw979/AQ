import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';

class LocalLlmService {
  LlamaParent? _llamaParent;

  bool get isLoaded => _llamaParent != null;

  /// 加载GGUF模型
  Future<void> loadModel() async {
    final modelPath = await getModelFilePath();

    final loadCmd = LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(),
      contextParams: ContextParams()..nCtx = 1024,
      samplingParams: SamplerParams(),
    );

    _llamaParent = LlamaParent(loadCmd);
    await _llamaParent!.init();
  }

  /// 释放模型
  void unloadModel() {
    _llamaParent?.dispose();
    _llamaParent = null;
  }

  /// Qwen2.5 ChatML Prompt拼接
  String buildChatPrompt({
    required String persona,
    required List<AiMemory> memoryList,
    required List<ChatMessage> history,
    required String userInput,
  }) {
    final sb = StringBuffer();
    sb.writeln("<|im_start|>system");
    if (persona.isNotEmpty) {
      sb.writeln(persona);
    }
    for (final mem in memoryList) {
      sb.writeln(mem.content);
    }
    sb.writeln("<|im_end|>");

    for (final msg in history) {
      if (msg.isUser) {
        sb.writeln("<|im_start|>user");
        sb.writeln(msg.content);
        sb.writeln("<|im_end|>");
      } else {
        sb.writeln("<|im_start|>assistant");
        sb.writeln(msg.content);
        sb.writeln("<|im_end|>");
      }
    }

    sb.writeln("<|im_start|>user");
    sb.writeln(userInput);
    sb.writeln("<|im_end|>");
    sb.write("<|im_start|>assistant\n");
    return sb.toString();
  }

  /// 执行推理，返回完整字符串
  Future<String> generateResponse(String prompt) async {
    if (_llamaParent == null) throw Exception("模型未加载，请先调用loadModel");

    String buffer = "";
    final completer = Completer<String>();

    final sub = _llamaParent!.stream.listen((token) {
      buffer += token;
    }, onDone: () {
      if (!completer.isCompleted) {
        completer.complete(buffer.trim());
      }
    }, onError: (err) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    });

    _llamaParent!.sendPrompt(prompt);
    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  /// 获取模型存储路径
  static Future<String> getModelFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/model.gguf";
  }

  /// 判断模型文件是否存在
  static Future<bool> modelFileExists() async {
    final p = await getModelFilePath();
    return await File(p).exists();
  }

  /// 下载模型
  static Future<void> downloadModel(
      {required void Function(double progress) onProgress}) async {
    final savePath = await getModelFilePath();
    final url =
        "https://huggingface.co/TheBloke/Qwen2.5-4B-Instruct-GGUF/resolve/main/qwen2.5-4b-instruct.Q4_K_M.gguf";
    final dio = Dio();
    await dio.download(
      url,
      savePath,
      onReceiveProgress: (recv, total) {
        if (total > 0) {
          onProgress(recv / total);
        }
      },
    );
  }
}
