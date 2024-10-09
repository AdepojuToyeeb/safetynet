import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safetynet/screens/emergency/success_additionn.dart';
import 'package:safetynet/widget/custom_next_button.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  EmergencyContactsScreenState createState() => EmergencyContactsScreenState();
}

class EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late List<Contact> _contacts = [];
  final List<Contact> _selectedContacts = [];
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDialog() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: false,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const SuccesfulEmergency(),
    );
  }

  Future<void> _fetchContacts() async {
    PermissionStatus permissionStatus = await Permission.contacts.request();
    if (permissionStatus.isGranted) {
      try {
        final contacts =
            await FlutterContacts.getContacts(withProperties: true);
        if (!mounted) return;

        setState(() {
          _contacts = contacts;
          _filteredContacts = _contacts;
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load contacts')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts
          .where((contact) =>
              contact.displayName.toLowerCase().contains(query) ||
              contact.phones.any((phone) => phone.number.contains(query)))
          .toList();
    });
  }

  void _addContact(Contact contact) {
    setState(() {
      if (!_selectedContacts.contains(contact)) {
        _selectedContacts.add(contact);
      }
    });
  }

  void _removeContact(Contact contact) {
    setState(() {
      _selectedContacts.remove(contact);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select your Emergency Contacts',
                  style: TextStyle(color: Colors.black, fontSize: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select people to be contacted immediately in case of any emergencies.',
                  style: TextStyle(color: Colors.black),
                ),
                const SizedBox(
                  height: 20,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ..._selectedContacts.take(2).map((contact) => Chip(
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxWidth: 60), // Set max width
                            child: Text(
                              contact.displayName,
                              overflow: TextOverflow
                                  .ellipsis, // Add ellipsis if text is too long
                            ),
                          ),
                          onDeleted: () => _removeContact(contact),
                        )),
                    if (_selectedContacts.length > 2)
                      Chip(
                        label: Text(
                          '+${_selectedContacts.length - 2} other contacts',
                          style: const TextStyle(color: Colors.black),
                        ),
                        backgroundColor:
                            Colors.grey[300], // Customize as needed
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contacts',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color:
                              Colors.black), // Black border for default state
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Colors.black), // Black border when enabled
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1), // Thicker black border when focused
                    ),
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: contact.photo != null
                              ? MemoryImage(contact.photo!)
                              : null,
                          child: contact.photo == null
                              ? Text(contact.displayName.isNotEmpty
                                  ? contact.displayName[0]
                                  : '')
                              : null,
                        ),
                        title: Text(
                          contact.displayName,
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          contact.phones.isNotEmpty
                              ? contact.phones.first.number
                              : 'No phone number',
                          style: const TextStyle(color: Colors.black45),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize
                              .min, // This ensures the row doesn't take up full width
                          children: [
                            IconButton(
                              icon: Icon(
                                _selectedContacts.contains(contact)
                                    ? Icons.check_circle
                                    : Icons.add_circle,
                                color: _selectedContacts.contains(contact)
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                              onPressed: () {
                                if (!_selectedContacts.contains(contact)) {
                                  _addContact(contact); // Add contact to list
                                }
                              },
                            ),
                            if (_selectedContacts.contains(contact))
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _removeContact(
                                      contact); // Remove contact from list
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: CustomNextButton(
              onPressed: _showDialog,
              text: "Proceed",
              enabled: _contacts.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }
}
