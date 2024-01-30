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
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value) {
          setState(() {
            pageIdx = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_chart_rounded),
            label: "Add Data",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_sharp),
            label: "Show Data",
          ),
        ]),
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
