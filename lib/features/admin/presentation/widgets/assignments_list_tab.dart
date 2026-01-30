import 'package:flutter/material.dart';

class AssignmentsListTab extends StatelessWidget {
  const AssignmentsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'إدارة التكليفات - قريباً',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
