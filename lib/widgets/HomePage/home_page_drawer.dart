import 'package:flutter/material.dart';
import 'package:i_do/data/config.dart';
import 'package:i_do/i_do_api.dart';
import 'package:i_do/widgets/BaseThemeWidget/base_theme_drawer.dart';
import 'package:provider/provider.dart';

class HomePageDrawer extends StatefulWidget {
  const HomePageDrawer({super.key});

  @override
  State<HomePageDrawer> createState() => _HomePageDrawerState();
}

class _HomePageDrawerState extends State<HomePageDrawer> {
  AppConfig? _homeData;
  Setting? _setting;
  AppConfig get data => _homeData!;
  Setting get setting => _setting!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeData ??= context.watch<AppConfig>();
    _setting ??= context.watch<Setting>();
  }

  Widget _buildToolBar() {
    final colorScheme = Theme.of(context).colorScheme; 
    return Row(
      children: [
        // Setting 页
        IconButton(
          color: colorScheme.primary,
          icon: const Icon(Icons.settings),
          onPressed: () {
            IDoAPI.openSettingPage(context);
          },
        ),
        // 切换主题按钮
        IconButton(
          color: colorScheme.primary,
          onPressed: _switchTheme,
          icon: _buildThemeIcon(),
          tooltip: 'Switch Theme',
        ),
        IconButton(
          color: colorScheme.primary,
          onPressed: () {
            IDoAPI.openRecyclePage(context);
          },
          icon: Icon(Icons.delete),
        )
      ],
    );
  }

  Widget _buildOptions() {
    final colorScheme = Theme.of(context).colorScheme; 
    final tileTextStyle = TextStyle(color: colorScheme.primary);

    return ExpansionTile(
      key: const PageStorageKey('home_options'),
      title: Text('Options', style: tileTextStyle,),
      trailing: const Icon(Icons.tune),
      children: [
        SwitchListTile(
          title: const Text('Floating Edit Button'),
          value: data.isEditButtonFloating,
          onChanged: (value) {
            data.isEditButtonFloating = value;
          },
        ),
        SwitchListTile(
          title: const Text('Show Finished Notes'),
          value: data.isFinishShown,
          onChanged: (value) {
            data.isFinishShown = value;
          },
        ),
        SwitchListTile(
          title: const Text('Show Unfinished Notes'),
          value: data.isUnfinishShown,
          onChanged: (value) {
            data.isUnfinishShown = value;
          },
        ),
        SwitchListTile(
          title: const Text('Toggle Finish'),
          value: data.isToggleFinish,
          onChanged: (value) {
            data.isToggleFinish = value;
          },
        ),
        SwitchListTile(
          title: const Text('Reverse Sort Order'),
          value: data.isSortReverse,
          onChanged: (value) {
            data.isSortReverse = value;
          },
        ),
      ],
    );
  }

  Widget _buildTagsTile() {
    final colorScheme = Theme.of(context).colorScheme; 
    final tileTextStyle = TextStyle(color: colorScheme.primary);

    return ListTile(
      title: Text('Tags', style: tileTextStyle,),
      trailing: const Icon(Icons.label),
      onTap: () => IDoAPI.openTagsPage(context),
    );
  }

  Widget _buildStarTile() {
    final colorScheme = Theme.of(context).colorScheme; 
    final tileTextStyle = TextStyle(color: colorScheme.primary);

    return ListTile(
      title: Text('Stared', style: tileTextStyle,),
      trailing: const Icon(Icons.star),
      onTap: () {
        IDoAPI.openStarredPage(context);
      },
    );
  }

  Widget _buildTaskTile() {
    final colorScheme = Theme.of(context).colorScheme; 
    final tileTextStyle = TextStyle(color: colorScheme.primary);
    
    return ListTile(
      title: Text('Event', style: tileTextStyle,),
      trailing: const Icon(Icons.event_note),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return BaseThemeDrawer(
      child: ListView(
        key: const PageStorageKey('home_drawer'),
        children: [
          _buildToolBar(),
          const Divider(height: 0,),
          _buildOptions(),
          _buildTagsTile(),
          _buildStarTile(),
          _buildTaskTile(),
        ],
      ),
    );
  }

  Icon _buildThemeIcon() {
    final themeMode = Setting().themeMode;
    final icon = switch (themeMode) {
      ThemeMode.light => Icons.brightness_7,
      ThemeMode.dark => Icons.brightness_4,
      ThemeMode.system => Icons.brightness_auto,
    };
    return Icon(icon);
  }

  void _switchTheme() {
    final themeMode = setting.themeMode;
      switch (themeMode) {
        case ThemeMode.system:
          setting.themeMode = ThemeMode.light;
        case ThemeMode.light:
          setting.themeMode = ThemeMode.dark;
        case ThemeMode.dark:
          setting.themeMode = ThemeMode.system;
      }
  }
}
