import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/services_examples/explorer_service/explorer_service.dart';

void main() {
  _createP2TRRawTransaction();
}

void _createP2TRRawTransaction() async {
  /// select network
  const BitcoinNetwork network = BitcoinNetwork.testnet;
  final service = BitcoinApiService();

  /// select api for read accounts UTXOs and send transaction
  /// Mempool or BlockCypher
  final api = ApiProvider.fromMempool(network, service);

  final mnemonic = Bip39SeedGenerator(
          Mnemonic.fromString(""))
      .generate();

  final bip32 = Bip32Slip10Secp256k1.fromSeed(mnemonic);

  /// i generate 4 HD wallet for this test and now i have access to private and pulic key of each wallet
  final p2trDerivePath = bip32.derivePath("m/86'/0'/0'/0/0");
  final p2wpkhDerivePath = bip32.derivePath("m/44'/0'/0'/0/0");

  /// access to private key `ECPrivate`
  final p2trPrivateKey = ECPrivate.fromBytes(p2trDerivePath.privateKey.raw);
  final p2wpkhPrivateKey = ECPrivate.fromBytes(p2wpkhDerivePath.privateKey.raw);

  /// access to public key `ECPublic`
  final p2trPublicKey = p2trPrivateKey.getPublic();
  final p2wpkhPublicKey = p2wpkhPrivateKey.getPublic();

  /// P2TR
  final p2trAddress = p2trPublicKey.toTaprootAddress();
  print(p2trAddress.toAddress(BitcoinNetwork.testnet));

  /// P2WPKH
  final p2wpkhAddress = p2wpkhPublicKey.toSegwitAddress();
  print(p2wpkhAddress.toAddress(BitcoinNetwork.testnet));

  /// Spending List
  /// i use some different address type for this
  /// now i want to spending from 8 address in one transaction
  /// we need publicKeys and address
  final spenders = [
    UtxoAddressDetails(publicKey: p2trPublicKey.toHex(), address: p2trAddress),
    // UtxoAddressDetails.watchOnly(p2trAddress),
  ];

  /// i need now to read spenders account UTXOS
  final List<UtxoWithAddress> utxos = [];

  /// i add some method for provider to read utxos from mempool or blockCypher
  /// looping address to read Utxos
  for (final spender in spenders) {
    try {
      /// read each address utxo from mempool
      final spenderUtxos = await api.getAccountUtxo(spender);

      /// check if account have any utxo for spending (balance)
      if (!spenderUtxos.canSpend()) {
        /// address does not have any satoshi for spending:
        continue;
      }

      utxos.addAll(spenderUtxos);
    } on Exception {
      /// something bad happen when reading Utxos:
      return;
    }
  }

  /// Well, now we calculate how much we can spend
  final sumOfUtxo = utxos.sumOfUtxosValue();

  /// now we have 1,174,140 satoshi for spending let do it
  /// we create 10 different output with  different address type like (pt2r, p2sh(p2wpkh), p2sh(p2wsh), p2pkh, etc.)
  /// We consider the spendable amount for 10 outputs and divide by 10, each output 117,414
  // final p2wpkhInput = BitcoinOutput(address: p2wpkhAddress, value: BigInt.from(117414));
  final p2wpkhOutput = BitcoinOutput(address: p2wpkhAddress, value: BigInt.from(1000));

  final restAmount = sumOfUtxo.toInt() - 2000;
  final p2trChangeAddress = BitcoinOutput(address: p2trAddress, value: BigInt.from(restAmount));

  int size = await BitcoinTransactionBuilder.estimateTransactionSize(
    utxos: utxos,
    outputs: [
      p2wpkhOutput,
      p2trChangeAddress,
    ],
    network: network,
    enableRBF: true,
  );

  /// transaction size: 565 byte
  final blockCypher = ApiProvider.fromBlocCypher(network, service);

  /// fee rate inKB
  /// feeRate.medium: 32279 P/KB
  /// feeRate.high: 43009  P/KB
  /// feeRate.low: 22594 P/KB
  final feeRate = await blockCypher.getNetworkFeeRate();

  /// Well now we have the transaction fee and we can create the outputs based on this
  /// 565 byte / 1024 * (feeRate / 32279 )  = 17810
  final fee = feeRate.getEstimate(size, feeRateType: BitcoinFeeRateType.medium);

  print(fee);
}
