import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:i_do/data/config.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/widgets/base_theme_widget.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  static final PageStorageBucket _bucket = PageStorageBucket();

  static List<FlexScheme> get schemes => IDoAPI.schemes; 

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late PageController _pageController;
  late TextEditingController _textEditingController;
  late FocusNode _sentenceFocusNode;
  Setting? _setting;

  Setting get setting => _setting!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setting ??= context.watch<Setting>();
  }

  @override
  void initState() {
    super.initState();
    final initialIndex = SettingPage.schemes.indexOf(Setting().colorScheme);
    _pageController = PageController(
      initialPage: initialIndex < 0 ? 0 : initialIndex,
      viewportFraction: 0.28,
    );
    _textEditingController = TextEditingController(text: Setting().startUpSentence);
    _sentenceFocusNode = FocusNode();
    _sentenceFocusNode.addListener(() {
      if (!_sentenceFocusNode.hasFocus) {
        setting.startUpSentence = _textEditingController.text;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildThemeColorTile(BuildContext context) {
    return ExpansionTile(
      key: const PageStorageKey('theme_color_tile'),
      title: Text('Theme Color'),
      subtitle: Text(
        setting.colorScheme.name.capitalize,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      children: [
        _colorPicker()
      ],
    );
  }

  Widget _colorPicker() {
    final selectedIndex = SettingPage.schemes.indexOf(setting.colorScheme);
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            key: const PageStorageKey('color_scheme_picker'),
            controller: _pageController,
            itemCount: SettingPage.schemes.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                setting.colorScheme = SettingPage.schemes[index];
              });
            },
            itemBuilder: (context, index) {
              final scheme = SettingPage.schemes[index];
              final color = _getSchemeColor(scheme);
              final isCenter = index == selectedIndex;

              return Center( 
                child: AnimatedScale(
                  scale: isCenter ? 1.0 : 0.75,
                  duration: const Duration(milliseconds: 250),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    child: SizedBox.square(
                      dimension: 100,
                      child: _ColorItem(
                        size: 100,
                        scheme: scheme,
                        color: color,
                        selected: isCenter,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // 指示条
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(SettingPage.schemes.length, (i) {
            final active = i == selectedIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 10,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStartUpSentenceTile(BuildContext context) {
    return ExpansionTile(
      key: const PageStorageKey('start_up_sentence_tile'),
      title: const Text('Start Up Sentence'),
      children: [
        Container(
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const PageStorageKey('start_up_sentence_textfield'),
            minLines: null,
            maxLines: null,
            expands: true,
            focusNode: _sentenceFocusNode,
            controller: _textEditingController,
            decoration: const InputDecoration(
              hintText: 'Try {<weekday/day/month/year>}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartUpAnimationTile(BuildContext context) {
    final setting = Setting();
    return SwitchListTile(
      title: const Text('Enable Start Up Animation'),
      value: setting.enableStartUpAnimation == true,
      onChanged: (v) => setting.enableStartUpAnimation = v,
    );
  }

  Widget _buildAnimationTile(BuildContext context) {
    final setting = Setting();
    return SwitchListTile(
      title: const Text('Enable Animations'),
      value: setting.enableAnimations == true,
      onChanged: (v) => setting.enableAnimations = v,
    );
  }

  Widget _buildSavePopTile(BuildContext context) {
    final setting = Setting();
    return SwitchListTile(
      title: const Text('Pop up after save note'),
      value: setting.savePop == true,
      onChanged: (v) => setting.savePop = v,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: SettingPage._bucket,
      child: Scaffold(
        appBar: const BaseAppBar(title: Text('Setting')),
        body: ListView(
          key: const PageStorageKey('settings'),
          children: [
            _buildThemeColorTile(context),
            _buildStartUpSentenceTile(context),
            _buildStartUpAnimationTile(context),
            _buildAnimationTile(context),
            _buildSavePopTile(context),
          ],
        ),
      ),
    );
  }

  Color _getSchemeColor(FlexScheme scheme) {
    final schemeData = FlexColor.schemes[scheme];
    return schemeData?.light.primary ?? Colors.grey;
  }
}

class _ColorItem extends StatelessWidget {
  final FlexScheme scheme;
  final Color color;
  final bool selected;
  final double size;

  const _ColorItem({
    required this.size,
    required this.scheme,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            width: selected ? 4 : 2,
          ),
          gradient: LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            scheme.name.capitalize,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}