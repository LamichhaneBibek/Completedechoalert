import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoalert/components/custom_appbar.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _user = FirebaseAuth.instance.currentUser;

  CollectionReference get _contactsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection('myContacts');

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

  // ── My Contacts helpers ──────────────────────────────────────────────────

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Trusted Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) return;
              await _contactsRef.add({
                'name': name,
                'phone': phone,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF830B2F),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove "$name" from your trusted contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _contactsRef.doc(docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Contacts',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF830B2F),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF830B2F),
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'My Contacts'),
              Tab(icon: Icon(Icons.emergency), text: 'Emergency'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMyContactsTab(), _buildEmergencyTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: _showAddContactDialog,
            backgroundColor: const Color(0xFF830B2F),
            tooltip: 'Add Trusted Contact',
            child: const Icon(Icons.person_add, color: Colors.white),
          );
        },
      ),
      bottomNavigationBar: const NavBarScreen(currentIndex: 3),
    );
  }

  // ── My Contacts tab ──────────────────────────────────────────────────────

  Widget _buildMyContactsTab() {
    if (_user == null) {
      return const Center(child: Text('Please log in to manage contacts.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _contactsRef.orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No trusted contacts yet.\nTap + to add someone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] as String? ?? '';
            final phone = data['phone'] as String? ?? '';
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF830B2F),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(phone),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      tooltip: 'Call',
                      onPressed: () =>
                          FlutterPhoneDirectCaller.callNumber(phone),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remove',
                      onPressed: () => _confirmDelete(docs[index].id, name),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Emergency Numbers tab ────────────────────────────────────────────────

  Widget _buildEmergencyTab() {
    final numbers = [
      _EmergencyEntry(
        label: 'Nepal Police - 100',
        number: '100',
        image: 'assets/images/police.png',
      ),
      _EmergencyEntry(
        label: 'Fire Brigade - 101',
        number: '101',
        image: 'assets/images/fire_brigade.png',
      ),
      _EmergencyEntry(
        label: 'Ambulance - 102',
        number: '102',
        image: 'assets/images/ambulance.png',
      ),
      _EmergencyEntry(
        label: 'Child Helpline - 104',
        number: '104',
        image: 'assets/images/childern.png',
      ),
      _EmergencyEntry(
        label: 'Women Helpline - 1145',
        number: '1145',
        image: 'assets/images/women.png',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: numbers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final e = numbers[index];
        return GestureDetector(
          onTap: () => FlutterPhoneDirectCaller.callNumber(e.number),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Image.asset(
                  e.image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.phone, size: 50),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    e.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.call, color: Colors.green),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmergencyEntry {
  final String label;
  final String number;
  final String image;
  const _EmergencyEntry({
    required this.label,
    required this.number,
    required this.image,
  });
}
