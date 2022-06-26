
import 'dart:ui';

import 'package:flutter/material.dart';

typedef _Disposer = void Function();

class _QWidgetBuilder extends StatefulWidget {

  final StatefulWidgetBuilder builder;
  final _Disposer? dispose;

  const _QWidgetBuilder({
    Key? key,
    required this.builder,
    this.dispose
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QWidgetBuilderState();

}

class _QWidgetBuilderState extends State<_QWidgetBuilder> {
  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
  @override
  void dispose() {
    super.dispose();
    if(widget.dispose != null) widget.dispose!();
  }
}

abstract class QWidget {

  StateSetter? _setState;

  Widget build();

  void _rebuild() {
    if(_setState != null) _setState!(() {});
  }

  Widget buildWidget() {
    return _QWidgetBuilder(builder: (BuildContext context, StateSetter setState) {
      _setState = setState;
      return build();
    }, dispose: dispose);
  }

  void dispose() {}

}

class QWidgetCompat extends QWidget {
  final Widget _widget;
  QWidgetCompat(Widget widget) : _widget = widget;
  Widget build() => _widget;
}

class QMaterialApp {

  late String _title;
  late bool _darkMode;
  late QWidget _content;

  late BuildContext context;

  QMaterialApp({String title = "", bool darkMode: false}) {
    _title = title;
    _darkMode = darkMode;
  }

  void setContent(QWidget content) {
    _content = content;
  }

  void show() {
    runApp(_QMaterialAppWidget(this));
  }

}

class _QMaterialAppWidget extends StatelessWidget {

  final QMaterialApp _app;
  const _QMaterialAppWidget(QMaterialApp app) : _app = app;

  Widget build(BuildContext context) {

    ThemeData themeData = ThemeData(
      brightness: _app._darkMode ? Brightness.dark : Brightness.light,
      primarySwatch: Colors.green
    );

    return MaterialApp(
      title: _app._title,
      theme: themeData,
      darkTheme: themeData,
      themeMode: _app._darkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: StatefulBuilder(builder: (context, setState) {
        _app.context = context;
        return Scaffold(body: _app._content.buildWidget());
      }),
    );
  }

}

enum QButtonType {
  Elevated, Outlined, Text
}

class QButton extends QWidget {

  late String _text;
  late QButtonType _type;
  Function? _onPressed;

  QButton({String text = "", QButtonType type = QButtonType.Elevated}) {
    _text = text;
    _type = type;
  }

  void setButtonType(QButtonType buttonType) {
    _type = buttonType;
    _rebuild();
  }

  void setText(String text) {
    _text = text;
    _rebuild();
  }

  void onPressed(Function onPressed) {
    _onPressed = onPressed;
  }

  Widget _buildElevatedButton() {
    return ElevatedButton(onPressed: () {
      if(_onPressed != null) _onPressed!();
    }, child: Text(_text));
  }

  Widget _buildOutlinedButton() {
    return OutlinedButton(onPressed: () {
      if(_onPressed != null) _onPressed!();
    }, child: Text(_text));
  }

  Widget _buildTextButton() {
    return TextButton(onPressed: () {
      if(_onPressed != null) _onPressed!();
    }, child: Text(_text));
  }

  Widget build() {
    switch(_type) {
      case QButtonType.Elevated: return _buildElevatedButton();
      case QButtonType.Outlined: return _buildOutlinedButton();
      case QButtonType.Text: return _buildTextButton();
    }


  }

}

class QContainer extends QWidget {

  final EdgeInsetsGeometry? _margin;
  final EdgeInsetsGeometry? _padding;
  final Color? _color;
  final bool _expanded;

  QWidget? _content;

  QContainer({
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
    QWidget? content,
    bool expanded = false,
  }) : 
    _margin = margin,
    _padding = padding,
    _color = color,
    _content = content,
    _expanded = expanded;

  void setContent(QWidget content) {
    _content = content;
    _rebuild();
  }

  Widget build() {

    Widget w = Container(
      margin: _margin,
      padding: _padding,
      color: _color,
      child: _content!.buildWidget(),
    );

    if(_expanded) w = Expanded(child: w);
    return w;

  }

}

class _QFlex extends QWidget {

  final List<Widget> _children = [];

  final Axis _direction;
  final EdgeInsetsGeometry? _margin;
  final EdgeInsetsGeometry? _padding;
  final Color? _color;
  final double _spacing;

  _QFlex({
    required Axis direction,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
    double spacing = 0,
  }) : 
    _direction = direction,
    _margin = margin,
    _padding = padding,
    _color = color,
    _spacing = spacing;

  SizedBox _createSpacing() {
    return _direction == Axis.horizontal ? 
      SizedBox(width: _spacing) : SizedBox(height: _spacing);
  }

  void add(QWidget widget) {
    if(_children.isNotEmpty) _children.add(_createSpacing());
    _children.add(widget.buildWidget());
    _rebuild();
  }

  void addAll(List<QWidget> widgets) {
    widgets.forEach((QWidget widget) {
      if(_children.isNotEmpty) _children.add(_createSpacing());
      _children.add(widget.buildWidget());
    });
    _rebuild();
  }

  void clear() {
    _children.clear();
    _rebuild();
  }

  Widget build() {
    return Container(
      margin: _margin,
      padding: _padding,
      color: _color,
      child: Flex(
        direction: _direction,
        children: _children
      ),
    );
  }

}

class QColumn extends _QFlex {
  QColumn({
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
    double spacing = 0,
  }) : super(
    direction: Axis.vertical,
    margin: margin,
    padding: padding,
    color: color,
    spacing: spacing
  );

}

class QRow extends _QFlex {
  QRow({
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
    double spacing = 0,
  }) : super(
    direction: Axis.horizontal,
    margin: margin,
    padding: padding,
    color: color,
    spacing: spacing
  );
}

class QComboBox<T> extends QWidget {

  final List<T> _items = [];
  late T _value;
  
  Function? _onRequest;

  void setItems(List<T> items, [int current = 0]) {
    if(current == -1) current = items.length - 1;
    _items.clear();
    _items.addAll(items);
    _value = _items[current];
    _rebuild();
  }

  T value() {
    return _value;
  }

  void onRequest(Function onRequest) {
    _onRequest = onRequest;
  }

  Widget build() {
    return DropdownButton<T>(
      value: _value,
      items: _generateItems(),
      isDense: true,
      onTap: () {
        if(_onRequest != null) _onRequest!();
      },
      onChanged: (T? s) {
        if(s == null) return;
        _value = s;
        _rebuild();
      }
    );
  }

  List<DropdownMenuItem<T>> _generateItems() {
    return _items.map((T e) => DropdownMenuItem(
      value: e,
      child: Text(e.toString()),
    )).toList();
  }

}

class QSwitch extends QWidget {

  bool _value = false;

  void Function(bool)? _onChanged;
  bool Function(bool, bool)? _onChange;

  void setValue(bool value) {
    _value = value;
    _rebuild();
  }

  bool value() => _value;

  void onChanged(void Function(bool) onChanged) {
    _onChanged = onChanged;
  }

  void onChange(bool Function(bool, bool) onChange) {
    _onChange = onChange;
  }

  Widget build() {
    return Switch(
      value: _value,
      activeColor: Colors.green,
      onChanged: (bool newValue) {

        if(_onChange != null) {
          newValue = _onChange!(_value, newValue);
          if(newValue == _value) return;
        }

        _value = newValue;
        _rebuild();
        if(_onChanged != null) _onChanged!(_value);
      }
    );
  }

}

class QTextField extends QWidget {
  
  final TextEditingController _controller = TextEditingController();
  InputDecoration? _inputDecoration;
  late bool _readOnly;
  double? _width;
  Function? _onEditingComplete;

  QTextField({InputDecoration? decoration, String? hintText, InputBorder? inputBorder, bool readOnly = false}) {
    
    _readOnly = readOnly;

    if(decoration != null) {
      _inputDecoration = decoration;
      return;
    }

    _inputDecoration = InputDecoration(
      hintText: hintText,
      isDense: true,
      border: inputBorder
    );

  }

  void onEditingComplete(Function onEditingComplete) {
    _onEditingComplete = onEditingComplete;
  }

  void setWidth(double? width) {
    _width = width;
    _rebuild();
  }

  void setText(String text) {
    _controller.text = text;
  }

  void appendText(String text) {
    _controller.text += text;
  }

  void clear() {
    _controller.clear();
  }

  String text() {
    return _controller.text;
  }

  Widget build() {
    return SizedBox(
      width: _width,
      child: TextField(
        controller: _controller,
        decoration: _inputDecoration,
        readOnly: _readOnly,
        onEditingComplete: () {
          if(_onEditingComplete != null) _onEditingComplete!();
        },
      )
    );
  }

  void dispose() {
    _controller.dispose();
  }

}

class QTextArea extends QTextField {

  QTextArea({InputDecoration? decoration, String? hintText, InputBorder? inputBorder, bool readOnly = false}) :
    super(decoration: decoration, hintText: hintText, inputBorder: inputBorder, readOnly: readOnly);

  Widget build() {
    return SizedBox(
      width: _width,
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        decoration: _inputDecoration,
        readOnly: _readOnly,
      ),
    );
  }

}
