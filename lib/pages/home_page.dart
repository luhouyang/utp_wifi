import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:utp_wifi/pages/add_wifi_data_page.dart';
import 'package:utp_wifi/pages/show_wifi_data_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIdx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: changePage(pageIdx),
      bottomNavigationBar: AnimatedBottomNavigationBar(
          backgroundColor: Colors.grey[200],
          activeColor: Colors.amber,
          inactiveColor: Colors.black,
          activeIndex: pageIdx,
          icons: const [
            Icons.add_chart_rounded,
            Icons.map_sharp,
          ],
          gapLocation: GapLocation.none,
          notchSmoothness: NotchSmoothness.sharpEdge,
          blurEffect: true,
          leftCornerRadius: 0,
          rightCornerRadius: 0,
          onTap: (index) {
            setState(() {
              pageIdx = index;
            });
          }),
    );
  }

  Widget changePage(int idx) {
    if (idx == 0) {
      return const AddWifiDataPage();
    } else if (idx == 1) {
      return const ShowWifiDataPage();
    } else {
      return const Center(
        child: Text("Error: no page data"),
      );
    }
  }
}
