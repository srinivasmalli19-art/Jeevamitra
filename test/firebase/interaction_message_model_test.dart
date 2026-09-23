import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/models/interaction_message_model.dart';

InteractionMessageModel _message({
  String id = '',
  String senderId = 'farmer-1',
  String type = 'text',
  String? text = 'Hello',
  String? attachmentUrl,
  String? attachmentPath,
  int? attachmentSizeBytes,
  DateTime? readAt,
}) {
  return InteractionMessageModel(
    id: id,
    senderId: senderId,
    senderRole: 'farmer',
    type: type,
    text: text,
    attachmentUrl: attachmentUrl,
    attachmentPath: attachmentPath,
    attachmentSizeBytes: attachmentSizeBytes,
    createdAt: DateTime(2026, 7, 1, 10, 30),
    readAt: readAt,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('round-trip', () {
    test('a text message survives write and read back unchanged', () async {
      final model = _message();
      final ref = await firestore
          .collection('interactions')
          .doc('int-1')
          .collection('messages')
          .add(model.toFirestore());
      final snap = await ref.get();
      final read = InteractionMessageModel.fromFirestore(snap);

      expect(read.senderId, 'farmer-1');
      expect(read.senderRole, 'farmer');
      expect(read.type, 'text');
      expect(read.text, 'Hello');
      expect(read.attachmentUrl, isNull);
      expect(read.attachmentPath, isNull);
      expect(read.attachmentSizeBytes, isNull);
      expect(read.createdAt, DateTime(2026, 7, 1, 10, 30));
      expect(read.readAt, isNull);
    });

    test('an image message with attachment fields survives write and read', () async {
      final model = _message(
        type: 'image',
        text: null,
        attachmentUrl: 'https://example.com/photo.jpg',
        attachmentPath: 'interactions/int-1/photo.jpg',
        attachmentSizeBytes: 204800,
      );
      final ref = await firestore
          .collection('interactions')
          .doc('int-1')
          .collection('messages')
          .add(model.toFirestore());
      final snap = await ref.get();
      final read = InteractionMessageModel.fromFirestore(snap);

      expect(read.type, 'image');
      expect(read.text, isNull);
      expect(read.attachmentUrl, 'https://example.com/photo.jpg');
      expect(read.attachmentPath, 'interactions/int-1/photo.jpg');
      expect(read.attachmentSizeBytes, 204800);
    });

    test('readAt, when set, survives write and read back unchanged', () async {
      final model = _message(readAt: DateTime(2026, 7, 1, 11, 0));
      final ref = await firestore
          .collection('interactions')
          .doc('int-1')
          .collection('messages')
          .add(model.toFirestore());
      final snap = await ref.get();
      final read = InteractionMessageModel.fromFirestore(snap);

      expect(read.readAt, DateTime(2026, 7, 1, 11, 0));
    });

    test('missing type field on legacy-shaped data defaults to text', () async {
      final ref = await firestore
          .collection('interactions')
          .doc('int-1')
          .collection('messages')
          .add({
        'senderId': 'farmer-1',
        'senderRole': 'farmer',
        'text': 'Hi',
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 1)),
      });
      final snap = await ref.get();
      final read = InteractionMessageModel.fromFirestore(snap);
      expect(read.type, 'text');
    });
  });

  group('type getters', () {
    test('isText/isImage/isSystem reflect the type field', () {
      expect(_message(type: 'text').isText, isTrue);
      expect(_message(type: 'image').isImage, isTrue);
      expect(_message(type: 'system').isSystem, isTrue);
      expect(_message(type: 'image').isText, isFalse);
    });

    test('isRead is true only when readAt is set', () {
      expect(_message().isRead, isFalse);
      expect(_message(readAt: DateTime(2026, 7, 1)).isRead, isTrue);
    });
  });

  group('copyWithModel', () {
    test('marking as read preserves every other field', () {
      final model = _message();
      final read = model.copyWithModel(readAt: DateTime(2026, 7, 1, 12, 0));

      expect(read.readAt, DateTime(2026, 7, 1, 12, 0));
      expect(read.senderId, model.senderId);
      expect(read.text, model.text);
      expect(read.createdAt, model.createdAt);
    });
  });
}
