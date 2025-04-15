package net.result.taulight;

import android.annotation.TargetApi;
import android.os.Build;

import net.result.sandnode.exception.error.SandnodeErrorException;
import net.result.sandnode.link.Links;
import net.result.sandnode.link.SandnodeLinkRecord;
import net.result.sandnode.serverclient.SandnodeClient;
import net.result.sandnode.util.IOController;
import net.result.taulight.exception.ClientNotFoundException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.*;
import java.util.Map.Entry;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;
import java.util.UUID;

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

    private final Runner runner;

    public MethodHandlers(FlutterEngine flutterEngine) {
        executorService = Executors.newCachedThreadPool();

        BinaryMessenger binaryMessenger = flutterEngine.getDartExecutor().getBinaryMessenger();
        String CHANNEL = "net.result.taulight/messenger";

        MethodChannel methodChannel = new MethodChannel(binaryMessenger, CHANNEL);
        methodChannel.setMethodCallHandler(this::onMethodCallHandler);

        taulight = new Taulight(methodChannel);

        runner = new Runner(taulight);

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
                Iterator<Entry<UUID, MemberClient>> iterator = taulight.clients.entrySet().iterator();
                while (iterator.hasNext()) {
                    Entry<UUID, MemberClient> entry = iterator.next();
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

        return runner.members(client, chatID);
    }

    private Map<String, String> connect(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String linkString = call.argument("link");

        assert uuid != null;
        assert linkString != null;

        SandnodeLinkRecord link = Links.parse(linkString);

        UUID clientID = UUID.fromString(uuid);

        return runner.connect(clientID, link);
    }

    private Map<String, String> login(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String nickname = call.argument("nickname");
        String password = call.argument("password");

        assert nickname != null;
        assert password != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.login(client, nickname, password);
    }

    private Map<String, String> register(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String nickname = call.argument("nickname");
        String password = call.argument("password");

        assert nickname != null;
        assert password != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.register(client, nickname, password);
    }

    private String disconnect(MethodCall call) throws ClientNotFoundException {
        String uuid = call.argument("uuid");
        return runner.disconnect(uuid);
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

        Set<UUID> replies = repliesString.stream()
                .map(UUID::fromString)
                .collect(Collectors.toSet());

        MemberClient mc = taulight.getClient(uuid);
        IOController io = mc.client.io;

        return runner.send(io, chatID, content, replies);
    }

    private String groupAdd(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String group = call.argument("group");

        assert uuid != null;
        assert group != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.groupAdd(client, group);
    }

    /** @noinspection rawtypes*/
    @TargetApi(Build.VERSION_CODES.TIRAMISU)
    private List getChats(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        assert uuid != null;

        SandnodeClient client = taulight.getClient(uuid).client;
        return runner.getChats(client);
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

        return runner.loadMessages(client, chatID, index, size);
    }

    @TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private List<Map<String, String>> loadClient(MethodCall ignoredCall) {
        return runner.loadClient();
    }

    @TargetApi(Build.VERSION_CODES.N)
    private Object loadChat(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chat = call.argument("chat-id");
        assert uuid != null;
        assert chat != null;

        UUID chatID = UUID.fromString(chat);
        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.loadChat(client, chatID);
    }

    private Map<String, String> createChannel(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String title = call.argument("title");
        assert uuid != null;
        assert title != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.createChannel(client, title);
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

        return runner.addMember(client, chatID, otherNickname);
    }

    private Map<String, String> token(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String token = call.argument("token");

        assert uuid != null;
        assert token != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.token(client, token);
    }

    private Object checkCode(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String code = call.argument("code");

        assert uuid != null;
        assert code != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.checkCode(client, code);
    }

    private String useCode(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String code = call.argument("code");

        assert uuid != null;
        assert code != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.useCode(client, code);
    }

    private Map<String, String> dialog(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String nickname = call.argument("nickname");

        assert uuid != null;
        assert nickname != null;

        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.dialog(client, nickname);
    }

    private String leave(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatIDStr = call.argument("chat-id");

        assert uuid != null;
        assert chatIDStr != null;

        UUID chatID = UUID.fromString(chatIDStr);
        SandnodeClient client = taulight.getClient(uuid).client;

        return runner.leave(client, chatID);
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

        return runner.channelCodes(client, chatID);
    }

    @TargetApi(Build.VERSION_CODES.N)
    private String reply(MethodCall call) throws Exception {
        String uuid = call.argument("uuid");
        String chatIDStr = call.argument("chat-id");
        String content = call.argument("content");
        List<String> replyIDs = call.argument("replies");

        assert chatIDStr != null;
        assert content != null;

        MemberClient mc = taulight.getClient(uuid);


        UUID chatID = UUID.fromString(chatIDStr);
        Set<UUID> replies = new HashSet<>();

        if (replyIDs != null && !replyIDs.isEmpty()) {
            for (String replyID : replyIDs) {
                replies.add(UUID.fromString(replyID));
            }
        }

        return runner.reply(mc, chatID, content, replies);
    }
}
