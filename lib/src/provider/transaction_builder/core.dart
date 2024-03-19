import 'package:bitcoin_base/bitcoin_base.dart';

typedef BitcoinSignerCallBack = Future<String> Function(
    List<int> trDigest, UtxoWithAddress utxo, String publicKey, int sighash);

abstract class BasedBitcoinTransactionBuilder {
  Future<BtcTransaction> buildTransaction(BitcoinSignerCallBack sign);
}

enum BitcoinOrdering { bip69, shuffle, none }
