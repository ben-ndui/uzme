import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/screens/shared/chat_input_controller.dart';

import '../../helpers/widget_test_helpers.dart';

class MockMessagingStorageService extends Mock implements MessagingStorageService {}

class MockAudioRecordService extends Mock implements AudioRecordService {}

class FakeFile extends Fake implements File {}

class FakeSendAttachmentMessageEvent extends Fake implements SendAttachmentMessageEvent {}

void main() {
  late MockMessagingStorageService storage;
  late MockMessagingBloc messagingBloc;
  late ChatInputController controller;

  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(FakeSendAttachmentMessageEvent());
  });

  setUp(() {
    storage = MockMessagingStorageService();
    messagingBloc = MockMessagingBloc();
    when(() => messagingBloc.state).thenReturn(const MessagingInitialState());
    controller = ChatInputController(
      conversationId: 'conv-1',
      storageService: storage,
      audioService: MockAudioRecordService(),
    );
  });

  Future<BuildContext> pumpAndCaptureContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(buildTestApp(
      messagingBloc: messagingBloc,
      child: Scaffold(
        body: Builder(builder: (context) {
          captured = context;
          return const SizedBox();
        }),
      ),
    ));
    return captured;
  }

  testWidgets('sendAttachment : succès → dispatch SendAttachmentMessageEvent une seule fois', (tester) async {
    final context = await pumpAndCaptureContext(tester);
    final file = File('/Users/eng/Enregistrements/mix.wav');
    const attachment = MessageAttachment(
      url: 'https://storage/mix.wav',
      fileName: 'mix.wav',
      fileType: 'audio/wav',
    );
    when(() => storage.uploadFile(file: file, conversationId: 'conv-1'))
        .thenAnswer((_) async => SmoothResponse.success(data: attachment));

    await controller.sendAttachment(context, file);

    verify(() => messagingBloc.add(any(that: isA<SendAttachmentMessageEvent>()))).called(1);
    expect(controller.isUploading, isFalse);
  });

  testWidgets('sendAttachment : échec → ne dispatch rien et ne plante pas', (tester) async {
    final context = await pumpAndCaptureContext(tester);
    final file = File('/Users/eng/Enregistrements/mix.wav');
    when(() => storage.uploadFile(file: file, conversationId: 'conv-1'))
        .thenAnswer((_) async => SmoothResponse.error(message: 'offline'));

    await controller.sendAttachment(context, file);

    verifyNever(() => messagingBloc.add(any(that: isA<SendAttachmentMessageEvent>())));
    expect(controller.isUploading, isFalse);
  });

  testWidgets('sendAttachment : isUploading repasse à false même si l\'upload lève une exception', (tester) async {
    final context = await pumpAndCaptureContext(tester);
    final file = File('/Users/eng/Enregistrements/mix.wav');
    when(() => storage.uploadFile(file: file, conversationId: 'conv-1'))
        .thenThrow(Exception('réseau coupé'));

    await expectLater(controller.sendAttachment(context, file), throwsException);

    expect(controller.isUploading, isFalse);
  });
}
