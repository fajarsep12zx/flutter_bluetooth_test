import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class PeripheralPage extends StatefulWidget {
  const PeripheralPage({Key? key, required this.title}) : super(key: key);
  
  FlutterBlue get flutterBlue => FlutterBlue.instance;
  final String title;

  @override
  State<PeripheralPage> createState() => _PeripheralState();
}

class _PeripheralState extends State<PeripheralPage> {
  final _writeController = TextEditingController();
  final disableButton = true;

  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};
  final Map<dynamic, dynamic> _connectedDevice = {};
  late var _services = [];

  _addDeviceTolist(final BluetoothDevice device) {
    if (!devicesList.contains(device)) {
      setState(() {
        devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  _buildListViewOfDevices() {
    List<Container> containers = <Container>[];
    for (BluetoothDevice device in devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              // ignore: deprecated_member_use
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } catch (e) {
                    // ignore: avoid_print
                    print(e);
                  } finally {
                    _services = await device.discoverServices();
                  }
                  setState(() {
                    _connectedDevice["connectedDevices"] = device;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

   List<Chip> _buildReadWriteNotifyButton(
    BluetoothCharacteristic characteristic) {
    List<Chip> chips = <Chip>[];

    if (characteristic.properties.read) {
      chips.add(
        Chip(
          label: Text('Read'),
        ),
      );
    }
    if (characteristic.properties.write) {
      chips.add(
        Chip(
        label: Text('Write'),),
      );
    }
    if (characteristic.properties.notify) {
      chips.add(
        Chip(
           label: Text('Notify'),)
      );
    }

    return chips;
  }

_buildConnectDeviceView() {
    List<Container> containers = <Container>[];

    for (BluetoothService service in _services) {
      List<Widget> characteristicsWidget = <Widget>[];

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristicsWidget.add(
         Align(
           alignment: Alignment.centerLeft,
           child: Column(
             children: <Widget>[
               Row(
                 children: <Widget>[
                   Text(characteristic.uuid.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                 ],
               ),
               Row(
                 children: <Widget>[
                   ..._buildReadWriteNotifyButton(characteristic),
                 ],
               ),
               Divider(),
             ],
           ),
         ),
       );
      }

      containers.add(
       Container(
         child: ExpansionTile(
             title: Text(service.uuid.toString()),
             children: characteristicsWidget),
       ),
     );
    }

    return 
    ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  _disconnectDevice(id) async {
    final connectedDevice = devicesList.firstWhere(((element) => element.id.id == id));
    try {
      await connectedDevice.disconnect();
    } catch (e) {
      print(e);
    } finally {
       setState(() {
      _connectedDevice.remove('connectedDevices');
    });
    }
  }

  _buildView() {
    if (_connectedDevice.values.isNotEmpty) {
      return Column(children: <Widget>[
         
          Flexible(child: RaisedButton(child: const Text('Disconnect'), onPressed:() {
             final id = _connectedDevice.values.first.id.id;
            _disconnectDevice(id);
          },)),
           Flexible(child: Column(children: [
              Text(_connectedDevice.values.first.name),
              Text(_connectedDevice.values.first.id.id)
          ],)),
          Flexible(child: Text("Characteristics", style: TextStyle(fontWeight: FontWeight.bold),),),
          Expanded( flex:5, child: Container(padding: EdgeInsets.all(10), child: _buildConnectDeviceView(),))
        ],);
    }
    return Column(children: <Widget>[
          Expanded(child: _buildListViewOfDevices())
        ],);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildView(),
    );
  }
}
