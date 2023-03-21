import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_widget/flutter_openim_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tencent_keyboard_visibility/tencent_keyboard_visibility.dart';

double kVoiceRecordBarHeight = 40.h;

class ChatInputBoxView extends StatefulWidget {
  ChatInputBoxView({
    Key? key,
    required this.toolbox,
    required this.multiOpToolbox,
    required this.voiceRecordBar,
    required this.emojiView,
    this.allAtMap = const <String, String>{},
    this.atCallback,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.style,
    this.atStyle,
    this.forceCloseToolboxSub,
    this.quoteContent,
    this.onClearQuote,
    this.multiMode = false,
    this.inputFormatters,
    this.showEmojiButton = true,
    this.showToolsButton = true,
    this.isGroupMuted = false,
    this.muteEndTime = 0,
    this.background,
    this.iconColor,
    this.disabledColor = const Color(0xFFbdbdbd),
    this.isInBlacklist = false,
    this.speakIcon,
    this.emojiIcon,
    this.keyboardIcon,
    this.toolsIcon,
    this.buttonColor,
    this.buttonTextStyle,
    this.buttonRadius,
    this.enabledEmojiButton = true,
    this.enabledToolboxButton = true,
    this.enabledVoiceButton = false,
  }) : super(key: key);

  final AtTextCallback? atCallback;
  final Map<String, String> allAtMap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final Widget toolbox;
  final Widget multiOpToolbox;
  final Widget emojiView;
  final ChatVoiceRecordBar voiceRecordBar;
  final TextStyle? style;
  final TextStyle? atStyle;
  final Subject? forceCloseToolboxSub;
  final String? quoteContent;
  final Function()? onClearQuote;
  final bool multiMode;
  final List<TextInputFormatter>? inputFormatters;
  final bool showEmojiButton;
  final bool showToolsButton;
  final bool isGroupMuted;
  final int muteEndTime;
  final bool isInBlacklist;
  final Color? background;
  final Color? iconColor;
  final Color? disabledColor;
  final Color? buttonColor;
  final TextStyle? buttonTextStyle;
  final double? buttonRadius;
  final Widget? speakIcon;
  final Widget? keyboardIcon;
  final Widget? toolsIcon;
  final Widget? emojiIcon;
  final bool enabledVoiceButton;
  final bool enabledEmojiButton;
  final bool enabledToolboxButton;

  @override
  ChatInputBoxViewState createState() => ChatInputBoxViewState();
}

class ChatInputBoxViewState extends State<ChatInputBoxView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  var _keyboardVisible = false;
  var _toolsVisible = false;
  var _emojiVisible = false;
  var _leftKeyboardButton = false;
  var _rightKeyboardButton = false;
  double _keyboardHeight = 0;
  double bottomPadding = 0;

  late AnimationController animationCtl;
  List<Animation<double>> animations = [];
  @override
  void initState() {
    initAnimation();

    widget.focusNode?.addListener(() {
      if (widget.focusNode!.hasFocus) {
        setState(() {
          _toolsVisible = false;
          _emojiVisible = false;
          _leftKeyboardButton = false;
          _rightKeyboardButton = false;
        });
      }
    });

    widget.forceCloseToolboxSub?.listen((value) {
      if (!mounted) return;
      setState(() {
        _toolsVisible = false;
        _emojiVisible = false;
      });
    });
    super.initState();
  }

  void initAnimation() {
    animationCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    animations = [
      Tween<double>(begin: 0, end: 346).animate(
          CurvedAnimation(curve: Curves.easeInOutSine, parent: animationCtl))
    ];
  }

  keyboardDown() {
    if (widget.focusNode != null && widget.focusNode!.hasFocus) {
      widget.focusNode?.unfocus();
      animationCtl.reverse();
    }
  }

  double _getBottomHeight() {
    if (_keyboardVisible) {
      final currentKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;

      if (currentKeyboardHeight != 0) {
        if (currentKeyboardHeight >= _keyboardHeight) {
          _keyboardHeight = currentKeyboardHeight;
        }
      }
      final height =
          _keyboardHeight != 0 ? _keyboardHeight : currentKeyboardHeight;
      return height;
    } else if (_toolsVisible) {
      return 360 + (bottomPadding);
    } else if (_emojiVisible) {
      return 360 + (bottomPadding);
    } else if (widget.controller!.text.length >= 46 &&
        _keyboardVisible == false) {
      return 25 + (bottomPadding);
    } else {
      return bottomPadding;
    }
  }

  hideAllPanel() {
    unfocus();
    if (_keyboardVisible != false ||
        _toolsVisible != false ||
        _emojiVisible != false) {
      setState(() {
        _keyboardVisible = false;
        _toolsVisible = false;
        _emojiVisible = false;
      });
    }
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    widget.focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    EdgeInsets padding = data.padding;
    if (bottomPadding == 0 || padding.bottom > bottomPadding) {
      bottomPadding = padding.bottom;
    }

    return widget.multiMode
        ? widget.multiOpToolbox
        : _buildMsgInputField(context: context);
  }

  focus() => FocusScope.of(context).requestFocus(widget.focusNode);

  unfocus() => FocusScope.of(context).requestFocus(FocusNode());

  EdgeInsetsGeometry get emojiButtonPadding {
    if (widget.showToolsButton) {
      return EdgeInsets.only(left: 10.w, right: 5.w);
    } else {
      return EdgeInsets.only(left: 10.w, right: 10.w);
    }
  }

  EdgeInsetsGeometry get toolsButtonPadding {
    if (widget.showEmojiButton) {
      return EdgeInsets.only(left: 5.w, right: 10.w);
    } else {
      return EdgeInsets.only(left: 10.w, right: 10.w);
    }
  }

  SizedBox get spaceView => SizedBox(
      width: widget.showEmojiButton || widget.showToolsButton ? 0 : 10.w);

  Widget _buildMsgInputField({required BuildContext context}) => Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            //height: 64.h,
            decoration: BoxDecoration(
              color: widget.background ?? Color(0xfff9f9f9),
              border:
                  Border(top: BorderSide(width: 0.5, color: Color(0xffe5e5e5))),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _leftKeyboardButton ? _keyboardLeftBtn() : _speakBtn(),
                    Flexible(
                      child: Stack(
                        children: [
                          Offstage(
                            child: Column(
                              children: [
                                KeyboardVisibility(
                                    child: _buildTextFiled(),
                                    onChanged: (bool visibility) {
                                      if (_keyboardVisible != visibility) {
                                        setState(() {
                                          _keyboardVisible = visibility;
                                        });
                                      }
                                    }),
                                if (widget.quoteContent != null &&
                                    "" != widget.quoteContent)
                                  _quoteView(),
                              ],
                            ),
                            offstage: _leftKeyboardButton,
                          ),
                          Offstage(
                            child: widget.voiceRecordBar,
                            offstage: !_leftKeyboardButton,
                          ),
                          // _keyboardInput ? _buildTextFiled() : _buildSpeakBar()
                        ],
                      ),
                    ),
                    if (widget.showEmojiButton)
                      _rightKeyboardButton ? _keyboardRightBtn() : _emojiBtn(),
                    if (widget.showToolsButton) _toolsBtn(),
                    spaceView,
                    /*
                    Visibility(
                      visible: !_leftKeyboardButton || !_rightKeyboardButton,
                      child: Container(
                        width: 60.0.w * (1.0 - _animation.value),
                        child: _buildSendButton(),
                      ),
                    ),*/
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(
                milliseconds:
                    (_keyboardVisible && Platform.isAndroid) ? 200 : 340),
            curve: Curves.fastOutSlowIn,
            child: Builder(builder: (context) {
              if (_emojiVisible) {
                return widget.emojiView;
              } else if (_toolsVisible) {
                return widget.toolbox;
              } else {
                return Container(
                  height: max(_getBottomHeight(), 0.0),
                  color: Color(0xfff8f8f8),
                );
              }
            }),
          ),
        ],
      );

  Widget _quoteView() => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onClearQuote,
        child: Container(
          margin: EdgeInsets.only(top: 4.h),
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.quoteContent!,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12.sp,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ImageUtil.delQuote(),
            ],
          ),
        ),
      );

  Widget _buildTextFiled() => Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(minHeight: kVoiceRecordBarHeight),
        decoration: BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            ChatTextField(
              style: widget.style ?? textStyle,
              atStyle: widget.atStyle ?? atStyle,
              atCallback: widget.atCallback,
              allAtMap: widget.allAtMap,
              focusNode: widget.focusNode,
              controller: widget.controller,
              enabled: !_isMuted,
              inputFormatters: widget.inputFormatters,
              onSubmitted: (value) {
                //禁止键盘收起. 不再需要
                //if (!_emojiVisible) focus();

                if (null != widget.onSubmitted && null != widget.controller) {
                  widget.onSubmitted!(widget.controller!.text.toString());
                }
              },
              onTap: () {
                animationCtl.forward();
              },
            ),
            Visibility(
              visible: _isMuted,
              child: Container(
                alignment: Alignment.center,
                constraints: BoxConstraints(minHeight: 40.h),
                child: Text(
                  widget.isInBlacklist
                      ? UILocalizations.inBlacklist
                      : (widget.isGroupMuted
                          ? UILocalizations.groupMuted
                          : UILocalizations.youMuted),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  static var textStyle = TextStyle(
    fontSize: 14.sp,
    color: Color(0xFF333333),
    textBaseline: TextBaseline.alphabetic,
  );

  static var atStyle = TextStyle(
    fontSize: 14.sp,
    color: Colors.blue,
    textBaseline: TextBaseline.alphabetic,
  );

  bool get _isMuted =>
      widget.isGroupMuted || _isUserMuted || widget.isInBlacklist;

  bool get _isUserMuted =>
      widget.muteEndTime * 1000 > DateTime.now().millisecondsSinceEpoch;

  Color? get _color => _isMuted ? widget.disabledColor : widget.iconColor;

  Widget _speakBtn() => _buildBtn(
        icon: widget.speakIcon ??
            ImageUtil.speak(
              color: widget.enabledVoiceButton ? _color : widget.disabledColor,
            ),
        onTap: _isMuted || !widget.enabledVoiceButton
            ? null
            : () {
                setState(() {
                  _leftKeyboardButton = true;
                  _rightKeyboardButton = false;
                  _toolsVisible = false;
                  _emojiVisible = false;
                  unfocus();
                });
              },
      );

  Widget _keyboardLeftBtn() => _buildBtn(
        icon: widget.keyboardIcon ?? ImageUtil.keyboard(color: _color),
        onTap: _isMuted
            ? null
            : () {
                setState(() {
                  _leftKeyboardButton = false;
                  _toolsVisible = false;
                  _emojiVisible = false;
                  focus();
                });
              },
      );

  Widget _keyboardRightBtn() => _buildBtn(
        padding: emojiButtonPadding,
        icon: widget.keyboardIcon ?? ImageUtil.keyboard(color: _color),
        onTap: _isMuted
            ? null
            : () {
                setState(() {
                  _rightKeyboardButton = false;
                  _toolsVisible = false;
                  _emojiVisible = false;
                  focus();
                });
              },
      );

  Widget _toolsBtn() => _buildBtn(
        icon: widget.toolsIcon ??
            ImageUtil.tools(
              color:
                  widget.enabledToolboxButton ? _color : widget.disabledColor,
            ),
        padding: toolsButtonPadding,
        onTap: _isMuted || !widget.enabledToolboxButton
            ? null
            : () {
                setState(() {
                  _keyboardVisible = false;
                  _toolsVisible = !_toolsVisible;
                  _emojiVisible = false;
                  _leftKeyboardButton = false;
                  _rightKeyboardButton = false;
                  if (_toolsVisible) {
                    unfocus();
                  } else {
                    focus();
                  }
                });
              },
      );

  Widget _emojiBtn() => _buildBtn(
        padding: emojiButtonPadding,
        icon: widget.emojiIcon ??
            ImageUtil.emoji(
              color: widget.enabledEmojiButton ? _color : widget.disabledColor,
            ),
        onTap: _isMuted || !widget.enabledEmojiButton
            ? null
            : () {
                setState(() {
                  _rightKeyboardButton = true;
                  _leftKeyboardButton = false;
                  _emojiVisible = true;
                  _toolsVisible = false;
                  _keyboardVisible = false;
                  unfocus();
                });
              },
      );

  Widget _buildBtn({
    required Widget icon,
    Function()? onTap,
    EdgeInsetsGeometry? padding,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: padding ?? EdgeInsets.symmetric(horizontal: 10.w),
          child: icon,
        ),
      );
}
