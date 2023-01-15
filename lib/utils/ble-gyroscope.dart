import 'dart:typed_data';
import 'dart:async';
import 'dart:math';
import 'package:vector_math/vector_math.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:esense_flutter/esense.dart';

class BLEGyroscope extends StatefulWidget {
  const BLEGyroscope({super.key});

  @override
  State<StatefulWidget> createState() => BLEGyroscopeState();
}

class BLEGyroscopeState extends State<BLEGyroscope> {
  bool _connected = false;
  final ble = FlutterReactiveBle();
  final esense = ESenseManager('eSense-0332');
  final _gyroscopeService = Uuid.parse("0000a000-1212-efde-1523-785feabcd123");
  final _gyroscopeCharacteristic =
      Uuid.parse("0000a001-1212-efde-1523-785feabcd123");
  final _gyroscopeConf = [
    0x32,
    0x31,
    0x39,
    0x32,
    0x37,
    0x34,
    0x31,
    0x30,
    0x35,
    0x39,
    0x35,
    0x35,
    0x30,
    0x32,
    0x34,
    0x35
  ];
  DiscoveredDevice? _device;
  Stream<List<int>> _gyroscopeStream = const Stream.empty();
  Vector3 _acc = Vector3.zero();
  int _accX = 0;
  int _accY = 0;
  int _accZ = 0;
  int _lastShakeTime = DateTime.now().millisecondsSinceEpoch;

  void _confGyro() async {
    if (_connected) {
      final characteristic = QualifiedCharacteristic(
        serviceId: _gyroscopeService,
        characteristicId: _gyroscopeCharacteristic,
        deviceId: _device!.id,
      );
      await ble.writeCharacteristicWithoutResponse(characteristic,
          value: _gyroscopeConf);
    }
  }

  void _setupESense(){
    _gyroscopeStream = esense.sensorEvents.map((event) {
      List<int> data = [18];
      var x = event.accel![0] * 33;
      var y = event.accel![1] * 33;
      var z = event.accel![2] * 33;
      data[14] = x;
      data[16] = y;
      data[18] = z;
      return data;
    });
  }

  Vector3 _extractAcc(List<int> rawData) {
    Int8List bytes = Int8List.fromList(rawData);
    // According to the accelerometer
    _accX = bytes[14];
    _accY = bytes[16];
    _accZ = bytes[18];
    // +X is out the face, +Z is down, +Y is to the right
    _accZ = _accY;
    _accX = -_accX;
    _accY = -_accZ;
    _acc = Vector3(_accX.toDouble(), _accY.toDouble(), _accZ.toDouble());
    return _acc;
  }

  Stream<Vector3> get accStream =>
      _gyroscopeStream.map((data) => _extractAcc(data));

  Stream<double> get pitchStream => accStream.map(
      (acc) => atan2(acc.x, sqrt(acc.y * acc.y + acc.z * acc.z)) * 180 / pi);

  Stream<double> get rollStream => accStream.map(
      (acc) => atan2(acc.y, sqrt(acc.x * acc.x + acc.z * acc.z)) * 180 / pi);

  Stream<bool> pitchShakeStream(double threshold) {
    return pitchStream
        .map((pitch) => pitch.abs() > threshold)
        .where((value) => value);
  }

  Stream<bool> rollShakeStream(double threshold) {
    return rollStream
        .map((roll) => roll.abs() > threshold)
        .where((value) => value);
  }

  Stream<bool> simpleShakeStream(double threshold, int shakeSlopTimeMS) {
    return accStream.map((acc) {
      double g = acc.length;
      if (g > threshold) {
        var now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastShakeTime > shakeSlopTimeMS) {
          _lastShakeTime = now;
          return true;
        }
      }
      return false;
    });
  }

  Future<void> connect() async {
    if (await Permission.bluetoothScan.isDenied) {
      if(await Permission.bluetoothScan.request().isDenied) {
        return;
      }
    }
    if (await Permission.bluetoothConnect.isDenied) {
      if(await Permission.bluetoothConnect.request().isDenied) {
        return;
      }
    }
    esense.connectionEvents.listen((event) {
      if (event.type == ConnectionType.connected) {
        setState(() {
          _connected = true;
        });
        _setupESense();
      } else if (event.type == ConnectionType.disconnected) {
        setState(() {
          _connected = false;
        });
        _gyroscopeStream = const Stream.empty();
      } else if (event.type == ConnectionType.device_found) {
        esense.connect();
      }
    });
    await esense.connect();
    if (_connected) {
      return;
    }
    ble.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen(
        (scanResult) {
      if (scanResult.name == "earconnect") {
        if (!_connected) {
          ble
              .connectToDevice(
                  id: scanResult.id,
                  connectionTimeout: const Duration(seconds: 1))
              .listen((connectionStateUpdate) {
            if (kDebugMode) {
              print('Connection state: $connectionStateUpdate');
            }
            if (connectionStateUpdate.connectionState ==
                DeviceConnectionState.connected) {
              _device = scanResult;
              _confGyro();
              _gyroscopeStream =
                  ble.subscribeToCharacteristic(QualifiedCharacteristic(
                serviceId: _gyroscopeService,
                characteristicId: _gyroscopeCharacteristic,
                deviceId: _device!.id,
              ));
              setState(() {
                _connected = true;
              });
            }
            if (connectionStateUpdate.connectionState ==
                DeviceConnectionState.disconnected) {
              _gyroscopeStream = const Stream.empty();
              setState(() {
                _connected = false;
                _device = null;
              });
            }
          });
        }
      }
    });
  }

  get isConnected => _connected;
  get accX => _accX;
  get accY => _accY;
  get accZ => _accZ;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !_connected,
      child: FloatingActionButton(
        onPressed: connect,
        child: const Icon(Icons.bluetooth_searching_sharp),
      ),
    );
  }
}
