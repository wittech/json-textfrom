import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json_schema_form/models/Action.dart';
import 'package:json_schema_form/models/Schema.dart';
import 'package:file_chooser/file_chooser.dart';
import 'package:permission_handler/permission_handler.dart';

class JSONTextFormField extends StatefulWidget {
  final Schema schema;
  final Function onSaved;
  final bool isOutlined;

  JSONTextFormField(
      {@required this.schema, this.onSaved, this.isOutlined = false, Key key})
      : super(key: key);

  @override
  _JSONTextFormFieldState createState() => _JSONTextFormFieldState();
}

class _JSONTextFormFieldState extends State<JSONTextFormField> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    String value = widget.schema.value ??
        widget.schema.extra?.defaultValue?.toString() ??
        "";
    _controller = TextEditingController(text: value);
  }

  String validation(String value) {
    switch (widget.schema.widget) {
      case WidgetType.number:
        final n = num.tryParse(value);
        if (n == null) {
          return '$value is not a valid number';
        }
        break;
      default:
        if ((value == null || value == "") && widget.schema.isRequired) {
          return "This field is required";
        }
    }
  }

  _suffixIconAction({File image, String inputValue}) async {
    switch (widget.schema.action.actionDone) {
      case ActionDone.getInput:
        if (inputValue != null) {
          setState(() {
            _controller.text = inputValue.toString();
          });
        } else if (image != null) {
          var value =
              await (widget.schema.action as FieldAction<File>).onDone(image);
          if (value is String) {
            setState(() {
              _controller.text = value;
            });
          }
        }
        break;

      case ActionDone.getImage:
        if (image != null) {
          await (widget.schema.action as FieldAction<File>).onDone(image);
        }
        break;
    }
  }

  Widget _renderSuffixIcon() {
    if (widget.schema.action != null) {
      switch (widget.schema.action.actionTypes) {
        case ActionTypes.image:
          return IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => Container(
                  child: Wrap(
                    children: <Widget>[
                      Platform.isAndroid || Platform.isIOS
                          ? ListTile(
                              leading: Icon(Icons.camera_alt),
                              title: Text("From Camera"),
                              onTap: () async {
                                File file = await ImagePicker.pickImage(
                                    source: ImageSource.camera);
                                await _suffixIconAction(image: file);
                              },
                            )
                          : null,
                      ListTile(
                        leading: Icon(Icons.filter),
                        title: Text("From Gallery"),
                        onTap: () async {
                          if (Platform.isIOS || Platform.isAndroid) {
                            File file = await ImagePicker.pickImage(
                                source: ImageSource.gallery);
                            await _suffixIconAction(image: file);
                          } else if (Platform.isMacOS) {
                            var result = await showOpenPanel();
                            if (!result.canceled) {
                              if (result.paths.length > 0) {
                                await _suffixIconAction(
                                    image: File(result.paths.first));
                              }
                            }
                          }
                        },
                      )
                    ],
                  ),
                ),
              );
            },
            icon: Icon(Icons.camera_alt),
          );

        case ActionTypes.qrScan:
          return IconButton(
            onPressed: () async {
              if (Platform.isAndroid || Platform.isIOS) {
                try {
                  String barcode = await BarcodeScanner.scan();
                  await _suffixIconAction(inputValue: barcode);
                } on PlatformException catch (e) {
                  if (e.code == BarcodeScanner.CameraAccessDenied) {
                  } else {}
                } on FormatException {} catch (e) {}
              } else if (Platform.isMacOS) {
                //TODO: Add macOS support
              }
            },
            icon: Icon(Icons.camera_alt),
          );
          break;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: TextFormField(
          onChanged: (value) {
            widget.onSaved(value);
          },
          key: Key("textfield"),
          // controller: _controller,
          controller: _controller,
          keyboardType: widget.schema.widget == WidgetType.number
              ? TextInputType.number
              : null,
          validator: this.validation,
          maxLength: widget.schema.validation?.length?.maximum,
          obscureText: widget.schema.name == "password",
          decoration: InputDecoration(
            helperText: widget.schema.extra?.helpText,
            labelText: widget.schema.label,
            prefixIcon: widget.schema.icon != null
                ? Icon(widget.schema.icon.iconData)
                : null,
            suffixIcon: _renderSuffixIcon(),
            border: widget.isOutlined == true
                ? OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(10.0),
                    ),
                  )
                : null,
          ),
          onSaved: this.widget.onSaved,
        ),
      ),
    );
  }
}
