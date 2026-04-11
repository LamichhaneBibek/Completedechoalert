import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoalert/components/custom_appbar.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:echoalert/services/nearest_contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';

enum _LocationState { checking, granted, denied, deniedForever, disabled }

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _user = FirebaseAuth.instance.currentUser;

  _LocationState _locationState = _LocationState.checking;

  CollectionReference get _contactsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection('myContacts');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Location ─────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    setState(() => _locationState = _LocationState.checking);

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) setState(() => _locationState = _LocationState.disabled);
      return;
    }

    var perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationState = _LocationState.deniedForever);
      return;
    }

    if (perm == LocationPermission.denied) {
      if (mounted) setState(() => _locationState = _LocationState.denied);
      return;
    }

    // Permission granted — get position and save to Firestore
    if (mounted) setState(() => _locationState = _LocationState.granted);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await NearestContactsService.updateUserLocation(
          pos.latitude, pos.longitude);
    } catch (_) {
      // Location saved best-effort; don't crash
    }
  }

  // ── Add contact dialog ───────────────────────────────────────────────────

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool isSaving = false;

          Future<void> save() async {
            final name = nameController.text.trim();
            final email = emailController.text.trim();
            final phone = phoneController.text.trim();

            final messenger = ScaffoldMessenger.of(context);

            if (name.isEmpty) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Please enter a contact name'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            if (phone.isEmpty && email.isEmpty) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Please enter a phone number or email'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            setDialogState(() => isSaving = true);
            try {
              await _contactsRef.add({
                'name': name,
                'email': email,
                'phone': phone,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              setDialogState(() => isSaving = false);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to add contact: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF830B2F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          color: Color(0xFF830B2F),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Trusted Contact',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A000A),
                            ),
                          ),
                          Text(
                            'They will receive your SOS alerts',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _dialogField(
                    controller: nameController,
                    label: 'Full name *',
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    controller: emailController,
                    label: 'Gmail / Email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    controller: phoneController,
                    label: 'Phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isSaving ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ? null : save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF830B2F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Add Contact',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF830B2F), size: 20),
        filled: true,
        fillColor: const Color(0xFFFBF5F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF830B2F), width: 1.8),
        ),
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
      bottomNavigationBar: const NavBarScreen(currentIndex: 2),
    );
  }

  // ── Location banner ──────────────────────────────────────────────────────

  Widget _buildLocationBanner() {
    switch (_locationState) {
      case _LocationState.checking:
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text(
                'Checking location permission…',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
            ],
          ),
        );

      case _LocationState.granted:
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Location enabled — SOS will include your position',
                  style: TextStyle(fontSize: 13, color: Colors.green),
                ),
              ),
            ],
          ),
        );

      case _LocationState.denied:
        return _locationWarningBanner(
          icon: Icons.location_off,
          message: 'Location permission denied. SOS will not include your position.',
          buttonLabel: 'Allow',
          onTap: _initLocation,
          color: Colors.orange,
        );

      case _LocationState.deniedForever:
        return _locationWarningBanner(
          icon: Icons.location_disabled,
          message: 'Location permanently denied. Open Settings to enable it.',
          buttonLabel: 'Settings',
          onTap: Geolocator.openAppSettings,
          color: Colors.red,
        );

      case _LocationState.disabled:
        return _locationWarningBanner(
          icon: Icons.location_disabled,
          message: 'Location services are off. Enable GPS for SOS alerts.',
          buttonLabel: 'Enable',
          onTap: Geolocator.openLocationSettings,
          color: Colors.red,
        );
    }
  }

  Widget _locationWarningBanner({
    required IconData icon,
    required String message,
    required String buttonLabel,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── My Contacts tab ──────────────────────────────────────────────────────

  Widget _buildMyContactsTab() {
    if (_user == null) {
      return const Center(child: Text('Please log in to manage contacts.'));
    }
    return Column(
      children: [
        _buildLocationBanner(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
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
                  final email = data['email'] as String? ?? '';
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF830B2F),
                            radius: 24,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined,
                                          size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        phone,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.email_outlined,
                                          size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call,
                                color: Colors.green, size: 22),
                            tooltip: 'Call',
                            onPressed: phone.isNotEmpty
                                ? () =>
                                    FlutterPhoneDirectCaller.callNumber(phone)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 22),
                            tooltip: 'Remove',
                            onPressed: () =>
                                _confirmDelete(docs[index].id, name),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
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
