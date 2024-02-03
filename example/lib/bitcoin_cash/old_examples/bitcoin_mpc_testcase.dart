import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:example/services_examples/explorer_service/explorer_service.dart';

void main() {
  _createP2TRRawTransaction();
  // _generateP2TRWithPrivateKey();
  // _generateP2TRWithMnemonic();
  // _generateP2TRWithPublicKey();
}

void _generateP2TRWithPublicKey() {
  String publicKey = "04eda19b92261471cb117594f48822e71bb84d05b88190545663fafebbbb0823dd4b8f032483dcbb43e29b0f30b64f6b6eb5c0f75734f73f56375cb3e6f70bd0a7";
  ECPublic ecPublic = ECPublic.fromHex(publicKey);

  // final bip32 = Bip32Slip10Secp256k1.fromPublicKey(ecPublic.publicKey.compressed);
  //
  // /// i generate 4 HD wallet for this test and now i have access to private and pulic key of each wallet
  // final p2trDerivePath = bip32.derivePath("m/86'/0'/0'/0/0");

  /// access to public key `ECPublic`
  // ECPublic p2trPublicKey = ECPublic.fromBytes(p2trDerivePath.publicKey.compressed);

  /// P2TR
  final p2trAddress = ecPublic.toTaprootAddress();
  print(p2trAddress.toAddress(BitcoinNetwork.testnet));
}

void _generateP2TRWithPrivateKey() {
  final ECPrivate ecPrivate = ECPrivate.fromWif('Kxq2up1S17tSva2Bh1wDHwtZenzmnvWMM6qE9oFsWwP8T42SvYDR',
      netVersion: BitcoinNetwork.mainnet.wifNetVer);

  // String privateKey = "0xaaf38cc130d216eb38646ff7a237a4a7a86e970f44b51ec11bbb4aa5fb96eebe";
  // String key = WifEncoder.encode(BytesUtils.fromHexString(privateKey), netVer: BitcoinNetwork.mainnet.wifNetVer, pubKeyMode: WifPubKeyModes.compressed);
  // ECPrivate ecPrivate = ECPrivate.fromWif(key, netVersion: BitcoinNetwork.mainnet.wifNetVer);

  final bip32 = Bip32Slip10Secp256k1.fromPrivateKey(ecPrivate.prive.raw);

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
  print(p2trAddress.toAddress(BitcoinNetwork.mainnet));

  /// P2WPKH
  final p2wpkhAddress = p2wpkhPublicKey.toSegwitAddress();
  print(p2wpkhAddress.toAddress(BitcoinNetwork.mainnet));
}

void _generateP2TRWithMnemonic() {
  final mnemonic = Bip39SeedGenerator(
      Mnemonic.fromString(""))
      .generate();

  final bip32 = Bip32Slip10Secp256k1.fromSeed(mnemonic);

  print('--------------public key-----------');
  print(bip32.publicKey.toHex());
  print('--------------');

  print('--------------private key-----------');
  print(bip32.privateKey.toHex());
  print('--------------');

  /// i generate 4 HD wallet for this test and now i have access to private and pulic key of each wallet
  final p2trDerivePath = bip32.derivePath("m/86'/0'/0'/0/0");

  /// access to private key `ECPrivate`
  final p2trPrivateKey = ECPrivate.fromBytes(p2trDerivePath.privateKey.raw);

  /// access to public key `ECPublic`
  final p2trPublicKey = p2trPrivateKey.getPublic();

  print('--------------public key-----------');
  print(p2trPublicKey.toHex());
  print('--------------');

  /// P2TR
  final p2trAddress = p2trPublicKey.toTaprootAddress();
  print(p2trAddress.toAddress(BitcoinNetwork.testnet));
}

void _createP2TRRawTransaction() async {
  String hex = "04eda19b92261471cb117594f48822e71bb84d05b88190545663fafebbbb0823dd4b8f032483dcbb43e29b0f30b64f6b6eb5c0f75734f73f56375cb3e6f70bd0a7";
  ECPublic p2trPublicKey = ECPublic.fromHex(hex);

  /// P2TR
  final p2trAddress = p2trPublicKey.toTaprootAddress();

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
  final p2wpkhPublicKey = p2wpkhPrivateKey.getPublic();

  /// P2WPKH
  final p2wpkhAddress = p2wpkhPublicKey.toSegwitAddress();
  print(p2wpkhAddress.toAddress(BitcoinNetwork.testnet));

  /// Spending List
  /// i use some different address type for this
  /// now i want to spending from 8 address in one transaction
  /// we need publicKeys and address
  final spenders = [
    UtxoAddressDetails(publicKey: p2trPublicKey.toHex(), address: p2trAddress),
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

  /// 1,224,143 sum of all utxos
  final hasSatoshi = sumOfUtxo != BigInt.zero;
  if (!hasSatoshi) {
    /// Are you kidding? We don't have btc to spend
    return;
  }

  /// In the 'p2wsh_multi_sig_test' example, I have provided a comprehensive
  /// explanation of how to determine the transaction fee
  /// before creating the original transaction.

  /// We consider 50,003 satoshi for the cost
  // final fee = BigInt.from(50003);
  final fee = BigInt.from(1000);

  /// now we have 1,174,140 satoshi for spending let do it
  /// we create 10 different output with  different address type like (pt2r, p2sh(p2wpkh), p2sh(p2wsh), p2pkh, etc.)
  /// We consider the spendable amount for 10 outputs and divide by 10, each output 117,414
  // final p2wpkhInput = BitcoinOutput(address: p2wpkhAddress, value: BigInt.from(117414));
  final p2wpkhOutput = BitcoinOutput(address: p2wpkhAddress, value: BigInt.from(1000));

  final restAmount = sumOfUtxo.toInt() - 2000;
  final p2trChangeAddress = BitcoinOutput(address: p2trAddress, value: BigInt.from(restAmount));

  /// Well, now it is clear to whom we are going to pay the amount
  /// Now let's create the transaction
  final transactionBuilder = BitcoinTransactionBuilder(
    /// Now, we provide the UTXOs we want to spend.
    utxos: utxos,

    /// We select transaction outputs
    outPuts: [
      p2wpkhOutput,
      p2trChangeAddress,
    ],
/*
		Transaction fee
		Ensure that you have accurately calculated the amounts.
		If the sum of the outputs, including the transaction fee,
		does not match the total amount of UTXOs,
		it will result in an error. Please double-check your calculations.
	*/
    fee: fee,
// network, testnet, mainnet
    network: network,
// If you like the note write something else and leave it blank
// I will put my GitHub address here
    memo: "https://github.com/mrtnetwork",
/*
		RBF, or Replace-By-Fee, is a feature in Bitcoin that allows you to increase the fee of an unconfirmed
		transaction that you've broadcasted to the network.
		This feature is useful when you want to speed up a
		transaction that is taking longer than expected to get confirmed due to low transaction fees.
	*/
    enableRBF: true,
  );

  /// now we use BuildTransaction to complete them
  /// I considered a method parameter for this, to sign the transaction
  print(transactionBuilder.toString());

  /// parameters
  /// utxo  infos with owner details
  /// trDigest transaction digest of current UTXO (must be sign with correct privateKey)
  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder
  final tr = transactionBuilder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    /// For each input in the transaction, locate the corresponding private key
    /// and sign the transaction digest to construct the unlocking script.
    if (utxo.utxo.isP2tr()) {
      return p2trPrivateKey.signTapRoot(trDigest);
    } else {
      return p2wpkhPrivateKey.signInput(trDigest, sigHash: sighash);
    }
  });

  print(tr.toHex());

  /// Calculate the size of the transaction in bytes.
  /// You can determine the transaction fee by multiplying the transaction size
  /// Formula: transaction fee = (transaction size in bytes * fee rate in bytes)
  final size = tr.hasSegwit ? tr.getVSize() : tr.getSize();

  /// broadcast transaction
  /// https://mempool.space/testnet/tx/05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258
  final trId = await api.sendRawTransaction(tr.serialize());

  print(trId);
}