// Main Flutter app for PECS-like communication
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const PecApp());
}

class PecApp extends StatelessWidget {
  const PecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Карточки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ChildScreen(),
    );
  }
}

class PecCard {
  final String id;
  final String title;
  final String speak;
  final String imagePath;
  final bool isAsset;

  PecCard({
    required this.id,
    required this.title,
    required this.speak,
    required this.imagePath,
    required this.isAsset,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'speak': speak,
        'imagePath': imagePath,
        'isAsset': isAsset,
      };

  factory PecCard.fromJson(Map<String, dynamic> json) => PecCard(
        id: json['id'],
        title: json['title'],
        speak: json['speak'],
        imagePath: json['imagePath'],
        isAsset: json['isAsset'] ?? false,
      );
}

final List<PecCard> presetCards = [
  PecCard(
    id: 'preset_eat',
    title: 'кушать',
    speak: 'Я хочу кушать',
    imagePath: 'assets/preset/eat.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_drink',
    title: 'пить',
    speak: 'Я хочу пить',
    imagePath: 'assets/preset/drink.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_toilet',
    title: 'туалет',
    speak: 'Мне нужно в туалет',
    imagePath: 'assets/preset/toilet.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_walk',
    title: 'гулять',
    speak: 'Я хочу гулять',
    imagePath: 'assets/preset/walk.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_mom',
    title: 'мама',
    speak: 'Мама',
    imagePath: 'assets/preset/mom.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_dad',
    title: 'папа',
    speak: 'Папа',
    imagePath: 'assets/preset/dad.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_pain',
    title: 'больно',
    speak: 'Мне больно',
    imagePath: 'assets/preset/pain.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_tired',
    title: 'устал',
    speak: 'Я устал',
    imagePath: 'assets/preset/tired.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_cartoon',
    title: 'мультик',
    speak: 'Я хочу мультик',
    imagePath: 'assets/preset/cartoon.png',
    isAsset: true,
  ),
  PecCard(
    id: 'preset_toy',
    title: 'игрушка',
    speak: 'Я хочу игрушку',
    imagePath: 'assets/preset/toy.png',
    isAsset: true,
  ),
];

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    await _tts.setLanguage('ru-RU');
    await _tts.setSpeechRate(0.9);
  }

  static Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }
}

class StorageService {
  static List<PecCard> _userCards = [];
  static const String fileName = 'cards.json';

  static Future<String> _jsonPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  static Future<String> _imagesDirPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/images';
    final imagesDir = Directory(path);
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return path;
  }

  static List<PecCard> get allCards => [...presetCards, ..._userCards];

  static Future<void> load() async {
    try {
      final path = await _jsonPath();
      final file = File(path);
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as List;
        _userCards = data.map((e) => PecCard.fromJson(e)).toList();
      }
    } catch (_) {
      _userCards = [];
    }
  }

  static Future<void> _save() async {
    final path = await _jsonPath();
    final data = _userCards.map((e) => e.toJson()).toList();
    await File(path).writeAsString(jsonEncode(data));
  }

  static Future<void> addUserCard({
    required String title,
    required String speak,
    required String imageFilePath,
  }) async {
    final id = const Uuid().v4();
    _userCards.add(
      PecCard(
        id: id,
        title: title,
        speak: speak,
        imagePath: imageFilePath,
        isAsset: false,
      ),
    );
    await _save();
  }

  static Future<void> deleteUserCard(PecCard card) async {
    _userCards.removeWhere((c) => c.id == card.id);
    await _save();
  }

  static Future<String> savePickedImage(XFile picked) async {
    final imagesDir = await _imagesDirPath();
    final newPath =
        '$imagesDir/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    await File(picked.path).copy(newPath);
    return newPath;
  }

  static Future<String> saveNetworkImage(Uint8List bytes, String ext) async {
    final imagesDir = await _imagesDirPath();
    final newPath =
        '$imagesDir/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = File(newPath);
    await file.writeAsBytes(bytes);
    return newPath;
  }
}

class HoldButton extends StatefulWidget {
  final VoidCallback onHoldComplete;

  const HoldButton({super.key, required this.onHoldComplete});

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  double progress = 0.0;
  bool holding = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        holding = true;
        progress = 0.0;
        _startProgress();
      },
      onLongPressEnd: (_) {
        holding = false;
        progress = 0.0;
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.settings, size: 28),
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startProgress() async {
    while (holding && progress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      progress += 0.06;
      setState(() {});
    }
    if (progress >= 1.0 && mounted) {
      widget.onHoldComplete();
    }
  }
}

class CardItem extends StatelessWidget {
  final PecCard card;

  const CardItem({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (card.isAsset) {
      img = Image.asset(card.imagePath, fit: BoxFit.cover);
    } else {
      img = Image.file(File(card.imagePath), fit: BoxFit.cover);
    }

    return GestureDetector(
      onTap: () {
        TtsService.speak(card.speak);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: img,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                card.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChildScreen extends StatefulWidget {
  const ChildScreen({super.key});

  @override
  State<ChildScreen> createState() => _ChildScreenState();
}

class _ChildScreenState extends State<ChildScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await StorageService.load();
    await TtsService.init();
    if (!mounted) return;
    setState(() {
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = StorageService.allCards;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточки'),
        actions: [
          HoldButton(
            onHoldComplete: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount = 2;
                if (width > 600) crossAxisCount = 3;
                if (width > 900) crossAxisCount = 4;

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (_, i) => CardItem(card: cards[i]),
                );
              },
            ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final userCards =
        StorageService.allCards.where((c) => !c.isAsset).toList();
    final assetCards =
        StorageService.allCards.where((c) => c.isAsset).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки (для мамы)'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Встроенные карточки',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Они всегда доступны ребёнку'),
          ),
          ...assetCards.map(
            (c) => ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(c.title),
              subtitle: Text(c.speak),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Пользовательские карточки',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...userCards.map(
            (c) => ListTile(
              leading: const Icon(Icons.image),
              title: Text(c.title),
              subtitle: Text(c.speak),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await StorageService.deleteUserCard(c);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _addCardFromDevice(context),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Добавить карточку (камера/галерея)'),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _openPexelsSearch(context),
              icon: const Icon(Icons.search),
              label: const Text('Найти картинку в интернете (Pexels)'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _addCardFromDevice(BuildContext context) async {
    final picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Источник изображения'),
        content: const Text('Выбрать откуда брать картинку'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Камера'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Галерея'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final path = await StorageService.savePickedImage(picked);

    final result = await _askTitleAndSpeak(context);
    if (result == null) return;

    await StorageService.addUserCard(
      title: result[0],
      speak: result[1],
      imageFilePath: path,
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<List<String>?> _askTitleAndSpeak(BuildContext context,
      {String? initial}) async {
    final titleCtrl = TextEditingController(text: initial ?? '');
    final speakCtrl = TextEditingController(text: initial ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новая карточка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Текст на карточке',
              ),
            ),
            TextField(
              controller: speakCtrl,
              decoration: const InputDecoration(
                labelText: 'Фраза для произношения',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok != true) return null;
    final title = titleCtrl.text.trim();
    final speak = speakCtrl.text.trim().isEmpty ? title : speakCtrl.text.trim();
    if (title.isEmpty) return null;
    return [title, speak];
  }

  void _openPexelsSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PexelsSearchScreen()),
    ).then((_) => setState(() {}));
  }
}

class PexelsSearchScreen extends StatefulWidget {
  const PexelsSearchScreen({super.key});

  @override
  State<PexelsSearchScreen> createState() => _PexelsSearchScreenState();
}

class _PexelsSearchScreenState extends State<PexelsSearchScreen> {
  final _queryCtrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  // TODO: replace with your real Pexels API key
  static const String _pexelsApiKey = 'YOUR_PEXELS_API_KEY_HERE';

  Future<void> _search() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _results = [];
    });

    try {
      final uri = Uri.parse(
          'https://api.pexels.com/v1/search?query=${Uri.encodeQueryComponent(query)}&per_page=30');
      final resp = await http.get(
        uri,
        headers: {'Authorization': _pexelsApiKey},
      );
      if (resp.statusCode == 200) {
        final jsonBody = jsonDecode(resp.body);
        final photos = (jsonBody['photos'] as List)
            .cast<Map<String, dynamic>>()
            .toList();
        setState(() {
          _results = photos;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка Pexels: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _onPhotoTap(Map<String, dynamic> photo) async {
    final src = photo['src'] as Map<String, dynamic>;
    final url = src['medium'] ?? src['large'] ?? src['original'];
    if (url == null) return;

    final query = _queryCtrl.text.trim();
    final result = await _askTitleAndSpeak(context, initial: query);
    if (result == null) return;

    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final bytes = resp.bodyBytes;
        final path = await StorageService.saveNetworkImage(bytes, 'jpg');
        await StorageService.addUserCard(
          title: result[0],
          speak: result[1],
          imageFilePath: path,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Карточка добавлена')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка загрузки изображения: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети: $e')),
      );
    }
  }

  Future<List<String>?> _askTitleAndSpeak(BuildContext context,
      {String? initial}) async {
    final titleCtrl = TextEditingController(text: initial ?? '');
    final speakCtrl = TextEditingController(text: initial ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новая карточка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Текст на карточке',
              ),
            ),
            TextField(
              controller: speakCtrl,
              decoration: const InputDecoration(
                labelText: 'Фраза для произношения',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok != true) return null;
    final title = titleCtrl.text.trim();
    final speak = speakCtrl.text.trim().isEmpty ? title : speakCtrl.text.trim();
    if (title.isEmpty) return null;
    return [title, speak];
  }

  @override
  Widget build(BuildContext context) {
    final cardsPerRow = MediaQuery.of(context).size.width > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск картинок (Pexels)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Поиск (например: яблоко, сок, игрушка)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          if (!_loading)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cardsPerRow,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final photo = _results[i];
                  final src = photo['src'] as Map<String, dynamic>;
                  final thumbUrl =
                      src['tiny'] ?? src['small'] ?? src['medium'];

                  return GestureDetector(
                    onTap: () => _onPhotoTap(photo),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        thumbUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
