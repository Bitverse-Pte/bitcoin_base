import 'dart:convert';
import 'dart:typed_data';

void main() {
  String hexString = "30784868403302194015878377951051568457560029542784822715027892509797137671684";

  List<int> bytes = List.generate(hexString.length ~/ 2,
          (index) => int.parse(hexString.substring(index * 2, index * 2 + 2), radix: 16));

  String base64String = base64Encode(Uint8List.fromList(bytes));
  print(base64String);
}