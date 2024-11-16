import 'dart:isolate';

void listActiveIsolates() {
  Isolate.current.addErrorListener(RawReceivePort((dynamic pair) {
    final List<dynamic> errorAndStacktrace = pair;
    print('Isolate error: ${errorAndStacktrace.first}');
    print('Isolate stack trace: ${errorAndStacktrace.last}');
  }).sendPort);

  print('Current Isolate: ${Isolate.current}');
}
