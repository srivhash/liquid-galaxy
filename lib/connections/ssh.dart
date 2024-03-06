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
          lng: 78.4772, lat: 17.4065, range: 7000, tilt: 45, heading: 0)));

      File inputFile = await makeFile("OrbitKML2", orbitKML);
      await uploadKMLFile(inputFile, "OrbitKML2", "Task_Orbit");
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
  loadSlaveKML(String kmlName, String task) async {
    try {
      final v = await _client!.execute(
          "echo 'http://lg2:81/$kmlName.kml' > /var/www/html/kmls.txt");

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

  cleanSlaves() async {
    try {
      await _client!.run("echo '' > /var/www/html/kml/slave_2.kml");
      await _client!.run("echo '' > /var/www/html/kml/slave_3.kml");
    } catch (error) {
      await cleanSlaves();
    }
  }
  
  // int infoSlave=2;
  Future<void> sendKMLToSlave() async {
    try {
      String command = """chmod 777 /var/www/html/kml/slave_2.kml; echo '<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>historic.kml</name> 
    <Style id="purple_paddle">
      <BalloonStyle>
        <text>\$[description]</text>
        <bgColor>ffffffff</bgColor>
      </BalloonStyle>
    </Style>
    <Placemark id="0A7ACC68BF23CB81B354">
      <name>Baloon</name>
      <Snippet maxLines="0"></Snippet>
      <description>
      <![CDATA[<!-- BalloonStyle background color: ffffffff -->
        <table width="400" height="300" align="left">
          <tr>
            <td colspan="2" align="center">
              <h2> IIIT Hyderabad</h2>
            </td>
          </tr>
          <tr>
            <td colspan="2" align="center">
              <h1>Hyderabad, India</h1>
            </td>
          </tr>
        </table>]]>
      </description>
      <LookAt>
        <longitude>78.4772</longitude>
        <latitude>17.4065</latitude>
        <altitude>0</altitude>
        <heading>0</heading>
        <tilt>0</tilt>
        <range>24000</range>
      </LookAt>
      <styleUrl>#purple_paddle</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>-17.841486,28.638478,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>
' > /var/www/html/kml/slave_2.kml""";
      await _client!
          .execute(command);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  setRefresh() async {
    try {
      for (var i = 2; i <= int.parse(_numberOfRigs); i++) {
        String search = '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href>';
        String replace =
            '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';

        await _client!.execute(
            'sshpass -p $_passwordOrKey ssh -t lg$i \'echo $_passwordOrKey | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml\'');
        await _client!.execute(
            'sshpass -p $_passwordOrKey ssh -t lg$i \'echo $_passwordOrKey | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml\'');
      }
    } catch (error) {
      print("ERROR");
    }
  }

  

}