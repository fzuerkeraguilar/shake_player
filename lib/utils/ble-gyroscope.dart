import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BLEGyroscope{
  bool _isConnected = false;
  final flutterReactiveBle = FlutterReactiveBle();
  final _gyroscopeService = Uuid.parse("0000a000-1212-efde-1523-785feabcd123");
  final _gyroscopeCharacteristic = Uuid.parse("0000a001-1212-efde-1523-785feabcd123");
  final _gyroscopeConf = [0x32, 0x31, 0x39, 0x32, 0x37, 0x34, 0x31, 0x30, 0x35, 0x39, 0x35, 0x35, 0x30, 0x32, 0x34, 0x35];
  DiscoveredDevice? _device;
  int _accX = 0;
  int _accY = 0;
  int _accZ = 0;

  void _confGyro() async{
    if(_isConnected){
      final characteristic = QualifiedCharacteristic(
        serviceId: _gyroscopeService,
        characteristicId: _gyroscopeCharacteristic,
        deviceId: _device!.id,
      );
      await flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: _gyroscopeConf);
    }
  }

  void _updateAcc(rawData){
    Int8List bytes = Int8List.fromList(rawData);
    _accX = bytes[14];
    _accY = bytes[16];
    _accZ = bytes[18];
  }

  Stream<int> get accXStream => flutterReactiveBle.subscribeToCharacteristic(
    QualifiedCharacteristic(
      serviceId: _gyroscopeService,
      characteristicId: _gyroscopeCharacteristic,
      deviceId: _device!.id,
    ),
  ).map((event) {
    _updateAcc(event);
    return _accX;
  });

  Stream<int> get accYStream => flutterReactiveBle.subscribeToCharacteristic(
    QualifiedCharacteristic(
      serviceId: _gyroscopeService,
      characteristicId: _gyroscopeCharacteristic,
      deviceId: _device!.id,
    ),
  ).map((event) {
    _updateAcc(event);
    return _accY;
  });

  Stream<int> get accZStream => flutterReactiveBle.subscribeToCharacteristic(
    QualifiedCharacteristic(
      serviceId: _gyroscopeService,
      characteristicId: _gyroscopeCharacteristic,
      deviceId: _device!.id,
    ),
  ).map((event) {
    _updateAcc(event);
    return _accZ;
  });

  Stream<bool> headShakeStream(double threshold) async*{
    while(true){
      int x = await accXStream.last;
      int y = await accYStream.last;
      int z = await accZStream.last;
      double pitch = atan2(y, sqrt(x*x + z*z)) * 180 / pi;
      double roll = atan2(x, sqrt(y*y + z*z)) * 180 / pi;
      if(pitch > threshold || roll > threshold) {
        yield true;
      }
    }
  }

  void connect() async {
    flutterReactiveBle.scanForDevices(withServices: [_gyroscopeService]).listen((scanResult) {
      print('Found device: ${scanResult.id}');
      if(!_isConnected){
        flutterReactiveBle.connectToAdvertisingDevice(id: scanResult.id,
            withServices: [_gyroscopeService],
            prescanDuration: const Duration(seconds: 1)).listen((connectionState) {
          print('Connection state: $connectionState');
          if(connectionState == DeviceConnectionState.connected){
            _isConnected = true;
            _device = scanResult;
            _confGyro();
            flutterReactiveBle.subscribeToCharacteristic(
                QualifiedCharacteristic(
                  serviceId: _gyroscopeService,
                  characteristicId: _gyroscopeCharacteristic,
                  deviceId: _device!.id,
                )
            ).listen((data) {
              _updateAcc(data);
            });
          }
        });
      }
    });
  }

  get isConnected => _isConnected;
  get accX => _accX;
  get accY => _accY;
  get accZ => _accZ;

}