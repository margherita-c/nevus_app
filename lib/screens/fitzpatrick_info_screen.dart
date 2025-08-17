import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_bar_title.dart';

class FitzpatrickInfoScreen extends StatefulWidget {
  const FitzpatrickInfoScreen({super.key});

  @override
  FitzpatrickInfoScreenState createState() => FitzpatrickInfoScreenState();
}

class FitzpatrickInfoScreenState extends State<FitzpatrickInfoScreen> {
  String _markdownContent = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMarkdownContent();
  }

  Future<void> _loadMarkdownContent() async {
    try {
      final content = await rootBundle.loadString('assets/md/fitzpatrick_scale.md');
      setState(() {
        _markdownContent = content;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _markdownContent = '';
        _isLoading = false;
        _errorMessage = 'Could not load content. Please check that the markdown file exists.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(title: 'Fitzpatrick Scale'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _loadMarkdownContent();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMarkdownContent(),
                  const SizedBox(height: 32),
                  _buildSkinTypeCards(),
                ],
              ),
            ),
    );
  }

  Widget _buildMarkdownContent() {
    // Simple markdown parsing for basic formatting
    final lines = _markdownContent.split('\n');
    List<Widget> widgets = [];

    // Get the default text color from the theme
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final headingColor = Theme.of(context).textTheme.headlineLarge?.color ?? Colors.black;

    for (String line in lines) {
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.substring(2),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            line.substring(3),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.substring(4),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: headingColor,
            ),
          ),
        ));
      } else if (line.startsWith('- **') && line.contains('**:')) {
        final parts = line.substring(2).split('**:');
        if (parts.length == 2) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: parts[0].replaceAll('**', ''),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ':${parts[1]}'),
                ],
              ),
            ),
          ));
        }
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            '• ${line.substring(2)}',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.4,
            ),
          ),
        ));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.replaceAll('**', ''),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: headingColor,
              height: 1.4,
            ),
          ),
        ));
      } else if (line.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.4,
            ),
          ),
        ));
      } else {
        widgets.add(const SizedBox(height: 4));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildSkinTypeCards() {
    final skinTypes = [
      {'type': 1, 'title': 'Type I', 'desc': 'Very fair, always burns', 'color': Colors.red.shade100},
      {'type': 2, 'title': 'Type II', 'desc': 'Fair, usually burns', 'color': Colors.orange.shade100},
      {'type': 3, 'title': 'Type III', 'desc': 'Medium, sometimes burns', 'color': Colors.yellow.shade100},
      {'type': 4, 'title': 'Type IV', 'desc': 'Olive, rarely burns', 'color': Colors.green.shade100},
      {'type': 5, 'title': 'Type V', 'desc': 'Brown, very rarely burns', 'color': Colors.blue.shade100},
      {'type': 6, 'title': 'Type VI', 'desc': 'Dark brown/black, never burns', 'color': Colors.purple.shade100},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Reference',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineLarge?.color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...skinTypes.map((skinType) => Card(
          color: skinType['color'] as Color,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                '${skinType['type']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            title: Text(
              skinType['title'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              skinType['desc'] as String,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        )),
      ],
    );
  }
}