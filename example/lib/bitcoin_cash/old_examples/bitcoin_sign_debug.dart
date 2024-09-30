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
  const BitcoinNetwork network = BitcoinNetwork.testnet;
  final service = BitcoinApiService();

  final api = ApiProvider.fromMempool(network, service);

  final mnemonic = Bip39SeedGenerator(
      Mnemonic.fromString(""))
      .generate();

  final bip32 = Bip32Slip10Secp256k1.fromSeed(mnemonic);

  final p2trDerivePath = bip32.derivePath("m/86'/0'/0'/0/0");
  final p2trPrivateKey = ECPrivate.fromBytes(p2trDerivePath.privateKey.raw);

  final p2trPublicKey = p2trPrivateKey.getPublic();
  final p2trAddress = P2trAddress.fromAddress(address: "tb1pv9hxejn4s6s6k9x5kqdrsdp6r96062jw4ceumz892jtwh2y8gtmsjfs0x3", network: network);
  if(p2trAddress ==null){
    return;
  }
  print(p2trAddress.toAddress(network));

  final p2wpkhAddress = P2wpkhAddress.fromAddress(
      address: "tb1qst7p2q2kz94tuvnx0gu34mqe99lcfrjhc6shr0", network: network);
  if (p2wpkhAddress == null) {
    return;
  }
  print(p2wpkhAddress.toAddress(network));

  final spenders = [
    UtxoAddressDetails(publicKey: p2trPublicKey.toHex(), address: p2trAddress),
  ];

  final List<UtxoWithAddress> utxo = [];
  for (final spender in spenders) {
    try {
      final spenderUtxos = await api.getAccountUtxo(spender);
      if (!spenderUtxos.canSpend()) {
        continue;
      }
      utxo.addAll(spenderUtxos);
    } on Exception {
      return;
    }
  }

  final sumOfUtxo = utxo.sumOfUtxosValue();
  final hasSatoshi = sumOfUtxo != BigInt.zero;
  if (!hasSatoshi) {
    return;
  }

  final fee = BigInt.from(1000);

  final p2wpkhOutput = BitcoinOutput(address: p2wpkhAddress, value: BigInt.from(1000));

  final restAmount = sumOfUtxo.toInt() - 2000;
  final p2trChangeAddress = BitcoinOutput(address: p2trAddress, value: BigInt.from(restAmount));

  final transactionBuilder = BitcoinTransactionBuilder(
    utxos: utxo,
    outPuts: [
      p2wpkhOutput,
      p2trChangeAddress,
    ],
    fee: fee,
    network: network,
    enableRBF: true,
  );

  final tr = await transactionBuilder.buildTransactionAsync((trDigest, utxo, publicKey, sighash) async {
    if (utxo.utxo.isP2tr()) {
      return p2trPrivateKey.signTapRoot(trDigest);
    } else {
      return p2trPrivateKey.signInput(trDigest, sigHash: sighash);
    }
  });

  final size = tr.hasSegwit ? tr.getVSize() : tr.getSize();

  final trId = await api.sendRawTransaction(tr.serialize());
  print(trId);
}