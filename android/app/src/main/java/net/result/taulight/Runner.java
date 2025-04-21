package net.result.taulight;

import net.result.sandnode.chain.IChain;
import net.result.sandnode.chain.sender.LogPasswdClientChain;
import net.result.sandnode.chain.sender.LoginClientChain;
import net.result.sandnode.chain.sender.RegistrationClientChain;
import net.result.sandnode.hubagent.ClientProtocol;
import net.result.sandnode.link.SandnodeLinkRecord;
import net.result.sandnode.message.RawMessage;
import net.result.sandnode.message.UUIDMessage;
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
import net.result.taulight.chain.sender.ReactionRequestClientChain;
import net.result.taulight.chain.sender.UseCodeClientChain;
import net.result.taulight.dto.*;
import net.result.taulight.exception.ClientNotFoundException;
import net.result.taulight.message.types.ForwardRequest;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

public class Runner {
    public Taulight taulight;

    public Runner(Taulight taulight) {
        this.taulight = taulight;
    }

    public Map<String, String> connect(UUID clientID, SandnodeLinkRecord link) throws Exception {
        taulight.addClient(clientID, link);
        return Map.of("endpoint", link.endpoint().toString(52525));
    }

    public Object members(SandnodeClient client, UUID chatID) throws Exception {
        MembersClientChain chain = new MembersClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        Collection<ChatMemberDTO> members = chain.getMembers(chatID);
        client.io.chainManager.removeChain(chain);

        return taulight.objectMapper.convertValue(members, List.class);
    }

    public Map<String, String> login(SandnodeClient client, String nickname, String password)
            throws Exception {
        var chain = new LogPasswdClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        String token = chain.getToken(nickname, password);
        client.io.chainManager.removeChain(chain);

        return Map.of("token", token);
    }

    public Map<String, String> register(SandnodeClient client, String nickname, String password)
            throws Exception {
        var chain = new RegistrationClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        String token = chain.getTokenFromRegistration(nickname, password);
        client.io.chainManager.removeChain(chain);

        return Map.of("token", token);
    }

    public String disconnect(String uuid) throws ClientNotFoundException {
        SandnodeClient client = taulight.getClient(uuid).client;
        client.close();
        return "disconnected";
    }

    public String send(IOController io, String chatID, String content, Set<UUID> replies)
            throws Exception {
        Optional<IChain> fwdReq = io.chainManager.getChain("fwd_req");

        AndroidForwardRequestChain androidChain;
        if (fwdReq.isPresent()) {
            androidChain = (AndroidForwardRequestChain) fwdReq.get();
        } else {
            androidChain = new AndroidForwardRequestChain(io);
            io.chainManager.setName(androidChain, "fwd_req");
            io.chainManager.linkChain(androidChain);
        }

        ChatMessageInputDTO message = new ChatMessageInputDTO()
                .setChatID(UUID.fromString(chatID))
                .setContent(content)
                .setRepliedToMessages(replies)
                .setSentDatetimeNow();

        return androidChain.message(message).toString();
    }

    public String groupAdd(SandnodeClient client, String group) throws Exception {
        ClientProtocol.addToGroups(client.io, Set.of(group));
        return "sent";
    }

    public List getChats(SandnodeClient client) throws Exception {
        ChatClientChain chain = new ChatClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        Collection<ChatInfoDTO> infos = chain.getByMember(ChatInfoPropDTO.all());
        client.io.chainManager.removeChain(chain);
        return taulight.objectMapper.convertValue(infos, List.class);
    }

    public Map<String, Object> loadMessages(
            SandnodeClient client,
            UUID chatID,
            int index,
            int size
    ) throws Exception {
        var chain = new MessageClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        chain.getMessages(chatID, index, size);
        client.io.chainManager.removeChain(chain);
        List<ChatMessageViewDTO> messages = chain.getMessages();
        return Map.of(
                "count", chain.getCount(),
                "messages", taulight.objectMapper.convertValue(messages, List.class)
        );
    }

    public List<Map<String, String>> loadClient() {
        return taulight.clients
                .entrySet().stream()
                .map((entry) -> {
                    UUID clientID = entry.getKey();
                    MemberClient mc = entry.getValue();

                    return Map.of(
                            "uuid", clientID.toString(),
                            "endpoint", mc.client.endpoint.toString(),
                            "link", mc.link.toString()
                    );
                })
                .toList();
    }

    public Object loadChat(SandnodeClient client, UUID chatID) throws Exception {
        ChatClientChain chain = new ChatClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        Collection<ChatInfoDTO> optChats = chain.getByID(List.of(chatID), ChatInfoPropDTO.all());
        client.io.chainManager.removeChain(chain);

        ChatInfoDTO info = optChats.stream().findFirst().get();
        return taulight.objectMapper.convertValue(info, Map.class);
    }

    public Map<String, String> createChannel(SandnodeClient client, String title) throws Exception {
        var chain = new ChannelClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        UUID chatID = chain.sendNewChannelRequest(title);
        client.io.chainManager.removeChain(chain);
        return Map.of("chat-id", chatID.toString());
    }

    public Map<String, String> addMember(SandnodeClient client, UUID chatID, String otherNickname)
            throws Exception {
        var chain = new ChannelClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        String code = chain.createInviteCode(chatID, otherNickname, Duration.ofDays(1));
        client.io.chainManager.removeChain(chain);
        return Map.of("code", code);
    }

    public Map<String, String> token(SandnodeClient client, String token) throws Exception {
        LoginClientChain chain = new LoginClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        String nickname = chain.getNickname(token);
        client.io.chainManager.removeChain(chain);

        return Map.of("nickname", nickname);
    }

    public Object checkCode(SandnodeClient client, String code) throws Exception {
        var chain = new CheckCodeClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        CodeDTO c = chain.check(code);
        client.io.chainManager.removeChain(chain);

        return taulight.objectMapper.convertValue(c, Map.class);
    }

    public String useCode(SandnodeClient client, String code) throws Exception {
        var chain = new UseCodeClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        chain.use(code);
        client.io.chainManager.removeChain(chain);

        return "success";
    }

    public Map<String, String> dialog(SandnodeClient client, String nickname) throws Exception {
        var chain = new DialogClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        UUID chatID = chain.getDialogID(nickname);
        client.io.chainManager.removeChain(chain);

        return Map.of("chat-id", chatID.toString());
    }

    public String leave(SandnodeClient client, UUID chatID) throws Exception {
        ChannelClientChain chain = new ChannelClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        chain.sendLeaveRequest(chatID);
        client.io.chainManager.removeChain(chain);

        return "success";
    }

    public List channelCodes(SandnodeClient client, UUID chatID) throws Exception {
        var chain = new ChannelClientChain(client.io);
        client.io.chainManager.linkChain(chain);
        Collection<CodeDTO> codes = chain.getChannelCodes(chatID);
        client.io.chainManager.removeChain(chain);

        return taulight.objectMapper.convertValue(codes, List.class);
    }

    public String react(SandnodeClient client, UUID msgID, String reactionType) throws Exception {
        var chain = new ReactionRequestClientChain(client.io);
        client.io.chainManager.linkChain(chain);

        chain.react(msgID, reactionType);
        System.out.printf("Added reaction '%s' to message %s%n", reactionType, msgID);

        client.io.chainManager.removeChain(chain);

        return "success";
    }

    public String unreact(SandnodeClient client, UUID msgID, String reactionType) throws Exception {
        var chain = new ReactionRequestClientChain(client.io);
        client.io.chainManager.linkChain(chain);

        chain.unreact(msgID, reactionType);
        System.out.printf("Removed reaction '%s' from message %s%n", reactionType, msgID);

        client.io.chainManager.removeChain(chain);

        return "success";
    }
}
