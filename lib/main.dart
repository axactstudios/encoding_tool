import 'dart:io';
import 'dart:typed_data';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folder_picker/folder_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:permissions_plugin/permissions_plugin.dart';
import 'package:progress_dialog/progress_dialog.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'File Encoder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<StorageInfo> _storageInfo = [];
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    List<StorageInfo> storageInfo;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      storageInfo = await PathProviderEx.getStorageInfo();
    } on PlatformException {}

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _storageInfo = storageInfo;
      print('--------------------------${_storageInfo[1].rootDir}');
    });
  }

  String dest, decrypt;
  void folder() async {
    // Directory extDir = await getExternalStorageDirectory();
    new Directory('/storage/emulated/0/EncodedFiles')
        .create(recursive: true)
        .then((Directory dir) {
      print("My directory path ${dir.path}");
      dest = dir.path;
      setState(() {
        print('----------------${dir.path} is the destination---------------');
      });
    });
    new Directory('/storage/emulated/0/DecodedFiles')
        .create(recursive: true)
        .then((Directory dir) {
      print("My directory path ${dir.path}");
      decrypt = dir.path;
      setState(() {
        print('----------------${dir.path} is the destination---------------');
      });
    });
  }

  void request() async {
    Map<Permission, PermissionState> permission =
        await PermissionsPlugin.requestPermissions([
      Permission.WRITE_EXTERNAL_STORAGE,
      Permission.READ_EXTERNAL_STORAGE
    ]);
  }

  @override
  void initState() {
    // folder();
    request();
  }

  ProgressDialog pr;
  Uint8List nFile;

  void encode(BuildContext context, File file) async {
    // File file = await FilePicker.getFile();
    String fileName = basename(file.path);

    nFile = await file.readAsBytes();
    var len = nFile.length;
    Uint8List mainfile2 = new Uint8List(len);
    for (int i = 0; i < 5; i++) {
      setState(() {
        mainfile2[i] = nFile[4 - i];
      });
    }
    for (int i = 5; i < nFile.length; i++) {
      mainfile2[i] = nFile[i];
    }
    File savedFile = await saveMediaAsString(fileName, mainfile2);

    AlertDialog(
      title: Text('File is successfully Encoded'),
    );
  }

  List files = new List();

  String directory;
  Future<File> saveMediaAsString(String fileName, Uint8List fileContent) async {
    // String path = await _storageInfo[0].rootDir;
//    print('----------------------${_storageInfo[1].rootDir}');
    Directory dataDir = new Directory('/storage/emulated/0/EncodedFiles');
    if (await dataDir.exists()) {
      File file = new File('/storage/emulated/0/EncodedFiles/$fileName');
      return file.writeAsBytes(fileContent);
    }
    await dataDir.create();
    print('File created');
    File file = new File('/storage/emulated/0/EncodedFiles/$fileName');
    return file.writeAsBytes(fileContent);
  }

  void _listofFilesfromFolder(String folderPath) async {
    // directory = (await getApplicationDocumentsDirectory()).path;
    setState(() {
      files = io.Directory(folderPath)
          .listSync(); //use your folder name insted of resume.
      print(files.length);
      print(files);
    });

    print(files.runtimeType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: InkWell(
        onTap: () {
          Navigator.of(context).push<FolderPickerPage>(
              MaterialPageRoute(builder: (BuildContext context) {
            return FolderPickerPage(
                rootDirectory: Directory('/storage/emulated/0'),

                /// a [Directory] object
                action: (BuildContext context, Directory folder) async {
                  print("$folder");
                  // int i = folder.path.indexOf('0');
                  // print(i);
                  String subFolder;
                  // subFolder = folder.path.substring(i + 1);
                  // print(folder.path.substring(i + 1));
                  await Navigator.pop(context);
                  // print(dest);
                  await _listofFilesfromFolder(folder.path);
                  pr = ProgressDialog(
                    context,
                    type: ProgressDialogType.Normal,
                    textDirection: TextDirection.ltr,
                    isDismissible: false,
                  );
                  pr.style(
                    message: 'Encoding in progress...',
                    borderRadius: 10.0,
                    backgroundColor: Colors.white,
                    elevation: 10.0,
                    insetAnimCurve: Curves.easeInOut,
                    progress: 0.0,
                    progressWidgetAlignment: Alignment.center,
                    progressTextStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400),
                    messageTextStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 19.0,
                        fontWeight: FontWeight.w600),
                  );
                  await pr.show();
                  for (int i = 0; i < files.length; i++) {
                    await encode(context, files[i]);
                  }
                  await pr.hide();
                });
          }));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 300, horizontal: 100),
          child: Container(
            color: Colors.blue,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Encode Files',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}
