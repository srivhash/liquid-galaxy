// TODO 2 Done: Import 'dartssh2' package
import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './look_at_entity.dart';
import './orbit_entity.dart';

class SSH {
  late String _host;
  late String _port;
  late String _username;
  late String _passwordOrKey;
  late String _numberOfRigs;
  SSHClient? _client;

  // Initialize connection details from shared preferences
  Future<void> initConnectionDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('ipAddress') ?? 'default_host';
    _port = prefs.getString('sshPort') ?? '22';
    _username = prefs.getString('username') ?? 'lg';
    _passwordOrKey = prefs.getString('password') ?? 'lg';
    _numberOfRigs = prefs.getString('numberOfRigs') ?? '3';
  }

  // Connect to the Liquid Galaxy system
  Future<bool?> connectToLG() async {
    await initConnectionDetails();

    try {
      // TODO 3 Done: Connect to Liquid Galaxy system, using examples from https://pub.dev/packages/dartssh2#:~:text=freeBlocks%7D%27)%3B-,%F0%9F%AA%9C%20Example%20%23,-SSH%20client%3A
      final socket = await SSHSocket.connect(_host, int.parse(_port));

      _client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _passwordOrKey,
      );
      print(
          'host: $_host, port: $_port, username: $_username, password: $_passwordOrKey');
      return true;
    } on SocketException catch (e) {
      print('Failed to connect: $e');
      return false;
    }
  }

  Future<SSHSession?> execute() async {
    try {
      if (_client == null) {
        print('SSH client is not initialized.');
        return null;
      }
      //   TODO 4 Done: Execute a demo command: echo "search=Lleida" >/tmp/query.txt
      final execResult =
          await _client!.execute('echo "search=Spain" >/tmp/query.txt');
      print('Command 4 executed');
      return execResult;
    } catch (e) {
      print('An error occurred while executing the command: $e');
      return null;
    }
  }

  // DEMO above, all the other functions below
  makeFile(String filename, String content) async {
    try {
      var localPath = await getApplicationDocumentsDirectory();
      File localFile = File('${localPath.path}/${filename}.kml');
      await localFile.writeAsString(content);

      return localFile;
    } catch (e) {
      return null;
    }
  }
  Future<void> orbitCity() async {
    try {
      if (_client == null) {
        print('MESSAGE :: SSH CLIENT IS NOT INITIALISED');
        return;
      }

      await cleanKML();

      String orbitKML = OrbitEntity.buildOrbit(OrbitEntity.tag(LookAtEntity(
          lng: 0.6222, lat: 41.6167, range: 7000, tilt: 60, heading: 0)));

      File inputFile = await makeFile("OrbitKML", orbitKML);
      await uploadKMLFile(inputFile, "OrbitKML", "Task_Orbit");
    } catch (e) {
      print("Error");
    }
  }
  uploadKMLFile(File inputFile, String kmlName, String task) async {
    try {
      bool uploading = true;
      final sftp = await _client!.sftp();
      final file = await sftp.open('/var/www/html/$kmlName.kml',
          mode: SftpFileOpenMode.create |
          SftpFileOpenMode.truncate |
          SftpFileOpenMode.write);
      var fileSize = await inputFile.length();
      file.write(inputFile.openRead().cast(), onProgress: (progress) async {
        if (fileSize == progress) {
          uploading = false;
          if (task == "Task_Orbit") {
            await loadKML("OrbitKML", task);
          } else if (task == "Task_Balloon") {
            await loadKML("BalloonKML", task);
          }
        }
      });
    } catch (e) {
      print("Error");
    }
  }

  loadKML(String kmlName, String task) async {
    try {
      final v = await _client!.execute(
          "echo 'http://lg1:81/$kmlName.kml' > /var/www/html/kmls.txt");

      if (task == "Task_Orbit") {
        await beginOrbiting();
      }
    } catch (error) {
      print("error");
      await loadKML(kmlName, task);
    }
  }

  beginOrbiting() async {
    try {
      final res = await _client!.run('echo "playtour=Orbit" > /tmp/query.txt');
    } catch (error) {
      await beginOrbiting();
    }
  }
  Future<SSHSession?> rebootLG() async {
    try {
      if (_client == null) {
        print('SSH client is not initialized.');
        return null;
      }
      for (int i = int.parse(_numberOfRigs); i > 0; i--) {
        _client!.execute(
            'sshpass -p $_passwordOrKey ssh -t lg$i "echo $_passwordOrKey | sudo -S reboot" ');
        print(
            'sshpass -p $_passwordOrKey ssh -t lg$i "echo $_passwordOrKey | sudo -S reboot"');
      }
      return null;
    } catch (e) {
      print('An error occurred while executing the command: Se');
      return null;
    }
  }
  Future<SSHSession?> searchPlace(String search) async {
    try {
      if (_client == null) {
        print('SSH client is not initialized.');
        return null;
      }
      final execResult = await _client!.execute('echo "search=$search" > /tmp/query.txt');
      print('Command executed');
      return execResult;
    } catch (e) {
      print('An error occurred while executing the command: $e');
      return null;
    }
  }
  cleanKML() async {
    try {
      await stopOrbit();
      await _client!.run("echo '' > /tmp/query.txt");
      await _client!.run("echo '' > /var/www/html/kmls.txt");
    } catch (error) {
      await cleanKML();
    }
  }

  stopOrbit() async {
    try {
      await _client!.run('echo "exittour=true" > /tmp/query.txt');
    } catch (error) {
      stopOrbit();
    }
  }

  startOrbit() async {
    try {
      await _client!.run('echo "playtour=Orbit" > /tmp/query.txt');
    } catch (error) {
      stopOrbit();
    }
  }

}