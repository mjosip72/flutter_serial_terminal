
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:serial_terminal/port_controller.dart';

void main() {
  runMyApp();
}

const appTitle = 'Serial terminal';

class ThemeColors {
  static var background = const Color(0xFF1E1E1E);
  static var background2 = const Color(0xFF333333);
}

void runMyApp() {

  ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: ThemeColors.background2,
  );

  var myApp = GetMaterialApp(
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.dark,
    darkTheme: theme,
    home: const SerialTerminal(),
    title: appTitle,
  );

  runApp(myApp);

  doWhenWindowReady(() {
    appWindow.size = const Size(1280, 720);
    appWindow.alignment = Alignment.center;
    appWindow.show();
    appWindow.title = appTitle;
  });

}

var outputText = TextEditingController();
var inputText = TextEditingController();
var portController = Get.put(PortController());

class SerialTerminal extends StatelessWidget {

  const SerialTerminal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        buildTitleBar(),
        buildControls(),
        buildTextArea(),
      ]),
    );
  }

  Widget buildTextArea() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: ThemeColors.background,
        child: TextField(
          controller: inputText,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          readOnly: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true
          ),
        ),
      ),
    );
  }

  Widget buildControls() {

    var mainRowSpacing = const SizedBox(width: 12);
    portController.onSerialData((data) => inputText.text += data);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Row( children: [

        Expanded(
          child: TextField(
            controller: outputText,
            onEditingComplete: () => portController.writeData(outputText.text),
            decoration: const InputDecoration(
              hintText: 'Poruka',
              isDense: true,
            ),
          ),
        ),

        mainRowSpacing,

        ElevatedButton(onPressed: () => inputText.clear(), child: const Text('Clear')),

        mainRowSpacing,

        GetX<PortController>(builder: (con) {
          return DropdownButton(
            items: con.baudRateItems,
            value: con.baudRate.value,
            isDense: true,
            onChanged: (int? newValue) {
              if(newValue == null) return;
              con.selectBaudRate(newValue);
            }
          );
        }),
        
        mainRowSpacing,

        TextButton(
          onPressed: () {
            openDialog();
          },
          child: GetX<PortController>(builder: (con) {
            return Text(con.portName.value);
          })
        ),

        mainRowSpacing,

        GetX<PortController>(builder: (con) {
          return Switch(
            value: con.portOpen.value,
            activeColor: Colors.green,
            onChanged: (newValue) {
              con.openOrClose();
            });
        })

      ]),
    );
  }

  void openDialog() {

    portController.listComPorts();

    Get.dialog(AlertDialog(

      title: const Text('Select COM port'),
      
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: portController.comPortsList
      ),
      /*
      content: GetX<PortController>(builder: (con) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: con.comPortsList
        );
      }),
      */

      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        //TextButton(onPressed: () => portController.listComPorts(), child: const Text('Refresh')),
      ],

    ), transitionDuration: const Duration(milliseconds: 100))

    .then((value) {
      if(value is String) portController.selectPortName(value);
      else portController.selectPortName(null);
    });

  }

  Widget buildTitleBar() {

    WindowButtonColors windowButtonColors = WindowButtonColors(
      normal: const Color(0xFF333333),
      mouseOver: const Color(0xFF505050),
      mouseDown: const Color(0xFF505050),
      iconNormal: const Color(0xFFCCCCCC),
      iconMouseDown: const Color(0xFFCCCCCC),
      iconMouseOver: const Color(0xFFCCCCCC),
    );

    return WindowTitleBarBox(
      child: Container(
        color: ThemeColors.background2,
        child: Row(children: [
          Expanded(child: MoveWindow()),
          MinimizeWindowButton(colors: windowButtonColors),
          MaximizeWindowButton(colors: windowButtonColors),
          CloseWindowButton(colors: windowButtonColors)
        ]),
      ),
    );
  }

}
