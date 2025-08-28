
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(HBWFCApp());
}

class HBWFCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HBWFC Overlijst',
      theme: ThemeData(
        primaryColor: Color(0xFF2E8B3A),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2E8B3A),
          foregroundColor: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HBWFC Overlijst'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                ),
                child: Text('Scannen', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScanSessionScreen())),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                ),
                child: Text('Historie', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanSessionScreen extends StatefulWidget {
  @override
  _ScanSessionScreenState createState() => _ScanSessionScreenState();
}

class _ScanSessionScreenState extends State<ScanSessionScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool popupOpen = false;
  List<Map<String,dynamic>> scans = [];
  late DateTime sessionStart;
  String storageFolderName = 'HBWFC_Overlijst';
  bool cameraInit = false;

  @override
  void initState() {
    super.initState();
    sessionStart = DateTime.now();
    _ensurePermissions();
  }

  Future<void> _ensurePermissions() async {
    await Permission.camera.request();
  }

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (popupOpen) return;
      popupOpen = true;
      final code = scanData.code ?? '';
      await controller.pauseCamera();
      await _handleScannedCode(code);
      await controller.resumeCamera();
      popupOpen = false;
    });
  }

  Future<void> _handleScannedCode(String code) async {
    // detect duplicate in this session
    int existingIndex = scans.indexWhere((e) => e['code'] == code);
    if (existingIndex != -1) {
      // show duplicate dialog
      final res = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Code al eerder gescand'),
          content: Text('De code $code is al gescand. Kies een actie.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context,'adjust'), child: Text('Aantal aanpassen')),
            TextButton(onPressed: () => Navigator.pop(context,'ignore'), child: Text('Negeren')),
          ],
        ),
      );
      if (res == 'adjust') {
        // show qty input for existing entry (overwrite)
        final newQty = await _showQtyInput(code, scans[existingIndex]['qty'].toString());
        if (newQty != null) {
          setState(() {
            scans[existingIndex]['qty'] = newQty;
          });
        }
        return;
      } else {
        // ignore -> allow adding a new entry (fall through)
      }
    }
    final qty = await _showQtyInput(code, '');
    if (qty != null) {
      setState(() {
        scans.add({'code': code, 'qty': qty});
      });
    }
  }

  Future<int?> _showQtyInput(String code, String initial) async {
    TextEditingController ctrl = TextEditingController(text: initial);
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(code),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Aantal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuleren')),
          ElevatedButton(onPressed: () {
            final text = ctrl.text.trim();
            final n = int.tryParse(text);
            if (n == null) return;
            Navigator.pop(context, n);
          }, child: Text('✔')),
        ],
      ),
    );
  }

  Future<String> _getStoragePath() async {
    final dir = await getExternalStorageDirectory();
    // Attempt Downloads fallback
    Directory base;
    if (Platform.isAndroid) {
      // Use external storage directory's parent up to 'Android' and then /Download
      String path = dir!.path;
      // try to find '/Android' and replace remainder to get root external storage
      int idx = path.indexOf('/Android');
      String rootPath = idx!=-1 ? path.substring(0, idx) : path;
      base = Directory('$rootPath/Download');
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final folder = Directory('${base.path}/$storageFolderName');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder.path;
  }

  Future<void> _finishAndSave() async {
    if (scans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Geen scans om op te slaan.')));
      return;
    }
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Klaar'),
        content: Text('Heb je alles gescand?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context,false), child: Text('Nee')),
          ElevatedButton(onPressed: () => Navigator.pop(context,true), child: Text('Ja')),
        ],
      ),
    );
    if (ok != true) return;
    final folder = await _getStoragePath();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final fname = 'Over-lijst ${formatter.format(sessionStart)}.csv';
    final path = '$folder/$fname';
    final file = File(path);
    final sb = StringBuffer();
    sb.writeln('code;aantal');
    for (var r in scans) {
      sb.writeln('${r['code']};${r['qty']}');
    }
    await file.writeAsString(sb.toString());
    // open the file view
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SessionResultScreen(filePath: path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scannen'),
        actions: [
          TextButton(onPressed: _finishAndSave, child: Text('Klaar', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildScansList(),
          )
        ],
      ),
    );
  }

  Widget _buildScansList() {
    return ListView.builder(
      itemCount: scans.length,
      itemBuilder: (_, idx) {
        final e = scans[idx];
        return ListTile(
          title: Text('${e['code']}'),
          subtitle: Text('Aantal: ${e['qty']}'),
        );
      },
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class SessionResultScreen extends StatelessWidget {
  final String filePath;
  SessionResultScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    return Scaffold(
      appBar: AppBar(title: Text('Resultaat')),
      body: FutureBuilder<String>(
        future: file.readAsString(),
        builder: (_, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          final lines = snap.data!.split('\n').where((l) => l.trim().isNotEmpty).toList();
          return Column(
            children: [
              Expanded(child: ListView.builder(
                itemCount: lines.length,
                itemBuilder: (_, i) {
                  return ListTile(title: Text(lines[i]));
                },
              )),
              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: ElevatedButton(
                      onPressed: () async {
                        await Share.shareFiles([filePath], text: 'Over-lijst');
                      },
                      child: Text('Delen'),
                    )),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await OpenFile.open(filePath);
                      },
                      child: Text('Open'),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String storageFolderName = 'HBWFC_Overlijst';
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<String> _getStoragePath() async {
    final dir = await getExternalStorageDirectory();
    Directory base;
    if (Platform.isAndroid) {
      String path = dir!.path;
      int idx = path.indexOf('/Android');
      String rootPath = idx!=-1 ? path.substring(0, idx) : path;
      base = Directory('$rootPath/Download');
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final folder = Directory('${base.path}/$storageFolderName');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder.path;
  }

  Future<void> _loadFiles() async {
    final p = await _getStoragePath();
    final dir = Directory(p);
    final list = dir.listSync().whereType<File>().toList();
    list.sort((a,b) => b.statSync().modified.compareTo(a.statSync().modified));
    setState(() {
      files = list;
    });
  }

  Future<void> _openFile(File f) async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SessionResultScreen(filePath: f.path)));
  }

  Future<void> _continueWith(File f) async {
    // Create V2 / V3 filename and open scan session with preloaded entries from file
    final content = await File(f.path).readAsString();
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final entries = <Map<String,dynamic>>[];
    for (var i=1;i<lines.length;i++) {
      final l = lines[i];
      final parts = l.split(';');
      if (parts.length>=2) {
        entries.add({'code': parts[0], 'qty': int.tryParse(parts[1]) ?? 1});
      }
    }
    // compute new filename with Vx suffix
    final dirname = File(f.path).parent.path;
    final base = f.uri.pathSegments.last;
    String newName;
    int version = 2;
    String nameOnly = base;
    if (base.contains(' V')) {
      // naive
      newName = base + ' V2';
    } else {
      final dot = base.lastIndexOf('.');
      final prefix = dot!=-1 ? base.substring(0,dot) : base;
      final ext = dot!=-1 ? base.substring(dot) : '';
      newName = prefix + ' V2' + ext;
    }
    final newPath = '$dirname/$newName';
    // write new file with same entries as starting point
    final sb = StringBuffer();
    sb.writeln('code;aantal');
    for (var e in entries) sb.writeln('${e['code']};${e['qty']}');
    await File(newPath).writeAsString(sb.toString());
    // open result screen for the new file
    await _loadFiles();
    Navigator.push(context, MaterialPageRoute(builder: (_) => SessionResultScreen(filePath: newPath)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historie'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFiles,
        child: ListView.builder(
          itemCount: files.length,
          itemBuilder: (_, idx) {
            final f = files[idx] as File;
            final name = f.uri.pathSegments.last;
            final date = f.statSync().modified;
            return ListTile(
              title: Text(name),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(date)),
              trailing: PopupMenuButton<String>(
                onSelected: (s) async {
                  if (s=='open') await _openFile(f);
                  if (s=='share') await Share.shareFiles([f.path], text: 'Over-lijst');
                  if (s=='continue') await _continueWith(f);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'open', child: Text('Openen')),
                  PopupMenuItem(value: 'share', child: Text('Delen')),
                  PopupMenuItem(value: 'continue', child: Text('Doorgaan met scannen')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
