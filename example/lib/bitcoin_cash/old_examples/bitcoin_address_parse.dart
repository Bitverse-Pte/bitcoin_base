import 'package:bitcoin_base/bitcoin_base.dart';

void main() {
  final addressA = fromAddress(address: "tb1qxxxxxxx");
  final addressB = fromAddress(address: "bc1q3k5vw86rsdnvsrm9y2cr4w0jc8vh2dq8t40ent");

  print(addressA);
  print(addressB?.type.value);
  print(addressB?.type == BitcoinAddressType.fromValue("P2WPKH"));

  final addressC = fromAddress(
      address: "tb1p2zg7n92d5a3g5zem0axqe8s99kw57fart4a9usa7p8n0kl0crwvsyslk2a", network: BitcoinNetwork.testnet);
  print(addressC?.type.value);
  print(addressC?.type == BitcoinAddressType.fromValue("P2WPKH"));
  print(addressC?.type == BitcoinAddressType.fromValue("P2TR"));
}

/// 获取钱包地址
BitcoinAddress? fromAddress({
  required String address,
  BitcoinNetwork? network,
}) {
  try {
    return BitcoinAddress(address, network: network ?? BitcoinNetwork.mainnet);
  } catch (_) {}
  return null;
}
