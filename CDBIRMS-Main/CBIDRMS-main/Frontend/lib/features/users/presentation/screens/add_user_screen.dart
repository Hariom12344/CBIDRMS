export 'add_edit_user_screen.dart';

import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import 'add_edit_user_screen.dart';

class AddUserScreen extends StatelessWidget {
  final UserEntity? userToEdit;
  const AddUserScreen({super.key, this.userToEdit});

  @override
  Widget build(BuildContext context) {
    return AddEditUserScreen(userToEdit: userToEdit);
  }
}
