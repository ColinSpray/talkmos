import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/core/encryption/ciphertext_envelope.dart';
import 'package:talkmos/core/encryption/http_key_client.dart';
import 'package:talkmos/core/encryption/message_key_service.dart';

void main() {
  // The endpoint is built from the configured backend url, so the fetch tests
  // cannot even construct a request without this.
  setUpAll(() => dotenv.load(fileName: '.env'));

  group('the key id travelling with a ciphertext', () {
    test('a legacy value carries no prefix and reads back as legacy', () {
      const stored = 'bm9uY2U=:bWFj:Y2lwaGVy';
      final parsed = CiphertextEnvelope.parse(stored);

      expect(parsed.keyId, CiphertextEnvelope.legacyKeyId);
      expect(parsed.payload, stored);
    });

    test('is not written for legacy, so old rows stay byte-identical', () {
      // Anything already on disk must keep decrypting untouched.
      expect(
        CiphertextEnvelope.wrap(
          keyId: CiphertextEnvelope.legacyKeyId,
          payload: 'a:b:c',
        ),
        'a:b:c',
      );
    });

    test('round-trips a current key', () {
      final wrapped = CiphertextEnvelope.wrap(keyId: 3, payload: 'a:b:c');
      expect(wrapped, 'k3.a:b:c');

      final parsed = CiphertextEnvelope.parse(wrapped);
      expect(parsed.keyId, 3);
      expect(parsed.payload, 'a:b:c');
    });

    test('leaves a payload containing dots alone', () {
      // base64 has no dots, but the split must not be greedy regardless.
      final parsed = CiphertextEnvelope.parse('k2.a.b:c:d');
      expect(parsed.keyId, 2);
      expect(parsed.payload, 'a.b:c:d');
    });

    test('a payload that merely starts with k is not a prefix', () {
      final parsed = CiphertextEnvelope.parse('keep:this:whole');
      expect(parsed.keyId, CiphertextEnvelope.legacyKeyId);
      expect(parsed.payload, 'keep:this:whole');
    });

    test('survives a two-digit rotation', () {
      final parsed = CiphertextEnvelope.parse(
        CiphertextEnvelope.wrap(keyId: 42, payload: 'x:y:z'),
      );
      expect(parsed.keyId, 42);
      expect(parsed.payload, 'x:y:z');
    });
  });

  group('the formula the server hands out', () {
    const formula = MessageKeyFormula(
      keyId: 1,
      template: '{userId}{salt}{chatId}',
      salt: 'S',
    );

    test('substitutes both placeholders', () {
      expect(formula.keyFor(userId: 'u1', chatId: 'c1'), 'u1Sc1');
    });

    test('a different chat derives a different key', () {
      expect(
        formula.keyFor(userId: 'u1', chatId: 'c1'),
        isNot(formula.keyFor(userId: 'u1', chatId: 'c2')),
      );
    });

    test('the server can change the derivation without an app release', () {
      // The point of sending a template rather than assuming one.
      const reordered = MessageKeyFormula(
        keyId: 2,
        template: '{salt}:{chatId}:{userId}',
        salt: 'S',
      );
      expect(reordered.keyFor(userId: 'u1', chatId: 'c1'), 'S:c1:u1');
    });

    test('an incomplete payload is rejected rather than half-used', () {
      expect(MessageKeyFormula.fromJson({'template': 'x', 'salt': ''}), isNull);
      expect(MessageKeyFormula.fromJson({'salt': 's', 'keyId': 1}), isNull);
      // A missing id would collide with the legacy id and silently mislabel
      // every message written under it.
      expect(
        MessageKeyFormula.fromJson({'template': 'x', 'salt': 's'}),
        isNull,
      );
    });

    test('round-trips through the cache format', () {
      final restored = MessageKeyFormula.fromJson(formula.toJson());
      expect(restored, isNotNull);
      expect(restored!.keyId, formula.keyId);
      expect(restored.template, formula.template);
      expect(restored.salt, formula.salt);
    });
  });

  group('fetching the formula', () {
    setUp(() => MessageKeyService.instance.seedForTest(null));

    test('reads what the server sent', () async {
      MessageKeyService.client = FakeKeyHttpClient(
        body: {
          'success': true,
          'data': {'keyId': 7, 'template': '{userId}{salt}', 'salt': 'pepper'},
        },
      );

      final formula = await MessageKeyService.instance.refresh();
      expect(formula?.keyId, 7);
      expect(formula?.salt, 'pepper');
    });

    test('a failed request keeps whatever was already known', () async {
      MessageKeyService.instance.seedForTest(
        const MessageKeyFormula(keyId: 1, template: '{salt}', salt: 'old'),
      );
      MessageKeyService.client = FakeKeyHttpClient(error: Exception('offline'));

      // Losing the network must not lose the key — the whole local history
      // would stop being readable.
      final formula = await MessageKeyService.instance.refresh();
      expect(formula?.salt, 'old');
    });

    test('an unsuccessful response is not treated as a key', () async {
      MessageKeyService.client = FakeKeyHttpClient(
        body: {'success': false, 'message': 'not configured'},
      );
      expect(await MessageKeyService.instance.refresh(), isNull);
    });

    test('a malformed formula is refused', () async {
      MessageKeyService.client = FakeKeyHttpClient(
        body: {
          'success': true,
          'data': {'keyId': 1, 'template': '', 'salt': 's'},
        },
      );
      expect(await MessageKeyService.instance.refresh(), isNull);
    });
  });
}
