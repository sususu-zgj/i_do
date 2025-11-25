import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:i_do/data/setting.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/widgets/base_theme_widget.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});
  static final PageStorageBucket _bucket = PageStorageBucket();

  static const List<FlexScheme> schemes= [
    FlexScheme.flutterDash,
    FlexScheme.blue, 
    FlexScheme.green, 
    FlexScheme.shadGreen, 
    FlexScheme.mandyRed, 
    FlexScheme.blackWhite, 
    FlexScheme.shadStone, 
  ];

  Widget buildThemeSchemeTile(BuildContext context) {
    final setting = context.watch<Setting>();

    return ExpansionTile(
      key: const PageStorageKey('theme_scheme'),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Theme Scheme'),
          Text(
            setting.colorScheme.name.capitalize,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          )
        ],
      ),
      children: schemes.map<Widget>((scheme) {
        bool isSelected = setting.colorScheme == scheme;

        Widget trailing = isSelected ? const Icon(Icons.check) : const SizedBox.shrink();

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
                width: isSelected ? 3 : 1,
              ),
              color: _getSchemeColor(scheme),
            ),
          ),
          title: Text(scheme.name.capitalize),
          trailing: IDoAPI.buildASWidget(child: trailing),
          selected: isSelected,
          onTap: () {
            setting.colorScheme = scheme;
          },
        );
      }).toList(),
    );
  }

  Widget buildAnimationTile(BuildContext context) {
    final setting = Setting();
    return SwitchListTile(
      title: Text('Enable Animations'),
      value: setting.enableAnimations == true,
      onChanged: (value) {
        setting.enableAnimations = value;
      },
    );
  }

  Widget buildSavePopTile(BuildContext context) {
    final setting = Setting();
    return SwitchListTile(
      title: Text('Pop up after save note'),
      value: setting.savePop == true,
      onChanged: (value) {
        setting.savePop = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: _bucket,
      child: Scaffold(
        appBar: BaseAppBar(
          title: Text('Setting'),
        ),
        body: ListView(
          key: const PageStorageKey('settings'),
          children: [
            // buildPathTile(),
            buildThemeSchemeTile(context),
            buildAnimationTile(context),
            buildSavePopTile(context),
          ],
        ),
      ),
    );
  }

  Color _getSchemeColor(FlexScheme scheme) {
    // 获取每个方案的主色调
    final schemeData = FlexColor.schemes[scheme];
    return schemeData?.light.primary ?? Colors.grey;
  }
}