import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_form/components/JSONForignKeyEditField.dart';
import 'package:json_schema_form/components/SelectionPage.dart';
import 'package:json_schema_form/models/Schema.dart';
import 'package:json_schema_form/utils.dart';

class JSONForignKeyField extends StatelessWidget {
  final Schema schema;
  final Function onSaved;
  final bool showIcon;
  final bool isOutlined;
  final String url;

  JSONForignKeyField(
      {@required this.schema,
      this.onSaved,
      this.showIcon = true,
      this.isOutlined = false,
      @required this.url});

  Future<List<Choice>> _getSelections(String path) async {
    String p = "$path/".replaceFirst("-", "_");
    String url = getURL(this.url, p);
    Response response = await Dio().get<List<dynamic>>(url);
    return (response.data as List)
        .map((d) => Choice(label: d['name'].toString(), value: d['id']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Container(
              decoration: isOutlined
                  ? BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context)
                                  .inputDecorationTheme
                                  ?.border
                                  ?.borderSide
                                  ?.color ??
                              Colors.black),
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).inputDecorationTheme.fillColor ??
                          null)
                  : null,
              child: ListTile(
                trailing: Icon(
                  Icons.expand_more,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text("Select ${schema.label}"),
                subtitle: Text("${schema.choice?.label}"),
                onTap: () async {
                  List<Choice> choices =
                      await _getSelections(schema.extra.relatedModel);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) {
                        return SelectionPage(
                          onSelected: (value) {
                            if (this.onSaved != null) {
                              this.onSaved(value);
                            }
                          },
                          title: "Select ${schema.label}",
                          selections: choices,
                          value: schema.value,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: RawMaterialButton(
              elevation: 0,
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
              fillColor: Colors.blue,
              shape: new CircleBorder(),
              onPressed: () async {
                /// Add new field
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) {
                    return JSONForignKeyEditField(
                      baseURL: this.url,
                      isOutlined: isOutlined,
                      title: "Add ${schema.label}",
                      path: schema.extra.relatedModel,
                      isEdit: false,
                    );
                  }),
                );
              },
            ),
          ),
          Expanded(
            child: RawMaterialButton(
              elevation: 0,
              child: Icon(
                Icons.edit,
                color: Colors.white,
              ),
              fillColor: schema.choice == null ? Colors.grey : Colors.blue,
              shape: new CircleBorder(),
              onPressed: schema.choice == null
                  ? null
                  : () async {
                      /// Edit current field
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) {
                          return JSONForignKeyEditField(
                            baseURL: this.url,
                            isOutlined: isOutlined,
                            title: "Edit ${schema.label}",
                            path: schema.extra.relatedModel,
                            isEdit: true,
                            id: schema.choice.value,
                          );
                        }),
                      );
                    },
            ),
          ),
          // Expanded(
          //   child: RawMaterialButton(
          //     elevation: 0,
          //     child: Icon(
          //       Icons.remove,
          //       color: Colors.white,
          //     ),
          //     fillColor: Colors.blue,
          //     shape: new CircleBorder(),
          //     onPressed: () {},
          //   ),
          // )
        ],
      ),
    );
  }
}
