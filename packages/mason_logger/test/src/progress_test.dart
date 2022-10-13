import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStdout extends Mock implements Stdout {}

class MockStdin extends Mock implements Stdin {}

void main() {
  group('Progress', () {
    late Stdout stdout;

    setUp(() {
      stdout = MockStdout();
      when(() => stdout.supportsAnsiEscapes).thenReturn(true);
    });

    test('writes ms when elapsed time is less than 0.1s', () async {
      await runZoned(
        () async {
          await IOOverrides.runZoned(
            () async {
              const message = 'test message';
              final progress = Logger().progress(message);
              await Future<void>.delayed(const Duration(milliseconds: 10));
              progress.complete();
              verify(
                () => stdout.write(any(that: matches(RegExp(r'\(\d\dms\)')))),
              ).called(1);
            },
            stdout: () => stdout,
          );
        },
        zoneValues: {AnsiCode: true},
      );
    });

    test('writes custom progress animation to stdout', () async {
      await IOOverrides.runZoned(
        () async {
          const time = '(0.Xs)';
          const message = 'test message';
          const progressOptions = ProgressOptions(
            animation: ProgressAnimation(frames: ['+', 'x', '*']),
          );
          final done = Logger().progress(message, options: progressOptions);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          done.complete();
          verifyInOrder([
            () {
              stdout.write(
                '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}+')} $message... ${darkGray.wrap('(0.1s)')}''',
              );
            },
            () {
              stdout.write(
                '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}x')} $message... ${darkGray.wrap('(0.2s)')}''',
              );
            },
            () {
              stdout.write(
                '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}*')} $message... ${darkGray.wrap('(0.3s)')}''',
              );
            },
            () {
              stdout.write(
                '''\b${'\b' * (message.length + 4 + time.length)}\u001b[2K${lightGreen.wrap('✓')} $message ${darkGray.wrap('(0.4s)')}\n''',
              );
            },
          ]);
        },
        stdout: () => stdout,
        stdin: () => stdin,
      );
    });

    test('supports empty list of animation frames', () async {
      await IOOverrides.runZoned(
        () async {
          const time = '(0.Xs)';
          const message = 'test message';
          const progressOptions = ProgressOptions(
            animation: ProgressAnimation(frames: []),
          );
          final done = Logger().progress(message, options: progressOptions);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          done.complete();
          verifyInOrder([
            () {
              stdout.write(
                '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}')}$message... ${darkGray.wrap('(0.1s)')}''',
              );
            },
            () {
              stdout.write(
                '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}')}$message... ${darkGray.wrap('(0.2s)')}''',
              );
            },
            () {
              stdout.write(
                '''${lightGreen.wrap('\b${'\b' * (message.length + 4 + time.length)}')}$message... ${darkGray.wrap('(0.3s)')}''',
              );
            },
            () {
              stdout.write(
                '''\b${'\b' * (message.length + 4 + time.length)}\u001b[2K${lightGreen.wrap('✓')} $message ${darkGray.wrap('(0.4s)')}\n''',
              );
            },
          ]);
        },
        stdout: () => stdout,
        stdin: () => stdin,
      );
    });

    group('.complete', () {
      test('writes lines to stdout', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const time = '(0.1s)';
                const message = 'test message';
                final progress = Logger().progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.complete();
                verify(
                  () {
                    stdout.write(
                      any(
                        that: contains(
                          '''[92m⠙[0m $message... [90m''',
                        ),
                      ),
                    );
                  },
                ).called(1);
                verify(
                  () {
                    stdout.write(
                      '''[2K[92m✓[0m $message [90m$time[0m\n''',
                    );
                  },
                ).called(1);
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write lines to stdout when Level > info', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'test message';
                final progress = Logger(level: Level.warning).progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.complete();
                verifyNever(() => stdout.write(any()));
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.update', () {
      test('writes lines to stdout', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'message';
                const update = 'update';
                const time = '(0.1s)';
                final progress = Logger().progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.update(update);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                verify(
                  () {
                    stdout.write(
                      any(
                        that: contains(
                          '''[92m⠙[0m $message... [90m''',
                        ),
                      ),
                    );
                  },
                ).called(1);
                verify(
                  () {
                    stdout.write(
                      '''[92m⠹[0m $update... [90m$time[0m''',
                    );
                  },
                ).called(1);
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not writes to stdout when Level > info', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'message';
                const update = 'update';
                final progress = Logger(level: Level.warning).progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.update(update);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                verifyNever(() => stdout.write(any()));
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.fail', () {
      test('writes lines to stdout', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const time = '(0.1s)';
                const message = 'test message';
                final progress = Logger().progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.fail();
                verify(
                  () {
                    stdout.write(
                      any(
                        that: contains(
                          '''[92m⠙[0m $message... [90m''',
                        ),
                      ),
                    );
                  },
                ).called(1);
                verify(
                  () {
                    stdout.write(
                      '''[2K[31m✗[0m $message [90m$time[0m\n''',
                    );
                  },
                ).called(1);
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write to stdout when Level > info', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'test message';
                final progress = Logger(level: Level.warning).progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.fail();
                verifyNever(() => stdout.write(any()));
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });
    });

    group('.cancel', () {
      test('writes lines to stdout', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'test message';
                final progress = Logger().progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.cancel();
                verify(
                  () {
                    stdout.write(
                      any(
                        that: contains(
                          '''[92m⠙[0m $message... [90m''',
                        ),
                      ),
                    );
                  },
                ).called(1);
                verify(
                  () {
                    stdout.write(
                      '''[2K''',
                    );
                  },
                ).called(1);
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });

      test('does not write to stdout when Level > info', () async {
        await runZoned(
          () async {
            await IOOverrides.runZoned(
              () async {
                const message = 'test message';
                final progress = Logger(level: Level.warning).progress(message);
                await Future<void>.delayed(const Duration(milliseconds: 100));
                progress.cancel();
                verifyNever(() => stdout.write(any()));
              },
              stdout: () => stdout,
            );
          },
          zoneValues: {AnsiCode: true},
        );
      });
    });
  });
}
