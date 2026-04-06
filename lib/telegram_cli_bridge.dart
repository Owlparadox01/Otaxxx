import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum TelegramCliAction {
  listAccounts,
  connectAccount,
  verifyOtp,
  verifyTwoFa,
}

extension on TelegramCliAction {
  String get value {
    switch (this) {
      case TelegramCliAction.listAccounts:
        return "list-accounts";
      case TelegramCliAction.connectAccount:
        return "connect-account";
      case TelegramCliAction.verifyOtp:
        return "verify-otp";
      case TelegramCliAction.verifyTwoFa:
        return "verify-2fa";
    }
  }
}

class TelegramCliResult {
  final int exitCode;
  final String stdoutText;
  final String stderrText;

  const TelegramCliResult({
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
  });

  bool get success => exitCode == 0;
}

class TelegramCliProcess {
  final Process _process;
  final Stream<String> stdoutLines;
  final Stream<String> stderrLines;
  final Future<int> exitCode;

  TelegramCliProcess._({
    required Process process,
    required this.stdoutLines,
    required this.stderrLines,
    required this.exitCode,
  }) : _process = process;

  void sendInput(String value) {
    _process.stdin.writeln(value);
  }

  Future<void> closeInput() async {
    await _process.stdin.flush();
    await _process.stdin.close();
  }

  Future<void> kill() async {
    _process.kill();
  }
}

class TelegramCliBridge {
  final String nodeExecutable;
  final String scriptPath;
  final String workingDirectory;

  const TelegramCliBridge({
    this.nodeExecutable = "node",
    this.scriptPath = "lib/index.js",
    this.workingDirectory = ".",
  });

  List<String> _buildArgs(
    TelegramCliAction action, {
    Map<String, String>? params,
  }) {
    final args = <String>[scriptPath, "--action=${action.value}"];
    params?.forEach((key, value) {
      args.add("--$key=$value");
    });
    return args;
  }

  Future<TelegramCliResult> run(
    TelegramCliAction action, {
    Map<String, String>? params,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      throw UnsupportedError(
        "Node.js CLI hanya bisa dijalankan di desktop/server.",
      );
    }

    final args = _buildArgs(action, params: params);
    final result = await Process.run(
      nodeExecutable,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    ).timeout(timeout);

    return TelegramCliResult(
      exitCode: result.exitCode,
      stdoutText: (result.stdout ?? "").toString(),
      stderrText: (result.stderr ?? "").toString(),
    );
  }

  Future<TelegramCliProcess> startInteractive(
    TelegramCliAction action, {
    Map<String, String>? params,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      throw UnsupportedError(
        "Node.js CLI hanya bisa dijalankan di desktop/server.",
      );
    }

    final args = _buildArgs(action, params: params);
    final process = await Process.start(
      nodeExecutable,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    return TelegramCliProcess._(
      process: process,
      stdoutLines: process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter()),
      stderrLines: process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter()),
      exitCode: process.exitCode,
    );
  }
}




