import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/tau_chat.dart';

bool isDialog(TauChat chat) => chat.record is DialogDTO;
bool isChannel(TauChat chat) => chat.record is ChannelDTO;
