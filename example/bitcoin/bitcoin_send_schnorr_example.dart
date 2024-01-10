import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import '../example_service.dart';
import '../spending_with_scripts/spending_builders.dart';
import '../spending_with_scripts/spending_single_type.dart';

void main() {
  spendingP2TR();
}

// Spend P2TR: Please note that all input addresses must be of P2TR type; otherwise, the transaction will fail.
Future<void> spendingP2TR() async {
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

  final utxo = await api.getAccountUtxo(UtxoAddressDetails(address: p2trAddress, publicKey: p2trPublicKey.toHex()));
  final sumOfUtxo = utxo.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    throw Exception("account does not have any unspent transaction");
  }

  // final feeRate = await api.getNetworkFeeRate();
  final changeAddress = p2trAddress;
  final List<BitcoinAddress> outputsAddress = [p2wpkhAddress, changeAddress];
  // final transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
  //   utxos: utxo,
  //   outputs: outputsAddress,
  //   network: network,
  // );
  // final estimateFee = feeRate.getEstimate(
  //   transactionSize,
  //   feeRateType: BitcoinFeeRateType.medium,
  // );

  final estimateFee =  BigInt.from(1000);

  final canSpend = sumOfUtxo - estimateFee;
  final outputWithValue = outputsAddress
      .map((e) => BitcoinOutput(address: e, value: canSpend ~/ BigInt.from(outputsAddress.length)))
      .toList();

  final transaction = buildP2trTransaction(
    receiver: outputWithValue,
    sign: (digest, publicKey, sigHash) {
      // Use signTapRoot instead of signInput for the taproot transaction input.
      return p2trPrivateKey.signTapRoot(digest, sighash: sigHash, tweak: true);
    },
    utxo: utxo,
  );

  final ser = transaction.serialize();
  final trHashId = await api.sendRawTransaction(ser);
  print(trHashId);
}