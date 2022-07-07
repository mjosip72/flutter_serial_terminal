
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:serial_comm/serial_comm.dart';

class PortController extends GetxController {

  final String selectPortText = 'Select COM port';
  late final List<DropdownMenuItem<int>> baudRateItems;

  var comPortsList = <SerialPortInfo>[].obs;

  late RxInt baudRate;
  late RxString portName;

  var portOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    var baudRates = [9600, 115200, 256000, 512000, 1000000, 2000000];
    baudRate = baudRates[1].obs;

    baudRateItems = baudRates.map((int e) {
      return DropdownMenuItem(value: e, child: Text(e.toString()));
    }).toList();

    portName = selectPortText.obs;

    SerialPort.onPortClose(() => portOpen.value = false);

  }

  void onSerialData(void Function(String data) onData) => SerialPort.onData(onData);

  void openPort() {

    if(portName.value == selectPortText) {
      portOpen.value = false;
      return;
    }

    bool success = SerialPort.open(portName: portName.value, baudRate: baudRate.value);
    portOpen.value = success;

  }

  void closePort() {
    SerialPort.close();
    portOpen.value = false;
  }

  void openOrClose() {
    if(SerialPort.isOpen) closePort();
    else openPort();
  }

  void writeData(String data) => SerialPort.write(data);

  void selectBaudRate(int newValue) {
    baudRate.value = newValue;
    if(portOpen.value) {
      closePort();
      openPort();
    }
  }

  void selectPortName(String? newValue) {
    portName.value = newValue ?? selectPortText;
    if(portOpen.value) {
      closePort();
      openPort();
    }
  }

  void listComPorts() {
    comPortsList.clear();
    var ports = SerialPort.listPorts();
    comPortsList.addAll(ports);
  }

}
