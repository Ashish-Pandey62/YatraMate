import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "package:pointycastle/export.dart";
import 'dart:convert';

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom,
    {int bitLength = 2048}) {
  // Create an RSA key generator and initialize it

  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom));

  // Use the generator

  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types

  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

SecureRandom exampleSecureRandom() {
  final secureRandom = FortunaRandom();

  final seedSource = Random.secure();
  final seeds = <int>[];
  for (int i = 0; i < 32; i++) {
    seeds.add(seedSource.nextInt(255));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

  return secureRandom;
}

const _secureStorage = FlutterSecureStorage();

// Method to store private key securely
Future<void> storePrivateKey(String privateKey) async {
  // Store the private key securely
  await _secureStorage.write(key: 'privateKey', value: privateKey);
}

// Method to retrieve private key securely
Future<String?> getPrivateKey() async {
  // Retrieve the private key
  return await _secureStorage.read(key: 'privateKey');
}

// Method to delete private key securely
Future<void> deletePrivateKey() async {
  await _secureStorage.delete(key: 'privateKey');
}

// final pair = generateRSAkeyPair(exampleSecureRandom());
// final public = pair.publicKey;
// final private = pair.privateKey;
// Function to convert PEM format private key to RSAPrivateKey

Uint8List pemStringToPrivateKey(String pemString) {
  // Remove the "-----BEGIN PRIVATE KEY-----" and "-----END PRIVATE KEY-----" lines
  final trimmedPem = pemString.replaceAll(
      RegExp(r'-----BEGIN PRIVATE KEY-----\n|-----END PRIVATE KEY-----'), '');

  // Decode the base64-encoded private key
  return base64.decode(trimmedPem.trim());
}
