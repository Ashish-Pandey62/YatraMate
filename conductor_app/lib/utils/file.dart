import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> writeToFile(String data) async {
  // Get the directory where you can store files
  final directory = await getApplicationDocumentsDirectory();
  // Create a file in the app's documents directory
  print(directory.path);
  final file = File('${directory.path}/data.txt');

  // Write the data to the file
  await file.writeAsString(data);
}

Future<String> readFromFile() async {
  try {
    // Get the directory where the file is stored
    final directory = await getApplicationDocumentsDirectory();

    // Create a file in the app's documents directory
    final file = File('${directory.path}/data.txt');

    // Read the file and return its content
    return await file.readAsString();
  } catch (e) {
    return 'Error reading file: $e';
  }
}
