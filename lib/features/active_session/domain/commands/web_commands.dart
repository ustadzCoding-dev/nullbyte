import 'package:nullbyte/features/active_session/domain/terminal_command.dart';

class CurlCommand extends TerminalCommand {
  @override
  String get name => 'curl';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Transfer data from or to a server';

  @override
  String get usage => 'curl [options] <url>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('curl: no URL specified\nUsage: $usage');
    }

    await Future.delayed(const Duration(milliseconds: 350));

    final url = _extractUrl(args);
    if (url.isEmpty) {
      return TerminalOutput.error('curl: no URL specified\nUsage: $usage');
    }

    final targetHost = _extractHost(url);
    // BUG-11 FIX: hanya m2_l1 yang dibebaskan dari host discovery check
    // (level tersebut adalah recon level yang dimulai dengan curl discovery).
    // m2_l2 sampai m2_l5 tetap butuh nmap dulu agar intended progression terjaga.
    final skipHostCheck = context.levelId == 'm2_l1';
    if (targetHost != null &&
        !skipHostCheck &&
        !context.isHostDiscovered(targetHost)) {
      return TerminalOutput.error(
        'curl: ($targetHost) Connection refused\n[tip] Target ini belum terlihat reachable. Lakukan discovery atau scan dulu sebelum mencoba akses web.',
      );
    }

    final showHeaders =
        args.contains('-I') || args.contains('-i') || args.contains('--head');
    final isPost =
        (args.contains('-X') && args.contains('POST')) ||
        args.contains('-d') ||
        args.contains('--data') ||
        args.contains('--data-raw') ||
        args.contains('-F') ||
        args.contains('--form');
    final postData = _extractPostData(args);

    if (showHeaders) {
      const output = '''HTTP/1.1 200 OK
Date: Mon, 15 Jan 2024 03:42:00 GMT
Server: Apache/2.4.54 (Ubuntu)
X-Powered-By: PHP/8.1.12
Content-Type: text/html; charset=UTF-8
X-Frame-Options: SAMEORIGIN
Set-Cookie: PHPSESSID=abc123def456; path=/; HttpOnly
Content-Length: 4821
Connection: keep-alive''';
      return TerminalOutput.output(output);
    }

    if (url == 'http://192.168.50.10' || url == 'http://192.168.50.10/') {
      context.completeObjective('endpoint_discovered');
      return TerminalOutput.output('''<!DOCTYPE html>
<html>
<body>
<h1>NULLBYTE Demo App</h1>
<a href="/search?q=test">Search</a>
<a href="/login">Login</a>
<!-- recon-note: /recon/flag.txt -->
</body>
</html>''');
    }

    if (url.contains('/recon/flag.txt')) {
      if (!context.isFlagAccessible) {
        return TerminalOutput.output(
          'recon artifact confirmed\nnext-stage target visible in app surface\nAccess denied: flag requires further exploitation\n',
        );
      }
      return TerminalOutput.output(
        'recon artifact confirmed\nnext-stage target visible in app surface\n${context.currentFlag}\n',
      );
    }

    if (url.contains('/search')) {
      // /search endpoint hanya relevan di M2 (SQL injection)
      if (!context.levelId.startsWith('m2')) {
        return TerminalOutput.error('404 Not Found');
      }
      final query = _extractQueryParam(url, 'q');
      // M2 L2: manual SQLi exploit via curl
      if (query.contains('UNION') ||
          query.contains('union') ||
          (query.contains('--') && query.contains("'")) ||
          query.contains('OR 1=1') ||
          query.contains('or 1=1')) {
        context.completeObjective('exploit_successful');
        if (targetHost != null) context.markHostExploited(targetHost);
        if (!context.isFlagAccessible) {
          return TerminalOutput.output(
            'SQL query executed successfully\nMultiple rows returned\nAccess denied: insufficient privileges\n',
          );
        }
        return TerminalOutput.output(
          'SQL query executed successfully\nMultiple rows returned\nDatabase dump:\n${context.currentFlag}\n\n[tip] SQL injection manual berhasil. Gunakan sqlmap untuk pendekatan yang lebih otomatis di level lain.',
        );
      }
      if (query.contains("'")) {
        return TerminalOutput.output('''Search request received for q=$query
SQL syntax error near '$query'
backend hint: parameter q is passed directly into the database query

[tip] Input pengguna tampaknya memengaruhi query database secara langsung.''');
      }
      return TerminalOutput.output(
        '''Search results for "$query"
endpoint: /search
debug: raw parameter q=$query

[tip] Endpoint ini menerima input mentah. Coba uji bagaimana aplikasi bereaksi terhadap karakter yang tidak biasa.''',
      );
    }

    if (url.contains('/cgi-bin/.%2e/%2e%2e/%2e%2e/flag.txt')) {
      // Path traversal hanya relevan di M1 L3/L4 (CVE-2021-41773)
      final levelId = context.levelId;
      if (!levelId.startsWith('m1')) {
        return TerminalOutput.error('404 Not Found');
      }
      context.completeObjective('exploit_successful');
      if (targetHost != null) context.markHostExploited(targetHost);
      if (!context.isFlagAccessible) {
        return TerminalOutput.output(
          'path traversal succeeded\nsensitive file disclosure: /flag.txt\nAccess denied: insufficient privileges\n',
        );
      }
      return TerminalOutput.output(
        'path traversal succeeded\nsensitive file disclosure: /flag.txt\n${context.currentFlag}\n',
      );
    }

    if (url.contains('/uploads/shell.php')) {
      // Webshell hanya relevan di M2 L4/L5
      if (!context.levelId.startsWith('m2')) {
        return TerminalOutput.error('404 Not Found');
      }
      context.completeObjective('exploit_successful');
      if (targetHost != null) context.markHostExploited(targetHost);
      final cmd = _extractQueryParam(url, 'cmd');
      if (cmd.contains('cat')) {
        if (!context.isFlagAccessible) {
          return TerminalOutput.output(
            'webshell command output\nAccess denied: insufficient privileges\n',
          );
        }
        return TerminalOutput.output(
          'webshell command output\n${context.currentFlag}\n',
        );
      }
      if (cmd.contains('ls')) {
        return TerminalOutput.output(
          'webshell command output\nshell.php\nflag.txt\nsecret\n',
        );
      }
      if (cmd.contains('bash') || cmd.contains('/dev/tcp')) {
        context.completeObjective('exploit_successful');
        if (targetHost != null) context.markHostExploited(targetHost);
        return TerminalOutput.success(
          'Reverse shell connection established\nShell session active\n\n[tip] Callback berhasil. Gunakan foothold ini untuk membaca file yang sebelumnya tidak bisa diakses.',
        );
      }
      return TerminalOutput.output('www-data\n');
    }

    if (url.contains('/upload')) {
      // Upload endpoint hanya relevan di M2 L4
      if (context.levelId != 'm2_l4') {
        return TerminalOutput.error(
          '403 Forbidden — upload not available on this endpoint',
        );
      }
      context.completeObjective('exploit_successful');
      if (targetHost != null) context.markHostExploited(targetHost);
      return TerminalOutput.success(
        'Upload accepted\nStored at /uploads/shell.php\nValidation: bypassed via weak MIME checks\n\n[tip] Webshell terunggah. Akses file tersebut dan gunakan parameter cmd untuk mengeksekusi perintah di server.',
      );
    }

    if (url.contains('/backup/') &&
        (url.endsWith('/backup') || url.endsWith('/backup/'))) {
      // JSON topology: 192.168.10.50 (file server)
      if (context.levelId != 'm1_l4') {
        return TerminalOutput.error('403 Forbidden');
      }
      return TerminalOutput.output(
        'index of /backup/\nnotes.txt\narchive.zip\n\n[tip] Direktori backup terbuka. Cari file kecil yang kemungkinan berisi catatan operator atau path sensitif.\n',
      );
    }

    if (url.contains('/notes.txt')) {
      // notes.txt hanya relevan di M1 L4 (backup context)
      if (context.levelId != 'm1_l4') {
        return TerminalOutput.error('404 Not Found');
      }
      return TerminalOutput.output(
        'Backup Schedule:\n'
        '- Full backup: Sundays 02:00\n'
        '- Incremental: Daily 04:00\n'
        '- Flag backup stored in: /flag.txt\n'
        'WARNING: backup directory is world-readable!\n'
        '\n[tip] Catatan operator menyebut lokasi flag. Coba akses path tersebut via curl.\n',
      );
    }

    if (url.contains('/manifest.csv')) {
      // manifest.csv hanya relevan di M1 L5 (export context)
      if (context.levelId != 'm1_l5') {
        return TerminalOutput.error('404 Not Found');
      }
      return TerminalOutput.output(
        'id,type,status,location\n'
        '1,logs,archived,/export/logs/\n'
        '2,config,active,/export/config/\n'
        '3,flag,restricted,/flag.txt\n'
        '\n[tip] Manifest menunjukkan artefak flag di path tertentu. Coba akses langsung.\n',
      );
    }

    if (url.contains('/export') &&
        (url.endsWith('/export') || url.endsWith('/export/'))) {
      // JSON topology: 192.168.20.100 (linux server)
      if (context.levelId != 'm1_l5') {
        return TerminalOutput.error('403 Forbidden');
      }
      return TerminalOutput.output(
        'index of /export/\nflag.txt\nread-only archive endpoint detected\n\n[tip] Endpoint export sering dipakai untuk ekstraksi data. Periksa file yang paling relevan dengan objective.\n',
      );
    }

    if (url.contains('/secret') || url.contains('/flag')) {
      // Flag endpoint hanya relevan di level yang punya web flag
      final levelId = context.levelId;
      if (!levelId.startsWith('m1') && !levelId.startsWith('m2')) {
        return TerminalOutput.error('404 Not Found');
      }
      if (!context.isFlagAccessible) {
        return TerminalOutput.output(
          'Access denied: insufficient privileges\n',
        );
      }
      return TerminalOutput.output('${context.currentFlag}\n');
    }

    if (isPost && url.contains('/login')) {
      // Login bypass hanya relevan di M2 L3
      if (context.levelId != 'm2_l3') {
        return TerminalOutput.error(
          '403 Forbidden — login not available on this endpoint',
        );
      }
      // Accept common SQLi auth bypass patterns
      final isBypass =
          postData.contains("'--") ||
          postData.contains("' --") ||
          postData.contains("' OR '") ||
          postData.contains("' OR \"") ||
          postData.contains("'#") ||
          postData.contains("admin'") ||
          postData.contains("'1'='1") ||
          postData.contains("'1'='1'--");
      if (isBypass) {
        context.completeObjective('exploit_successful');
        if (targetHost != null) context.markHostExploited(targetHost);
        return TerminalOutput.success(
          'Login successful\nAdmin session granted\nNext route: /admin\n\n[tip] Bypass berhasil. Sekarang validasi apa yang benar-benar terbuka di area admin, lalu cari artefak level di sana.',
        );
      }
      return TerminalOutput.error('Login failed\nInvalid credentials');
    }

    if (url.contains('/admin')) {
      if (url.contains('/admin/flag')) {
        if (!context.isFlagAccessible) {
          return TerminalOutput.output(
            'Access denied: insufficient privileges\n',
          );
        }
        return TerminalOutput.output('${context.currentFlag}\n');
      }
      return TerminalOutput.output(
        '<h1>Admin Dashboard</h1>\n<p>flag route: /admin/flag</p>',
      );
    }

    if (url.contains('admin') || url.contains('login')) {
      const output = '''<!DOCTYPE html>
<html>
<head><title>Admin Login</title></head>
<body>
<form method="POST" action="/admin/login">
  <input type="text" name="username" placeholder="Username">
  <input type="password" name="password" placeholder="Password">
  <button type="submit">Login</button>
</form>
</body>
</html>''';
      return TerminalOutput.output(output);
    }

    if (url.contains('api') || url.contains('json')) {
      const output =
          '''{"status":"ok","version":"1.0.3","endpoints":["/api/users","/api/data"],"debug":false}''';
      return TerminalOutput.output(output);
    }

    // Level-specific root page responses for discovered hosts
    final levelId = context.levelId;
    if (levelId.startsWith('m1')) {
      final m1Response = _m1RootResponse(url, context);
      if (m1Response != null) return m1Response;
    }
    if (levelId.startsWith('m2')) {
      final m2Response = _m2RootResponse(url, context);
      if (m2Response != null) return m2Response;
    }
    if (levelId.startsWith('m3')) {
      final m3Response = _m3RootResponse(url, context);
      if (m3Response != null) return m3Response;
    }

    final output =
        '''<!DOCTYPE html>
<html>
<head><title>Welcome to $url</title></head>
<body>
<h1>It works!</h1>
<p>Apache/2.4.54 (Ubuntu) Server at $url Port 80</p>
</body>
</html>''';
    return TerminalOutput.output(output);
  }

  /// M1 level-aware root page responses that guide players toward the next step.
  TerminalOutput? _m1RootResponse(String url, LevelContext context) {
    final levelId = context.levelId;

    switch (levelId) {
      case 'm1_l1':
        // JSON topology: 192.168.1.1 (router), 192.168.1.10 (corp server)
        if (url.contains('192.168.1.10')) {
          return TerminalOutput.output(
            '''<!DOCTYPE html>
<html><body><h1>Corp Intranet</h1>
<p>Welcome to the corporate internal portal.</p>
<!-- TODO: remove /flag.txt before production deploy -->
</body></html>

[tip] Web server terbuka di target. Coba akses path yang disebutkan di komentar HTML.''',
          );
        }
        if (url.contains('192.168.1.1')) {
          return TerminalOutput.output(
            '<html><body><h1>Gateway Router</h1><p>Admin interface on port 80</p></body></html>',
          );
        }
        break;

      case 'm1_l2':
        // JSON topology: 192.168.2.1 (firewall), 192.168.2.10 (Workstation A), 192.168.2.11 (Workstation B)
        if (url.contains('/secret/flag.txt')) {
          return TerminalOutput.output(
            '''nullbyte{m1_l2_port_scan}

[tip] Flag ditemukan! Salin kode flag di atas dan kirim menggunakan tombol "SUBMIT FLAG" di bagian kanan atas layar.''',
          );
        }
        if (url.contains('/secret')) {
          return TerminalOutput.output(
            '''<html><body><h1>Restricted Area</h1>
<p>Files in this directory:</p>
<ul>
  <li><a href="/secret/flag.txt">flag.txt</a></li>
</ul>
</body></html>

[tip] File "flag.txt" ditemukan di dalam direktori secret. Baca isinya dengan: "curl http://192.168.2.11:8080/secret/flag.txt"''',
          );
        }
        if (url.contains('8080')) {
          return TerminalOutput.output(
            '''<html><body><h1>Hidden Service</h1>
<p>Welcome to the staging area.</p>
<a href="/secret">Secret Area</a>
</body></html>

[tip] Direktori "/secret" terdeteksi. Coba akses endpoint tersebut dengan: "curl http://192.168.2.11:8080/secret"''',
          );
        }
        if (url.contains('192.168.2.11')) {
          return TerminalOutput.output(
            '''<html><body><h1>Workstation B</h1>
<p>Dev environment</p>
<a href=":8080">Alternate service</a>
</body></html>

[tip] Ada service web di port non-standar. Coba akses port 8080 dengan perintah: "curl http://192.168.2.11:8080"''',
          );
        }
        break;

      case 'm1_l3':
        // JSON topology: 172.16.0.1 (router), 172.16.0.10 (web server), 172.16.0.20 (db server)
        if (url.contains('172.16.0.10')) {
          return TerminalOutput.output(
            '''<html><body>
<h1>Apache/2.4.49 Test Server</h1>
<p>Default installation — DO NOT EXPOSE TO INTERNET</p>
<!-- Server version visible in headers. Check CVE-2021-41773 -->
</body></html>

[tip] Versi Apache spesifik sering punya kerentanan yang sudah terdokumentasi. Coba path traversal jika versi ini rentan.''',
          );
        }
        break;

      case 'm1_l4':
        // JSON topology: 192.168.10.50 (file server)
        if (url.contains('192.168.10.50')) {
          return TerminalOutput.output(
            '''<html><body><h1>File Server</h1>
<p>Backup repository</p>
<a href="/backup/">Backups</a>
</body></html>

[tip] Direktori backup sering dibiarkan world-readable. Coba enumerasi isinya.''',
          );
        }
        break;

      case 'm1_l5':
        // JSON topology: 192.168.20.100 (linux server)
        if (url.contains('192.168.20.100')) {
          return TerminalOutput.output(
            '''<html><body><h1>Data Export Service</h1>
<p>Automated export pipeline</p>
<a href="/export/">Exports</a>
</body></html>

[tip] Service export otomatis sering menyimpan artefak data. Coba lihat direktori export.''',
          );
        }
        break;
    }
    return null;
  }

  /// M2 level-aware root page responses.
  TerminalOutput? _m2RootResponse(String url, LevelContext context) {
    final levelId = context.levelId;

    switch (levelId) {
      case 'm2_l1':
        // JSON topology: 192.168.50.10 (web app)
        if (url.contains('192.168.50.10')) {
          return TerminalOutput.output(
            '''<!DOCTYPE html>
<html><body><h1>NULLBYTE Demo App</h1>
<a href="/search?q=test">Search</a>
<a href="/login">Login</a>
<!-- recon-note: /recon/flag.txt -->
</body></html>

[tip] Web app terbuka. Perhatikan endpoint dan parameter yang tertaut dari halaman utama.''',
          );
        }
        break;

      case 'm2_l2':
        // JSON topology: 192.168.50.10 (same web app, different level focus)
        if (url.contains('192.168.50.10')) {
          return TerminalOutput.output(
            '''<html><body><h1>Search Gateway</h1>
<form action="/search" method="GET">
  <input name="q" placeholder="Search...">
</form>
</body></html>

[tip] Form pencarian mengirim parameter ke backend. Uji bagaimana input diproses.''',
          );
        }
        break;

      case 'm2_l3':
        // JSON topology: 192.168.50.10 (same web app, login focus)
        if (url.contains('192.168.50.10')) {
          return TerminalOutput.output(
            '''<html><body><h1>Admin Login</h1>
<form method="POST" action="/login">
  <input name="username" placeholder="Username">
  <input name="password" placeholder="Password">
  <button type="submit">Login</button>
</form>
</body></html>

[tip] Form login klasik. Pikirkan bagaimana input username dan password digabung dalam query autentikasi.''',
          );
        }
        break;

      case 'm2_l4':
        // JSON topology: 192.168.50.10 (same web app, upload focus)
        if (url.contains('192.168.50.10')) {
          return TerminalOutput.output(
            '''<html><body><h1>Upload Portal</h1>
<form method="POST" action="/upload" enctype="multipart/form-data">
  <input type="file" name="file">
  <button type="submit">Upload</button>
</form>
</body></html>

[tip] Form upload tersedia. Validasi file sering hanya mengandalkan Content-Type, bukan isi file.''',
          );
        }
        break;

      case 'm2_l5':
        // JSON topology: 192.168.50.10 (same web app, webshell focus)
        if (url.contains('192.168.50.10')) {
          return TerminalOutput.output(
            '''<html><body><h1>Production Server</h1>
<p>Service status: active</p>
<a href="/uploads/">Uploads</a>
</body></html>

[tip] Server produksi punya direktori upload aktif. Jika webshell sudah ada, pikirkan cara mengubahnya menjadi shell yang lebih stabil.''',
          );
        }
        break;
    }
    return null;
  }

  /// M3 level-aware root page responses.
  TerminalOutput? _m3RootResponse(String url, LevelContext context) {
    final levelId = context.levelId;

    switch (levelId) {
      case 'm3_l1':
        // JSON topology: 192.168.100.10 (target host)
        if (url.contains('192.168.100.')) {
          return TerminalOutput.output(
            '<html><body><h1>Target Host</h1><p>SSH service active</p></body></html>\n\n[tip] SSH tersedia. Gunakan foothold yang paling langsung lalu lanjut ke enumerasi dasar sistem.',
          );
        }
        break;

      case 'm3_l2':
        // JSON topology: 192.168.100.20 (enumeration target)
        if (url.contains('192.168.100.')) {
          return TerminalOutput.output(
            '<html><body><h1>Compromised Host</h1><p>Enumerate local resources</p></body></html>\n\n[tip] Setelah foothold, kumpulkan identitas user, grup, dan file sensitif yang bisa dibaca.',
          );
        }
        break;

      case 'm3_l3':
        // JSON topology: 192.168.100.30 (sudo misconfig target)
        if (url.contains('192.168.100.')) {
          return TerminalOutput.output(
            '<html><body><h1>Target Workstation</h1><p>Check sudo configuration</p></body></html>\n\n[tip] Setelah login, cek apakah ada misconfiguration di sudo atau binary berbahaya yang bisa dieksekusi lebih tinggi.',
          );
        }
        break;

      case 'm3_l4':
        // JSON topology: 192.168.100.40 (jump host), 10.10.10.20 (internal)
        if (url.contains('192.168.100.') || url.contains('10.10.10.')) {
          return TerminalOutput.output(
            '<html><body><h1>Pivot Point</h1><p>Internal network reachable</p></body></html>\n\n[tip] Gunakan host ini sebagai titik pivot sebelum melihat jaringan internal.',
          );
        }
        break;

      case 'm3_l5':
        // JSON topology: 192.168.120.1 (operator host)
        if (url.contains('192.168.120.')) {
          return TerminalOutput.output(
            '<html><body><h1>Final Target</h1><p>Root escalation required</p></body></html>\n\n[tip] Fokus pada jalur escalation yang disediakan sistem. Cari command yang diizinkan untuk naik privilege.',
          );
        }
        break;
    }
    return null;
  }

  String _extractPostData(List<String> args) {
    for (final flag in ['-d', '--data', '--data-raw', '-F', '--form']) {
      final idx = args.indexOf(flag);
      if (idx >= 0 && idx + 1 < args.length) {
        return args[idx + 1];
      }
    }
    return '';
  }

  String _extractUrl(List<String> args) {
    for (final arg in args) {
      if (arg.startsWith('http://') || arg.startsWith('https://')) {
        return arg;
      }
    }
    return '';
  }

  String? _extractHost(String url) {
    final match = RegExp(r'https?://([^/:]+)').firstMatch(url);
    return match?.group(1);
  }

  String _extractQueryParam(String url, String key) {
    final queryIndex = url.indexOf('?');
    if (queryIndex == -1) return '';
    final query = url.substring(queryIndex + 1).split('&');
    for (final part in query) {
      final pieces = part.split('=');
      if (pieces.length >= 2 && pieces.first == key) {
        return pieces.sublist(1).join('=');
      }
    }
    return '';
  }
}

class WgetCommand extends TerminalCommand {
  @override
  String get name => 'wget';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Non-interactive network downloader';

  @override
  String get usage => 'wget [options] <url>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('wget: missing URL\nUsage: $usage');
    }

    final url = args.where((a) => !a.startsWith('-')).lastOrNull ?? '';
    final filename = url.split('/').last.isNotEmpty
        ? url.split('/').last
        : 'index.html';

    // Host validation: harus ada di topology dan sudah di-discover
    final hostMatch = RegExp(r'https?://([^/:]+)').firstMatch(url);
    if (hostMatch != null) {
      final targetHost = hostMatch.group(1)!;
      if (context.isHostInTopology(targetHost) &&
          !context.isHostDiscovered(targetHost)) {
        return TerminalOutput.error(
          'wget: unable to resolve host address $targetHost\n[tip] Target belum reachable. Scan jaringan dulu dengan nmap.',
        );
      }
      if (!context.isHostInTopology(targetHost)) {
        return TerminalOutput.error('wget: failed: No route to host.');
      }
    }

    await Future.delayed(const Duration(milliseconds: 450));

    final levelId = context.levelId;
    String? tip;
    if (levelId == 'm2_l4') {
      tip =
          '[tip] File berhasil diunduh. Gunakan curl -F untuk upload webshell ke server.';
    } else if (levelId == 'm2_l5') {
      tip =
          '[tip] File berhasil diunduh. Gunakan webshell yang sudah ada untuk reverse shell.';
    }

    final output =
        '''--2024-01-15 03:42:00--  $url
Resolving ${url.replaceAll(RegExp(r'https?://'), '').split('/').first}... ${url.replaceAll(RegExp(r'https?://'), '').split('/').first}
Connecting to ${url.replaceAll(RegExp(r'https?://'), '').split('/').first}:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: ${(filename.hashCode.abs() % 90000) + 1024} (${((filename.hashCode.abs() % 90000) + 1024) ~/ 1024}K) [application/octet-stream]
Saving to: '$filename'

$filename          100%[===================>]  ${((filename.hashCode.abs() % 90000) + 1024) ~/ 1024}K  --.-KB/s    in 0.1s

2024-01-15 03:42:00 (${(filename.hashCode.abs() % 900) + 100} KB/s) - '$filename' saved [${(filename.hashCode.abs() % 90000) + 1024}/${(filename.hashCode.abs() % 90000) + 1024}]''';

    return TerminalOutput.success(tip != null ? '$output\n$tip' : output);
  }
}
