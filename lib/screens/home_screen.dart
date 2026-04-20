import 'add_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // THAY ĐỔI QUAN TRỌNG: Trỏ vào tầng 'CloudBackup' để quét mọi Project
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('CloudBackup');

  String _query = '';
  Set<String> _favs = {};
  bool _onlyFav = false;

  @override
  void initState() {
    super.initState();
    _loadFavs();
  }

  _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favs = (prefs.getStringList('favs') ?? []).toSet();
    });
  }

  _toggleFav(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favs.contains(id)) {
        _favs.remove(id);
      } else {
        _favs.add(id);
      }
      prefs.setStringList('favs', _favs.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('ALL EXPENSES', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_onlyFav ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent),
            onPressed: () => setState(() => _onlyFav = !_onlyFav),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search by claimant or type...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.indigo),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder(
              stream: _dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.snapshot.value == null) {
                  return const Center(child: Text('Waiting for data sync from Admin...'));
                }

                // LOGIC QUÉT DỮ LIỆU CỰC MẠNH: Gom tất cả chi phí từ mọi project
                final dynamic rawData = snap.data!.snapshot.value;
                List<Project> allExpenses = [];

                try {
                  if (rawData is Map) {
                    // Duyệt qua từng project (project_3, project_4,...)
                    rawData.forEach((projectKey, projectData) {
                      if (projectData != null && projectData['expenses'] != null) {
                        var expensesRaw = projectData['expenses'];

                        // Duyệt qua từng chi phí trong project đó
                        if (expensesRaw is List) {
                          for (var item in expensesRaw) {
                            if (item != null) {
                              allExpenses.add(Project.fromJson(Map<dynamic, dynamic>.from(item)));
                            }
                          }
                        } else if (expensesRaw is Map) {
                          expensesRaw.forEach((expKey, expData) {
                            if (expData != null) {
                              allExpenses.add(Project.fromJson(Map<dynamic, dynamic>.from(expData)));
                            }
                          });
                        }
                      }
                    });
                  }
                } catch (e) {
                  return Center(child: Text('Error parsing data: $e'));
                }

                // Filter Data
                var filtered = allExpenses.where((p) {
                  var matchQuery = p.name.toLowerCase().contains(_query) ||
                      p.type.toLowerCase().contains(_query);
                  var matchFav = !_onlyFav || _favs.contains(p.id.toString());
                  return matchQuery && matchFav;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching results found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final p = filtered[i];
                    final isFav = _favs.contains(p.id.toString());

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text("Type: ${p.type}\nDate: ${p.date}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("\$${p.amount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
                            Expanded(
                              child: IconButton(
                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                                onPressed: () => _toggleFav(p.id.toString()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // === NÚT ADD EXPENSE ĐƯỢC THÊM VÀO ĐÂY ===
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      // =========================================
    );
  }
}