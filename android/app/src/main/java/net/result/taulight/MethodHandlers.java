package net.result.taulight;

import android.annotation.TargetApi;
import android.os.Build;

import net.result.sandnode.chain.IChain;
import net.result.sandnode.chain.sender.LogPasswdClientChain;
import net.result.sandnode.chain.sender.LoginClientChain;
import net.result.sandnode.chain.sender.RegistrationClientChain;
import net.result.sandnode.exception.error.SandnodeErrorException;
import net.result.sandnode.hubagent.ClientProtocol;
import net.result.sandnode.link.Links;
import net.result.sandnode.link.SandnodeLinkRecord;
import net.result.sandnode.message.RawMessage;
import net.result.sandnode.message.types.ChainNameRequest;
import net.result.sandnode.message.util.MessageTypes;
import net.result.sandnode.serverclient.SandnodeClient;
import net.result.sandnode.util.IOController;
import net.result.taulight.chain.client.AndroidForwardRequestChain;
import net.result.taulight.chain.sender.ChannelClientChain;
import net.result.taulight.chain.sender.ChatClientChain;
import net.result.taulight.chain.sender.CheckCodeClientChain;
import net.result.taulight.chain.sender.DialogClientChain;
import net.result.taulight.chain.sender.MembersClientChain;
import net.result.taulight.chain.sender.MessageClientChain;
import net.result.taulight.chain.sender.UseCodeClientChain;
import net.result.taulight.code.TauCode;
import net.result.taulight.db.ChatMessage;
import net.result.taulight.db.ServerChatMessage;
import net.result.taulight.exception.ClientNotFoundException;
import net.result.taulight.message.ChatInfo;
import net.result.taulight.message.ChatInfoProp;
import net.result.taulight.message.MemberRecord;
import net.result.taulight.message.types.ForwardRequest;
import net.result.taulight.message.types.UUIDMessage;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MethodHandlers {
    private static final Logger LOGGER = LogManager.getLogger(MethodHandlers.class);

    private interface MethodHandler {
        Object methodCall(MethodCall ignoredCall) throws Exception;
    }

    private final Map<String, MethodHandler> methodHandlerMap;
    private final Taulight taulight;

    private final ExecutorService executorService;

    public MethodHandlers(FlutterEngine flutterEngine) {
        executorService = Executors.newCachedThreadPool();

        BinaryMessenger binaryMessenger = flutterEngine.getDartExecutor().getBinaryMessenger();
        String CHANNEL = "net.result.taulight/messenger";

        MethodChannel methodChannel = new MethodChannel(binaryMessenger, CHANNEL);
        methodChannel.setMethodCallHandler(this::onMethodCallHandler);

        taulight = new Taulight(methodChannel);

        methodHandlerMap = new HashMap<>();
        methodHandlerMap.put("connect", this::connect);
        methodHandlerMap.put("login", this::login);
        methodHandlerMap.put("register", this::register);
        methodHandlerMap.put("disconnect", this::disconnect);
        methodHandlerMap.put("send", this::send);
        methodHandlerMap.put("group", this::groupAdd);
        methodHandlerMap.put("get-chats", this::getChats);
        methodHandlerMap.put("load-messages", this::loadMessages);
        methodHandlerMap.put("load-clients", this::loadClient);
        methodHandlerMap.put("load-chat", this::loadChat);
        methodHandlerMap.put("create-channel", this::createChannel);
        methodHandlerMap.put("members", this::members);
        methodHandlerMap.put("add-member", this::addMember);
        methodHandlerMap.put("token", this::token);
        methodHandlerMap.put("check-code", this::checkCode);
        methodHandlerMap.put("use-code", this::useCode);
        methodHandlerMap.put("dialog", this::dialog);
        methodHandlerMap.put("leave", this::leave);
        methodHandlerMap.put("channel-codes", this::channelCodes);
        methodHandlerMap.put("reply", this::reply);
    }

    @TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private void onMethodCallHandler(MethodCall call, MethodChannel.Result result) {
        executorService.execute(() -> {
            MethodHandler handler = methodHandlerMap.get(call.method);
            if (handler != null) {
                Iterator<Entry<String, MemberClient>> iterator = taulight.clients.entrySet().iterator();
                while (iterator.hasNext()) {
                    Entry<String, MemberClient> entry = iterator.next();
                    if (!entry.getValue().client.io.isConnected()) {
                        LOGGER.debug("Removing client with uuid {}", entry.getKey());
                        iterator.remove();
                    }
                }

                try {
                    Object res = handler.methodCall(call);
                    result.success(Map.of("success", res));

                } catch (SandnodeErrorException e) {
                    Map<String, String> error = new HashMap<>();
                    error.put("name", e.getClass().getSimpleName());
                    error.put("message", e.getMessage());
                    result.success(Map.of("error", error));

                } catch (Exception e) {
                    LOGGER.error("Unhandled", e);
                    Map<String, String> error = new HashMap<>();
                    error.put("name", e.getClass().getSimpleName());
                    error.put("message", e.getMessage());
                    result.success(Map.of("error", error));
                }
            }
            else result.error("UNAVAILABLE", "Unknown method type", call.method);
        });
    }

    private Object members(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatIDStr = call.argument("chat-id");

        assert uuid != null;
        assert chatIDStr != null;

        SandnodeClient client = taulight.getClient(uuid).client;
        UUID chatID = UUID.fromString(chatIDStr);

        MembersClientChain chain = new MembersClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        Collection<MemberRecord> members = chain.getMembers(chatID);
        client.io.chainManager.removeChain(chain);

        return taulight.objectMapper.convertValue(members, List.class);
    }

    private Map<String, String> connect(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String linkString = call.argument("link");

        assert uuid != null;
        assert linkString != null;

        SandnodeLinkRecord link = Links.parse(linkString);
        taulight.addClient(uuid, linkString);

        return Map.of("endpoint", link.endpoint().toString(52525));
    }

    private Map<String, String> login(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String nickname = call.argument("nickname");
        String password = call.argument("password");

        assert uuid != null;
        assert nickname != null;
        assert password != null;

        SandnodeClient client = taulight.getClient(uuid).client;
        var chain = new LogPasswdClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        String token = chain.getToken(nickname, password);
        client.io.chainManager.removeChain(chain);

        return Map.of("token", token);
    }

    private Map<String, String> register(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String nickname = call.argument("nickname");
        String password = call.argument("password");

        assert uuid != null;
        assert nickname != null;
        assert password != null;

        SandnodeClient client = taulight.getClient(uuid).client;
        var chain = new RegistrationClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        String token = chain.getTokenFromRegistration(nickname, password);
        client.io.chainManager.removeChain(chain);

        return Map.of("token", token);
    }

    private String disconnect(MethodCall call) throws ClientNotFoundException {
        String uuid = call.argument("uuid");
        SandnodeClient client = taulight.getClient(uuid).client;
        client.close();
        return "disconnected";
    }

    @TargetApi(Build.VERSION_CODES.N)
    private String send(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatID = call.argument("chat-id");
        String content = call.argument("content");
        List<String> repliesString = call.argument("replies");

        assert uuid != null;
        assert chatID != null;
        assert content != null;
        assert repliesString != null;

        List<UUID> replies = repliesString.stream()
                .map(UUID::fromString)
                .collect(Collectors.toList());

        MemberClient mc = taulight.getClient(uuid);
        IOController io = mc.client.io;

        Optional<IChain> fwdReq = io.chainManager.getChain("fwd_req");

        AndroidForwardRequestChain androidChain;
        if (fwdReq.isPresent()) {
            androidChain = (AndroidForwardRequestChain) fwdReq.get();
        } else {
            androidChain = new AndroidForwardRequestChain(io);
            io.chainManager.setName(androidChain, "fwd_req");
            io.chainManager.linkChain(androidChain);
        }

        ChatMessage message = new ChatMessage()
                .setChatID(UUID.fromString(chatID))
                .setContent(content)
                .setReplies(replies)
                .setZtdNow();

        return androidChain.sendMessage(message).toString();
    }

    private String groupAdd(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String group = call.argument("group");

        assert uuid != null;
        assert group != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        ClientProtocol.addToGroups(client.io, Set.of(group));

        return "sent";
    }

    /** @noinspection rawtypes*/
    @TargetApi(Build.VERSION_CODES.TIRAMISU)
    private List getChats(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        assert uuid != null;

        SandnodeClient client = taulight.getClient(uuid).client;
        Optional<IChain> chat = client.io.chainManager.getChain("chat");

        Optional<Collection<ChatInfo>> optChats;
        if (chat.isPresent()) {
            ChatClientChain chain = (ChatClientChain) chat.get();
            optChats = chain.getByMember(ChatInfoProp.all());
        } else {
            ChatClientChain chain = new ChatClientChain(client.io);
            client.io.chainManager.linkChain(chain);
            optChats = chain.getByMember(ChatInfoProp.all());
            chain.send(new ChainNameRequest("chat"));
        }

        if (optChats.isPresent()) {
            Collection<ChatInfo> infos = optChats.get();
            return taulight.objectMapper.convertValue(infos, List.class);
        }

        return new ArrayList<>();
    }

    private Map<String, Object> loadMessages(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatID_str = call.argument("chat-id");
        Integer index = call.argument("index");
        Integer size = call.argument("size");

        assert uuid != null;
        assert chatID_str != null;
        assert index != null;
        assert size != null;

        SandnodeClient client = taulight.getClient(uuid).client;
        UUID chatID = UUID.fromString(chatID_str);

        var chain = new MessageClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        chain.getMessages(chatID, index, size);
        client.io.chainManager.removeChain(chain);
        List<ServerChatMessage> messages = chain.getMessages();
        return Map.of(
            "count", chain.getCount(),
            "messages", taulight.objectMapper.convertValue(messages, List.class)
        );
    }

    @TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private List<Map<String, String>> loadClient(MethodCall ignoredCall) {
        return taulight.clients
                .entrySet().stream()
                .map((entry) -> Map.of(
                    "uuid", entry.getKey(),
                    "endpoint", entry.getValue().client.endpoint.toString(),
                    "link", entry.getValue().link
                ))
                .toList();
    }

    @TargetApi(Build.VERSION_CODES.N)
    private Object loadChat(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatUuid = call.argument("chat-id");
        assert uuid != null;
        assert chatUuid != null;
        Collection<UUID> chatID = List.of(UUID.fromString(chatUuid));

        SandnodeClient client = taulight.getClient(uuid).client;
        Optional<IChain> chat = client.io.chainManager.getChain("chat");

        Collection<ChatInfo> optChats;
        if (chat.isPresent()) {
            ChatClientChain chain = (ChatClientChain) chat.get();
            optChats = chain.getByID(chatID, ChatInfoProp.all());
        } else {
            ChatClientChain chain = new ChatClientChain(client.io);
            client.io.chainManager.linkChain(chain);
            optChats = chain.getByID(chatID, ChatInfoProp.all());
            chain.send(new ChainNameRequest("chat"));
        }

        ChatInfo info = optChats.stream().findFirst().get();
        return taulight.objectMapper.convertValue(info, Map.class);
    }

    private Map<String, String> createChannel(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String title = call.argument("title");
        assert uuid != null;
        assert title != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        var chain = new ChannelClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        UUID chatID = chain.sendNewChannelRequest(title);
        client.io.chainManager.removeChain(chain);
        return Map.of("chat-id", chatID.toString());
    }

    @TargetApi(Build.VERSION_CODES.O)
    private Map<String, String> addMember(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatIDString = call.argument("chat-id");
        String otherNickname = call.argument("nickname");
        assert uuid != null;
        assert chatIDString != null;

        UUID chatID = UUID.fromString(chatIDString);

        SandnodeClient client = taulight.getClient(uuid).client;

        var chain = new ChannelClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        String code = chain.createInviteCode(chatID, otherNickname, Duration.ofDays(1));
        client.io.chainManager.removeChain(chain);
        return Map.of("code", code);
    }

    private Map<String, String> token(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String token = call.argument("token");

        assert uuid != null;
        assert token != null;

        SandnodeClient client = taulight.getClient(uuid).client;
        LoginClientChain chain = new LoginClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        String nickname = chain.getNickname(token);
        client.io.chainManager.removeChain(chain);

        return Map.of("nickname", nickname);
    }

    private Object checkCode(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String code = call.argument("code");

        assert uuid != null;
        assert code != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        var chain = new CheckCodeClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        TauCode c = chain.check(code);
        client.io.chainManager.removeChain(chain);

        return taulight.objectMapper.convertValue(c, Map.class);
    }

    private String useCode(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String code = call.argument("code");

        assert uuid != null;
        assert code != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        var chain = new UseCodeClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        chain.use(code);
        client.io.chainManager.removeChain(chain);

        return "success";
    }

    private Map<String, String> dialog(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String nickname = call.argument("nickname");

        assert uuid != null;
        assert nickname != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        var chain = new DialogClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        UUID chatID = chain.getDialogID(nickname);
        client.io.chainManager.removeChain(chain);

        return Map.of("chat-id", chatID.toString());
    }

    private String leave(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatIDStr = call.argument("chat-id");

        assert uuid != null;
        assert chatIDStr != null;

        UUID chatID = UUID.fromString(chatIDStr);
        SandnodeClient client = taulight.getClient(uuid).client;

        ChannelClientChain chain = new ChannelClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        chain.sendLeaveRequest(chatID);
        client.io.chainManager.removeChain(chain);

        return "success";
    }

    /** @noinspection rawtypes*/
    @TargetApi(Build.VERSION_CODES.N)
    private List channelCodes(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatIDStr = call.argument("chat-id");

        assert uuid != null;
        assert chatIDStr != null;

        UUID chatID = UUID.fromString(chatIDStr);
        SandnodeClient client = taulight.getClient(uuid).client;

        var chain = new ChannelClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        Collection<TauCode> codes = chain.getChannelCodes(chatID);
        client.io.chainManager.removeChain(chain);

        return taulight.objectMapper.convertValue(codes, List.class);
    }

    @TargetApi(Build.VERSION_CODES.N)
    private String reply(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatIDStr = call.argument("chat-id");
        String content = call.argument("content");
        List<String> replyIDs = call.argument("replies");

        assert uuid != null;
        assert chatIDStr != null;
        assert content != null;

        MemberClient mc = taulight.getClient(uuid);
        IOController io = mc.client.io;

        Optional<IChain> fwdReq = io.chainManager.getChain("fwd_req");

        AndroidForwardRequestChain androidChain;
        if (fwdReq.isPresent()) {
            androidChain = (AndroidForwardRequestChain) fwdReq.get();
        } else {
            androidChain = new AndroidForwardRequestChain(io);
            io.chainManager.setName(androidChain, "fwd_req");
            io.chainManager.linkChain(androidChain);
        }

        UUID chatID = UUID.fromString(chatIDStr);
        List<UUID> replies = new ArrayList<>();

        if (replyIDs != null && !replyIDs.isEmpty()) {
            for (String replyID : replyIDs) {
                replies.add(UUID.fromString(replyID));
            }
        }

        ChatMessage message = new ChatMessage()
                .setChatID(chatID)
                .setContent(content)
                .setReplies(replies)
                .setZtdNow();

        androidChain.send(new ForwardRequest(message));
        RawMessage raw = androidChain.queue.take();
        raw.expect(MessageTypes.HAPPY);
        UUIDMessage uuidMessage = new UUIDMessage(raw);
        return uuidMessage.uuid.toString();
    }
}
