import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mboathoscope/controller/appDirectorySingleton.dart';
import 'package:mboathoscope/controller/helpers.dart';
import 'package:mboathoscope/models/records.dart';
import 'package:mboathoscope/views/widgets/waveform.dart';
import 'package:provider/provider.dart';

List<Recordings> listOfRecordings = [];
List<Recordings> getRecordings() {
  return listOfRecordings;
}


class dbRecordingList extends StatefulWidget {
  const dbRecordingList({Key? key}) : super(key: key);

  @override
  State<dbRecordingList> createState() => _dbRecordingListState();
}

class _dbRecordingListState extends State<dbRecordingList> {
  @override
  void initState() {
    super.initState();
    getRecordings();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<AppDirectorySingleton>(

        builder: (BuildContext context, value, Widget? child) {

          listOfRecordings.clear();

          value.heartbeatAndPathMap.forEach((key, value) {

            Recordings rec1 = Recordings(
              id: key,
              pathname: key,
              filename: helpers().getFileBaseName(File(key)),
              dateTime: DateTime.now(),
              playerController: value,
              audio: File(key),
            );
            listOfRecordings.add(rec1);
            // listOfRecordings.add(rec1);
          });

          return Container(
            child: listOfRecordings.isEmpty
                ? const SizedBox(
              height: 50,
              child: Center(
                child: Text('No recordings yet'),
              ),
            )
                : SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width* 0.9,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: listOfRecordings.length,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    //final item = items[index];
                    return ListTile(
                      title: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 20,
                            child: WaveformButton(
                              playerController:listOfRecordings[index].playerController!,
                              fileName:listOfRecordings[index].filename,
                              path: listOfRecordings[index].pathname,
                            ),
                          ),
                        ],
                      ),
                      // subtitle: Text(listOfRecordings[index].filename),
                    );
                  },
                ),
              ),
            ),
          );
        },
    );
  }
}

/// The base class for the different types of items the list can contain.
abstract class ListItem {
  /// The title line to show in a list item.
  Widget buildTitle(BuildContext context);

  /// The subtitle line, if any, to show in a list item.
  Widget buildSubtitle(BuildContext context);
}

/// A ListItem that contains data to display a heading.
class HeadingItem implements ListItem {
  final String heading;

  HeadingItem(this.heading);

  @override
  Widget buildTitle(BuildContext context) {
    return Text(
      heading,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  @override
  Widget buildSubtitle(BuildContext context) => const SizedBox.shrink();
}

/// A ListItem that contains data to display a message.
class MessageItem implements ListItem {
  final String sender;
  final String body;

  MessageItem(this.sender, this.body);

  @override
  Widget buildTitle(BuildContext context) => Text(sender);

  @override
  Widget buildSubtitle(BuildContext context) => Text(body);
}
