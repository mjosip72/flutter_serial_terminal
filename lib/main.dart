
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:serial_comm/serial_comm.dart';
import 'qwidgets.dart';

String? serialPortName;

void main() {

  app();

  doWhenWindowReady(() {
    appWindow.size = const Size(1280, 720);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });

}

void app() {

  QMaterialApp app = QMaterialApp(title: "Serial terminal", darkMode: true);

  QColumn mainColumn = QColumn();

  WindowButtonColors windowButtonColors = WindowButtonColors(
    normal: const Color(0xFF333333),
    mouseOver: const Color(0xFF505050),
    mouseDown: const Color(0xFF505050),
    iconNormal: const Color(0xFFCCCCCC),
    iconMouseDown: const Color(0xFFCCCCCC),
    iconMouseOver: const Color(0xFFCCCCCC),
  );
  QWidgetCompat win = QWidgetCompat(
    WindowTitleBarBox(
      child: Container(
        color: const Color(0xFF333333),
        child: Row(
          children: [
            Expanded(child: MoveWindow()),
            MinimizeWindowButton(colors: windowButtonColors),
            MaximizeWindowButton(colors: windowButtonColors),
            CloseWindowButton(colors: windowButtonColors)
          ],
        )
      )
    )
  );
  mainColumn.add(win);

  QRow mainRow = QRow(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    color: const Color(0xFF333333),
    spacing: 12
  );

  QTextField outputText = QTextField(hintText: "Poruka");

  QButton clearButton = QButton(text: "Očisti", type: QButtonType.Elevated);

  QComboBox<int> baudRateCombo = QComboBox();
  baudRateCombo.setItems([9600, 115200, 256000, 1000000], 1);

  QButton portButton = QButton(text: "Odabir", type: QButtonType.Text);
  portButton.onPressed(() {
    showPortsDialog(app.context, portButton);
  });

  QSwitch portOpenSwitch = QSwitch();
  portOpenSwitch.onChange((bool oldValue, bool newValue) {

    if(SerialPort.isOpen) {
      SerialPort.close();
      return false;
    }else{
      if(serialPortName == null) return false;
      int baudRate = baudRateCombo.value();
      bool ok = SerialPort.open(portName: serialPortName!, baudRate: baudRate);
      return ok;
    }

  });

  mainRow.addAll([QContainer(expanded: true, content: outputText), clearButton, baudRateCombo, portButton, portOpenSwitch]);
  mainColumn.add(mainRow);

  QTextArea inputText = QTextArea(inputBorder: InputBorder.none, readOnly: true);
  
  SerialPort.onData((String data) {
    inputText.appendText(data);
  });

  SerialPort.onPortClose(() { 
    portOpenSwitch.setValue(false);
  });
  
  mainColumn.add(QContainer(
    color: const Color(0xFF1E1E1E),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    expanded: true,
    content: inputText
  ));

  clearButton.onPressed(() {
    inputText.clear();
  });

  outputText.onEditingComplete(() {
    if(SerialPort.isOpen) SerialPort.write("${outputText.text()}\n");
    outputText.clear();
  });

  app.setContent(mainColumn);
  app.show();

}

void refreshPorts(BuildContext context, QColumn buttons) {
  buttons.clear();
  SerialPort.listPorts().forEach((SerialPortInfo serialPort) {
    QButton button = QButton(text: serialPort.description, type: QButtonType.Text);
    button.onPressed(() {
      Navigator.pop(context, serialPort.name);
    });
    buttons.add(button);
  });
}

void showPortsDialog(BuildContext context, QButton button) {

  QColumn buttons = QColumn(spacing: 4);
  showDialog(context: context, builder: (BuildContext context) {
    refreshPorts(context, buttons);
    return AlertDialog(
      title: const Text("Odaberite priključak"),
      content: FittedBox(child: buttons.buildWidget()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Odustani")),
        TextButton(onPressed: () => refreshPorts(context, buttons), child: const Text("Osvježi"))
      ],
    );
  }).then((value) {
    if(value != null) {
      serialPortName = value.toString();
      button.setText(value.toString());
    }else{
      button.setText("Odabir");
      serialPortName = null;
    }
  });

}
