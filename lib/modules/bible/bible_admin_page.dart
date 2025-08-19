import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/member_view_toggle_button.dart';
import '../../widgets/bottom_navigation_wrapper.dart';
import 'bible_page.dart';
import 'views/bible_admin_view.dart';

class BibleAdminPage extends StatefulWidget {
  const BibleAdminPage({Key? key}) : super(key: key);

  @override
  State<BibleAdminPage> createState() => _BibleAdminPageState();
}

class _BibleAdminPageState extends State<BibleAdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'La Bible - Administration',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          MemberViewToggleButton(
            onToggle: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const BottomNavigationWrapper(initialRoute: 'bible')),
                (route) => false);
            }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
              ]),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 15),
              tabs: const [
                Tab(icon: Icon(Icons.admin_panel_settings), text: 'Gestion'),
                Tab(icon: Icon(Icons.visibility), text: 'Vue Membre'),
              ])))),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BibleAdminView(),
          BiblePage(),
        ]));
  }
}
