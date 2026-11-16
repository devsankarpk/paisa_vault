import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsd/nsd.dart';

import 'secure_channel.dart';

const serviceType = '_paisavault._tcp';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Wi-Fi sync spike',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const Home(),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final log = <String>[];
  final _manual = TextEditingController();
  late final String myName;
  late SecureChannel channel;
  HttpServer? server;
  Registration? registration;
  Discovery? discovery;
  final sessions = <String, Session>{};
  final started = Stopwatch();
  final tried = <String>{};
  String status = 'Starting...';

  void add(String s) {
    final t = (started.elapsedMilliseconds / 1000).toStringAsFixed(1);
    debugPrint('PV_SYNC $t s $s');
    if (mounted) setState(() => log.insert(0, '[$t s] $s'));
  }

  @override
  void initState() {
    super.initState();
    myName =
        '${Platform.isIOS ? "iphone" : "android"}-${Random().nextInt(9000) + 1000}';
    unawaited(_start());
  }

  Future<void> _start() async {
    started.start();
    channel = await SecureChannel.create();
    server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    add('Server listening on port ${server!.port} as $myName');
    server!.listen(_handle);
    final ips = <String>[];
    for (final i in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    )) {
      for (final a in i.addresses) {
        ips.add('${a.address} (${i.name})');
      }
    }
    add('My addresses: ${ips.join(", ")}');
    try {
      registration = await register(
        Service(name: myName, type: serviceType, port: server!.port),
      );
      add('Advertised on the network');
      discovery = await startDiscovery(serviceType, autoResolve: true);
      discovery!.addServiceListener((service, status) {
        if (status == ServiceStatus.found) _onFound(service);
      });
      add('Looking for other phones...');
      setState(() => status = 'Waiting for the other phone');
    } catch (e) {
      add('Discovery error: $e');
      setState(() => status = 'Discovery failed, use manual address');
    }
  }

  // Server side: /hello exchanges keys, /msg receives and answers with encrypted text.
  Future<void> _handle(HttpRequest req) async {
    try {
      final body = jsonDecode(
        await utf8.decoder.bind(req).join(),
      ) as Map<String, dynamic>;
      if (req.uri.path == '/hello') {
        final from = body['name'] as String;
        final peerPub = base64.decode(body['pub'] as String);
        sessions[from] = await channel.sessionWith(peerPub);
        add('Handshake from $from, code ${sessions[from]!.code}');
        req.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'name': myName,
              'pub': base64.encode(channel.publicKey),
            }),
          );
      } else if (req.uri.path == '/msg') {
        final from = body['from'] as String;
        final s = sessions[from];
        if (s == null) {
          req.response.statusCode = 403;
        } else {
          final text = await s.decrypt(body);
          add('Received from $from: "$text"');
          final reply = await s.encrypt('reply from $myName');
          req.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(reply));
        }
      } else {
        req.response.statusCode = 404;
      }
    } catch (e) {
      add('Server error: $e');
      req.response.statusCode = 400;
    }
    await req.response.close();
  }

  Future<void> _onFound(Service s) async {
    final name = s.name;
    if (name == null || name == myName) return;
    final host =
        s.addresses
            ?.firstWhere(
              (a) => a.type == InternetAddressType.IPv4,
              orElse: () => s.addresses!.first,
            )
            .address ??
        s.host;
    final port = s.port;
    if (host == null || port == null) return;
    add('Found $name at $host:$port');
    // Only the phone with the smaller name starts, so both don't start at once.
    if (myName.compareTo(name) < 0) await _connect(host, port, name);
  }

  Future<void> _connect(String host, int port, [String? peerName]) async {
    final key = '$host:$port';
    if (!tried.add(key)) return;
    final sw = Stopwatch()..start();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final hello = await _post(client, host, port, '/hello', {
        'name': myName,
        'pub': base64.encode(channel.publicKey),
      });
      final peer = hello['name'] as String;
      final session = await channel.sessionWith(
        base64.decode(hello['pub'] as String),
      );
      sessions[peer] = session;
      add(
        'Handshake with $peer done in ${sw.elapsedMilliseconds} ms, code ${session.code}',
      );
      sw.reset();
      final enc = await session.encrypt('hello from $myName');
      final reply = await _post(client, host, port, '/msg', {
        'from': myName,
        ...enc,
      });
      add(
        'Reply: "${await session.decrypt(reply)}" (message round trip ${sw.elapsedMilliseconds} ms)',
      );
      setState(
        () => status =
            'Connected to $peer. Check the code matches on both phones.',
      );
    } catch (e) {
      add('Connect to $key failed: $e');
      tried.remove(key);
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _post(
    HttpClient c,
    String host,
    int port,
    String path,
    Map<String, dynamic> body,
  ) async {
    final r = await c.post(host, port, path);
    r.headers.contentType = ContentType.json;
    r.write(jsonEncode(body));
    final resp = await r.close();
    final text = await utf8.decoder.bind(resp).join();
    if (resp.statusCode != 200) throw 'HTTP ${resp.statusCode}';
    return jsonDecode(text) as Map<String, dynamic>;
  }

  @override
  void dispose() {
    if (registration != null) unregister(registration!);
    if (discovery != null) stopDiscovery(discovery!);
    server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Wi-Fi sync: $myName')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manual,
                  decoration: const InputDecoration(
                    labelText: 'Manual: ip:port (fallback)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final p = _manual.text.trim().split(':');
                  if (p.length == 2) _connect(p[0], int.parse(p[1]));
                },
                child: const Text('Connect'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: log.reversed.join('\n'))),
            child: const Text('Copy log'),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                for (final l in log)
                  Text(l, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
