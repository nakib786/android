import 'package:flutter/material.dart';

class ManualTripEntryScreen extends StatefulWidget {
  const ManualTripEntryScreen({super.key});

  @override
  State<ManualTripEntryScreen> createState() => _ManualTripEntryScreenState();
}

class _ManualTripEntryScreenState extends State<ManualTripEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for TextField data retrieval and management
  late TextEditingController _startLocationController;
  late TextEditingController _destinationController;
  late TextEditingController _distanceController;
  late TextEditingController _purposeController;

  // Explicit focus nodes to prevent Gboard/Android 14 crashes
  final FocusNode _startFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();
  final FocusNode _distFocus = FocusNode();
  final FocusNode _purposeFocus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  String _category = 'Business';

  @override
  void initState() {
    super.initState();
    _startLocationController = TextEditingController();
    _destinationController = TextEditingController();
    _distanceController = TextEditingController();
    _purposeController = TextEditingController();
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _purposeController.dispose();
    _startFocus.dispose();
    _destFocus.dispose();
    _distFocus.dispose();
    _purposeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Log Manual Trip")),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildDatePicker(),
                  const SizedBox(height: 20),
                  _buildTextField("Start Location", "e.g. Home", _startLocationController, focusNode: _startFocus, nextFocus: _destFocus),
                  const SizedBox(height: 20),
                  _buildTextField("Destination", "e.g. Client Office", _destinationController, focusNode: _destFocus, nextFocus: _distFocus),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Distance (km)", 
                    "0.0", 
                    _distanceController,
                    focusNode: _distFocus,
                    nextFocus: _purposeFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Purpose (Required for Business)", 
                    "e.g. Project briefing", 
                    _purposeController,
                    focusNode: _purposeFocus
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Unfocus before popping to avoid layout crashes during transition
                          FocusScope.of(context).unfocus();
                          // TODO: Save the trip using the controllers' values
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: const Text("SAVE TRIP"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2023),
          lastDate: DateTime(2027),
        );
        if (date != null && mounted) {
          setState(() => _selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: "Date", border: OutlineInputBorder()),
        child: Text("${_selectedDate.toLocal()}".split(' ')[0]),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {FocusNode? focusNode, FocusNode? nextFocus, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      // Fix for Android 14/Gboard crashes: disable spellcheck on technical fields
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: (val) {
        if (label.contains("Purpose") && _category == "Business" && (val == null || val.isEmpty)) {
          return "Purpose is required for Business trips";
        }
        if (label.contains("Distance") && (val == null || val.isEmpty)) {
          return "Distance is required";
        }
        return null;
      },
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = ['Business', 'Medical', 'Moving', 'Charity', 'Personal'];
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) {
        if (val != null && mounted) {
          setState(() => _category = val);
        }
      },
    );
  }
}
