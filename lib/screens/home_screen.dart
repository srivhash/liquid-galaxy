import 'package:flutter/material.dart';
import 'package:lg_connection/components/connection_flag.dart';
// TODO 12 done : Import connections/ssh.dart
import 'package:lg_connection/connections/ssh.dart';
import '../components/reusable_card.dart';

bool connectionStatus = false;
// TODO 17 Done : Initialize const String searchPlace
const String searchPlace = 'Hyderabad';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO 13 done : Initialize SSH instance just like you did in the settings_page.dart, just uncomment the lines below, this time use the same instance for each of the tasks
  late SSH ssh;

  @override
  void initState() {
    super.initState();
    ssh = SSH();
    _connectToLG();
  }

  Future<void> _connectToLG() async {
    bool? result = await ssh.connectToLG();
    setState(() {
      connectionStatus = result!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LG Connection'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              _connectToLG();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10),
            child: Image.asset('assets/images/LIQUIDGALAXYLOGO.png',
              width: 100,
              height: 100),
     // Add this line
          ),
          ConnectionFlag(
            status: connectionStatus,
          ),
          //
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ReusableCard(
                    colour: Colors.blue,
                    onPress: () async {
                      // Show confirmation dialog
                      final bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Reboot'),
                            content: const Text('Do you want to reboot the LG system?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false); // User cancels
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true); // User confirms
                                },
                                child: const Text('Reboot'),
                              ),
                            ],
                          );
                        },
                      ) ?? false; // In case showDialog is dismissed by tapping outside of it

                      // Proceed with reboot if confirmed
                      if (confirm) {
                        ssh.rebootLG();
                      }
                    },
                    cardChild: const Center(
                      child: Text(
                        'REBOOT LG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ReusableCard(
                    colour: Colors.blue,
                    onPress: () async {
                      // TODO 16: Implement clearKML() as async task and test
                      // ssh.clearKML();
                      ssh.searchPlace(searchPlace);
                    },
                    cardChild: const Center(
                      child: Text(
                        'HOME CITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ReusableCard(
                    colour: Colors.blue,
                    onPress: () async {
                      // TODO 19 done: Implement searchPlace(String searchPlace) as async task and test
                      ssh.orbitCity();
                    },
                    cardChild: const Center(
                      child: Text(
                        // TODO 18 done : Add searchPlace variable to the button
                        'ORBIT CITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ReusableCard(
                    colour: Colors.blue,
                    onPress: () async {
                      //   TODO 20: Implement sendKML() as async task
                      // ssh.sendKML();
                    },
                    cardChild: const Center(
                      child: Text(
                        'PRINT BUBBLE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
