import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/services_examples/explorer_service/explorer_service.dart';

final magicBytes = Uint8List.fromList(utf8.encode("Bitcoin Signed Message:\n"));

void main() {
  getHashData();
}

String _messagePrefix = '\u0018Bitcoin Signed Message:\n';

///这个方法的作用是将一个整数 n 编码成 Bitcoin 协议中的 Varint 格式。Varint 是一种变长整数编码方式，用于在比特币协议中表示不同长度的整数。
// Varint 格式的编码规则如下：
// 如果整数 n 小于 253，将其编码为一个字节。
// 如果整数 n 在 253 到 65535 之间，将其编码为 0xFD 后跟一个小端序的 2 字节无符号整数。
// 如果整数 n 在 65536 到 4294967295 之间，将其编码为 0xFE 后跟一个小端序的 4 字节无符号整数。
// 如果整数 n 大于等于 4294967296，将其编码为 0xFF 后跟一个小端序的 8 字节有符号整数。
Uint8List varintBufNum(int n) {
  Uint8List buf;
  if (n < 253) {
    buf = Uint8List(1);
    buf[0] = n;
  } else if (n < 0x10000) {
    buf = Uint8List(1 + 2);
    buf[0] = 253;
    buf.buffer.asByteData().setUint16(1, n, Endian.little);
  } else if (n < 0x100000000) {
    buf = Uint8List(1 + 4);
    buf[0] = 254;
    buf.buffer.asByteData().setUint32(1, n, Endian.little);
  } else {
    buf = Uint8List(1 + 8);
    buf[0] = 255;
    buf.buffer.asByteData().setInt32(1, n & -1, Endian.little);
    buf.buffer.asByteData().setUint32(5, (n / 0x100000000).floor(), Endian.little);
  }
  return buf;
}

void getHashData() {
  // final message = 'hello'.codeUnits;
  // final prefix1 = _varintBufNum(magicBytes.length);
  // final prefix2 = _varintBufNum(message.length);
  // final concat = Uint8List.fromList([...prefix1, ...magicBytes, ...prefix2, ...message]);
  // Uint8List preHashResult = Uint8List.fromList(QuickCrypto.keccack256Hash(concat));
  // print(hex.encode(preHashResult));

  // 18426974636f696e205369676e6564204d6573736167653a0a0568656c6c6f



  final message = 'hello'.codeUnits;
  final prefix = _messagePrefix;
  final prefixBytes = ascii.encode(prefix);
  final prefix2 = varintBufNum(message.length);
  final concat = Uint8List.fromList([...prefixBytes, ...prefix2, ...message]);

  print("${hex.encode(ascii.encode(_messagePrefix))}");
  print("${hex.encode(message)}");

  print("expected:18426974636f696e205369676e6564204d6573736167653a0a0568656c6c6f");
  print("actual  :${hex.encode(concat)}");
  print("${hex.encode(concat) == '18426974636f696e205369676e6564204d6573736167653a0a0568656c6c6f'}");


  //
  // print("prehash ------------------------ ");
  // print(hex.encode(preHashResult));
  //
  // return preHashResult;

  // return Uint8List.fromList(hex.decode('cf0447ec85f0ce7150a257db32ebfcb7523dae17c36dbd1be598779fec0484f4'));

  // final prefix = _messagePrefix + message.length.toString();
  // final prefixBytes = ascii.encode(prefix);
  // final concat = uint8ListFromList(prefixBytes + message);
  // return KeccakDigest(256).process(concat);
}
