package net.result.taulight;

import android.os.Handler;
import android.os.Looper;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import net.result.sandnode.exception.InvalidSandnodeLinkException;
import net.result.sandnode.exception.UnprocessedMessagesException;
import net.result.sandnode.exception.crypto.CreatingKeyException;
import net.result.sandnode.exception.crypto.KeyNotCreatedException;
import net.result.sandnode.link.Links;
import net.result.sandnode.link.SandnodeLinkRecord;
import net.result.taulight.chain.AndroidClientChainManager;
import net.result.taulight.config.AndroidClientConfig;
import net.result.sandnode.config.ClientConfig;
import net.result.sandnode.encryption.interfaces.AsymmetricKeyStorage;
import net.result.sandnode.hubagent.Agent;
import net.result.sandnode.hubagent.ClientProtocol;
import net.result.sandnode.exception.ConnectionException;
import net.result.sandnode.exception.InputStreamException;
import net.result.sandnode.exception.OutputStreamException;
import net.result.sandnode.serverclient.SandnodeClient;
import net.result.sandnode.exception.ExpectedMessageException;
import net.result.sandnode.encryption.KeyStorageRegistry;
import net.result.taulight.exception.ClientNotFoundException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class Taulight {
    private static final Logger LOGGER = LogManager.getLogger(Taulight.class);
    public final Map<String, MemberClient> clients = new HashMap<>();
    public final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    private final Handler handler = new Handler(Looper.getMainLooper());

    private final MethodChannel methodChannel;

    public Taulight(MethodChannel methodChannel) {
        this.methodChannel = methodChannel;
    }

    public void sendToFlutter(String method, Map<String, Object> obj) {
        handler.post(() -> methodChannel.invokeMethod(method, obj));
    }

    public void addClient(String uuid, String linkString) throws OutputStreamException,
            ConnectionException, InputStreamException, ExpectedMessageException,
            InterruptedException, KeyNotCreatedException, UnprocessedMessagesException,
            CreatingKeyException, InvalidSandnodeLinkException {

        SandnodeLinkRecord link = Links.parse(linkString);

        KeyStorageRegistry keyStorageRegistry = new KeyStorageRegistry();
        Agent agent = new AndroidAgent(keyStorageRegistry, this, uuid);

        ClientConfig clientConfig = new AndroidClientConfig();
        SandnodeClient client = SandnodeClient.fromLink(link, agent, clientConfig);
        client.start(new AndroidClientChainManager(uuid, this));

        AsymmetricKeyStorage keyStorage = link.keyStorage();
        client.io.setServerKey(keyStorage);
        ClientProtocol.sendSYM(client);

        LOGGER.debug("Saving client of {} with uuid {}", client.endpoint, uuid);
        clients.put(uuid, new MemberClient(client, linkString));
    }

    public MemberClient getClient(String uuid) throws ClientNotFoundException {
        if (clients.containsKey(uuid)) {
            return clients.get(uuid);
        }
        throw new ClientNotFoundException(uuid);
    }
}
