import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum TabsVariant {
  line,
  pills,
}

class AppTabs extends StatefulWidget {
  final List<AppTab> tabs;
  final int initialIndex;
  final ValueChanged<int>? onChanged;
  final TabsVariant variant;
  final bool scrollable;
  final double? height;

  const AppTabs({
    Key? key,
    required this.tabs,
    this.initialIndex = 0,
    this.onChanged,
    this.variant = TabsVariant.line,
    this.scrollable = false,
    this.height,
  }) : super(key: key);

  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.tabs.length,
      initialIndex: widget.initialIndex,
      vsync: this,
    );
    _controller.addListener(() {
      if (_controller.indexIsChanging) {
        widget.onChanged?.call(_controller.index);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == TabsVariant.pills) {
      return _buildPillsTabs();
    } else {
      return _buildLineTabs();
    }
  }

  Widget _buildLineTabs() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColor.border1,
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _controller,
            isScrollable: widget.scrollable,
            labelColor: AppColor.primary7,
            unselectedLabelColor: AppColor.secondary05,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            indicatorColor: AppColor.primary7,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            tabs: widget.tabs.map((tab) => _buildTab(tab)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: widget.tabs.map((tab) => tab.content).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPillsTabs() {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColor.secondary00,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _controller,
            isScrollable: widget.scrollable,
            labelColor: AppColor.secondary07,
            unselectedLabelColor: AppColor.secondary05,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            indicator: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColor.secondary07.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            tabs: widget.tabs.map((tab) => _buildTab(tab)).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: widget.tabs.map((tab) => tab.content).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(AppTab tab) {
    return Tab(
      height: widget.variant == TabsVariant.pills ? 40 : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tab.icon != null) ...[
            Icon(tab.icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(tab.label),
          if (tab.badge != null) ...[
            const SizedBox(width: 8),
            tab.badge!,
          ],
        ],
      ),
    );
  }
}

class AppTab {
  final String label;
  final Widget content;
  final IconData? icon;
  final Widget? badge;

  const AppTab({
    required this.label,
    required this.content,
    this.icon,
    this.badge,
  });
}

// Simple Tabs without TabBarView (header only)
class AppTabsHeader extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final TabsVariant variant;
  final bool scrollable;

  const AppTabsHeader({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = TabsVariant.line,
    this.scrollable = false,
  }) : super(key: key);

  @override
  State<AppTabsHeader> createState() => _AppTabsHeaderState();
}

class _AppTabsHeaderState extends State<AppTabsHeader> {
  @override
  Widget build(BuildContext context) {
    if (widget.variant == TabsVariant.pills) {
      return _buildPillsHeader();
    } else {
      return _buildLineHeader();
    }
  }

  Widget _buildLineHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColor.border1,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.scrollable)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildTabButtons(),
                ),
              ),
            )
          else
            ..._buildTabButtons(),
        ],
      ),
    );
  }

  Widget _buildPillsHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.secondary00,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: widget.scrollable
            ? [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _buildPillButtons(),
                    ),
                  ),
                )
              ]
            : _buildPillButtons(),
      ),
    );
  }

  List<Widget> _buildTabButtons() {
    return widget.tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      final isSelected = index == widget.selectedIndex;

      return GestureDetector(
        onTap: () => widget.onChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    bottom: BorderSide(
                      color: AppColor.primary7,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Text(
            tab,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              color: isSelected ? AppColor.primary7 : AppColor.secondary05,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPillButtons() {
    return widget.tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      final isSelected = index == widget.selectedIndex;

      return Expanded(
        child: GestureDetector(
          onTap: () => widget.onChanged(index),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.secondary07.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  )
                : null,
            child: Text(
              tab,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? AppColor.secondary07 : AppColor.secondary05,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
