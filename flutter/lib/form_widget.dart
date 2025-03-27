import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const List<String> list = <String>['Washroom', 'Water fountain'];

class FormWidget extends StatefulWidget {
  const FormWidget({super.key});

  @override
  State<FormWidget> createState() => _FormState();
}

class _FormState extends State<FormWidget> {
  final _formKey = GlobalKey<FormState>();
  late FocusNode formFocusNode;
  final formController = TextEditingController();
  String facilityTypeValue = list.first;

  @override
  void initState() {
    super.initState();
    formFocusNode = FocusNode();
  }

  @override
  void dispose() {
    formFocusNode.dispose();
    formController.dispose();
    super.dispose();
  }

  Future<void> submitForm(
      String date, String address, String description) async {
    final url = Uri.parse('BACKEND URL GOES HERE /api/userSubmission');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'facilityType': facilityTypeValue,
          'description': description,
          'date': date,
          'address': address,
        }),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for the feedback!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Failed to submit. Please try again or reach out through the contact page.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Please try again later.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report An Issue')),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text('Facility Type:'),
                DropdownButton<String>(
                  autofocus: true,
                  value: facilityTypeValue,
                  icon: const Icon(Icons.arrow_downward),
                  onChanged: (String? value) {
                    setState(() {
                      facilityTypeValue = value!;
                    });
                  },
                  items: list.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Text('Problem Description:'),
                TextFormField(
                  autofocus: false,
                  controller: formController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description of the issue';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Explanation of Issue and additional details...',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        submitForm(DateTime.now().toIso8601String(),
                            'need address var here', formController.text);
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
