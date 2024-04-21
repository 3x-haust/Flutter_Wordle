import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Wordle Clone'),
        ),
        body: WordleWidget(),
      ),
    );
  }
}

class WordleWidget extends StatefulWidget {
  @override
  _WordleWidgetState createState() => _WordleWidgetState();
}

class _WordleWidgetState extends State<WordleWidget> {
  String answer = ""; // 정답 단어 // TODO 랜덤 만들기
  List<String> words = []; // 실제 단어
  List<List<TextEditingController>> _controllers = [];
  List<List<FocusNode>> _focusNodes = [];
  List<List<Color>> _backgroundColor = []; // 배경색 리스트
  int _currentEditingRowIndex = 0; // 현재 편집 중인 행 인덱스
  int _currentEditingColumnIndex = 0; // 현재 편집 중인 열 인덱스
  bool _isDialogShowing = false; // 다이얼로그 표시 여부

  Future<List<String>> loadWords() async {
    final String data = await rootBundle.loadString('assets/words.txt');  // 경로 수정
    words = data.split('\n');
    Random random = Random();

    answer = words[random.nextInt(words.length)];

    return words;
  }

  

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    loadWords();
    _controllers.clear();
    _focusNodes.clear();
    _backgroundColor.clear();
    _currentEditingRowIndex = 0;
    _currentEditingColumnIndex = 0;

    
    for (int i = 0; i < 6; i++) {
      List<TextEditingController> rowControllers = [];
      List<FocusNode> rowFocusNodes = [];
      List<Color> rowBackgroundColors = List.filled(5, Colors.transparent);
      for (int j = 0; j < 5; j++) {
        rowControllers.add(TextEditingController());
        rowFocusNodes.add(FocusNode());
      }
      _controllers.add(rowControllers);
      _focusNodes.add(rowFocusNodes);
      _backgroundColor.add(rowBackgroundColors);
    }
    setState(() {});
  }

  void _resetColumn() {
    
    // 현재 행의 모든 TextEditingController와 FocusNode를 새롭게 초기화합니다.
    List<TextEditingController> newRowControllers = [];
    List<FocusNode> newRowFocusNodes = [];
    List<Color> newRowBackgroundColors = List.filled(5, Colors.transparent); // 5칸 모두 투명색으로 초기화
    
    for (int j = 0; j < 5; j++) { // 5칸에 대해 반복
      newRowControllers.add(TextEditingController());
      newRowFocusNodes.add(FocusNode());
    }

    // 현재 행에 대한 정보를 업데이트합니다.
    _controllers[_currentEditingRowIndex] = newRowControllers;
    _focusNodes[_currentEditingRowIndex] = newRowFocusNodes;
    _backgroundColor[_currentEditingRowIndex] = newRowBackgroundColors;

    // 상태 변경을 알리기 위해 setState를 호출합니다.
    _currentEditingColumnIndex = 0;
    setState(() {});
}




  void _checkWord() {
    // 사용자가 현재 편집 중인 행의 모든 컨트롤러에서 글자를 가져와 하나의 단어로 합칩니다.
    String userInput = _controllers[_currentEditingRowIndex].map((controller) => controller.text).join('').toLowerCase();

    // 단어 길이가 5일 때만 확인 로직을 수행합니다.
    if (userInput.length == 5) {
      for (int i = 0; i < 5; i++) {
        // 정확한 위치에 있는 경우
        if (userInput[i] == answer[i]) {
          _backgroundColor[_currentEditingRowIndex][i] = Colors.green; // 정확한 위치
        // 단어에는 있지만 다른 위치에 있는 경우
        } else if (answer.contains(userInput[i])) {
          _backgroundColor[_currentEditingRowIndex][i] = Colors.yellow; // 다른 위치에 존재
        // 존재하지 않는 경우
        } else {
          _backgroundColor[_currentEditingRowIndex][i] = Colors.grey; // 존재하지 않음
        }
      }

      if (userInput == answer || _currentEditingRowIndex >= 5) {
        if (!_isDialogShowing) {
          _isDialogShowing = true;
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(userInput == answer ? "성공!" : "실패!"),
                content: Text("정답은 ${answer.toUpperCase()}입니다. \n다시 시작하시겠습니까?"),
                actions: <Widget>[
                  TextButton(
                    child: Text("확인"),
                    onPressed: () {
                      Navigator.of(context).pop(); // 팝업 닫기
                      _isDialogShowing = false; // 다이얼로그 표시 여부를 false로 설정
                      _resetGame(); // 게임 재시작
                    },
                  ),
                ],
              );
            },
          );
        }else {
          Navigator.of(context).pop();
          _isDialogShowing = false;
          _resetGame();
        }
      } else {
        if (_currentEditingRowIndex < 5) {
          _currentEditingRowIndex++;
          _currentEditingColumnIndex = 0;
        }
      }

      // 상태를 업데이트하여 UI를 갱신합니다.
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent && event.character != null) {
          final String? character = event.character;
          String userInput = _controllers[_currentEditingRowIndex].map((controller) => controller.text).join('').toLowerCase();

          if (event.logicalKey == LogicalKeyboardKey.enter) { 
            if(userInput.length != 5){
              if (!_isDialogShowing) {
                _isDialogShowing = true;
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("너무 짧음"),
                      actions: <Widget>[
                        TextButton(
                          child: Text("확인"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _isDialogShowing = false;
                            _resetColumn();
                          },
                        ),
                      ],
                    );
                  },
                );
              }else{
                Navigator.of(context).pop();
                _isDialogShowing = false;
                _resetColumn();
              }
            }else {
              if(!words.contains(userInput)) {
                if (!_isDialogShowing) {
                  _isDialogShowing = true;
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("없는 단어"),
                        actions: <Widget>[
                          TextButton(
                            child: Text("확인"),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _isDialogShowing = false;
                              _resetColumn();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }else{
                  Navigator.of(context).pop();
                  _isDialogShowing = false;
                  _resetColumn();
                }
              }else _checkWord();
            }
          } else if (event.logicalKey == LogicalKeyboardKey.backspace && _currentEditingColumnIndex > 0) {
            setState(() {
              _currentEditingColumnIndex--;
              _controllers[_currentEditingRowIndex][_currentEditingColumnIndex].clear();
              _backgroundColor[_currentEditingRowIndex][_currentEditingColumnIndex] = Colors.transparent;
            });
          } else if (_currentEditingColumnIndex < 5 && character!.isNotEmpty) {
            final isEnglishLetter = RegExp(r'^[a-zA-Z]$').hasMatch(character);

            // 입력된 문자가 영어 알파벳인 경우에만 처리
            if(isEnglishLetter) {
              setState(() {
                _controllers[_currentEditingRowIndex][_currentEditingColumnIndex].text = character;
                if (_currentEditingColumnIndex < 4) { // 마지막 칸에 문자를 입력한 후 인덱스 증가를 막습니다.
                  _currentEditingColumnIndex++;
                }
              });
            }
          }
        }
      },

      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode()); // 키보드 포커스 해제
        },
        child: Center(
          child: Column(
            children: List.generate(6, (rowIndex) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (columnIndex) {
                  return Container(
                    margin: EdgeInsets.all(4),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _backgroundColor[rowIndex][columnIndex],
                      border: Border.all(color: Colors.black),
                    ),
                    child: Center(
                      child: Text(
                        _controllers[rowIndex][columnIndex].text.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}
