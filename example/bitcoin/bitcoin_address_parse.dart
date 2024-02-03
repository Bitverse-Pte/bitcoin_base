import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import '../example_service.dart';

void main() {
  final addressA = fromAddress(address: "tb1qxxxxxxx");
  final addressB = fromAddress(address: "bc1q3k5vw86rsdnvsrm9y2cr4w0jc8vh2dq8t40ent");

  print(addressA);
  print(addressB?.type.value);
  print(addressB?.type == BitcoinAddressType.p2wpkh);

  final addressC = fromAddress(address: "tb1p2zg7n92d5a3g5zem0axqe8s99kw57fart4a9usa7p8n0kl0crwvsyslk2a", network: BitcoinNetwork.testnet);
  print(addressC?.type.value);
  print(addressC?.type == BitcoinAddressType.p2wpkh);
  print(addressC?.type == BitcoinAddressType.p2tr);
}

/// 获取钱包地址
BitcoinAddress? fromAddress({
  required String address,
  BitcoinNetwork? network,
}) {
  /// segwit address
  try {
    return P2trAddress.fromAddress(address: address, network: network ?? BitcoinNetwork.mainnet);
// ignore: empty_catches
  } catch (e) {}
  try {
    return P2wpkhAddress.fromAddress(address: address, network: network ?? BitcoinNetwork.mainnet);
// ignore: empty_catches
  } catch (e) {}
  try {
    return P2wshAddress.fromAddress(address: address, network: network ?? BitcoinNetwork.mainnet);
// ignore: empty_catches
  } catch (e) {}

  /// legency address
  try {
    return P2shAddress.fromAddress(address: address, network: network ?? BitcoinNetwork.mainnet);
// ignore: empty_catches
  } catch (e) {}
  try {
    return P2pkhAddress.fromAddress(address: address, network: network ?? BitcoinNetwork.mainnet);
// ignore: empty_catches
  } catch (e) {}
  return null;
}
