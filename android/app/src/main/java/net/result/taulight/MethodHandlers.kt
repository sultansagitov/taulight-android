package net.result.taulight

import android.os.Build
import android.util.Base64
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.result.sandnode.chain.Chain
import net.result.sandnode.dto.FileDTO
import net.result.sandnode.exception.error.KeyStorageNotFoundException
import net.result.sandnode.link.Links
import net.result.sandnode.serverclient.SandnodeClient
import net.result.taulight.dto.ChatMessageInputDTO
import org.apache.logging.log4j.LogManager
import java.lang.reflect.InvocationTargetException
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

val uuidRegex = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")

val executorService: ExecutorService = Executors.newCachedThreadPool()

var methodHandlerMap: Map<String, (MethodCall) -> Any?> = emptyMap()

var taulight: Taulight? = null

object M {
    val LOGGER = LogManager.getLogger("MethodHandlers")!!
}

@RequiresApi(Build.VERSION_CODES.N)
class MethodHandlers(flutterEngine: FlutterEngine) {
    companion object {
        private const val CHANNEL = "net.result.taulight/messenger"
    }

    init {
        val binaryMessenger: BinaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        val methodChannel = MethodChannel(binaryMessenger, CHANNEL)
        taulight = Taulight(methodChannel)

        methodChannel.setMethodCallHandler(this::onMethodCallHandler)
        methodHandlerMap = mapOf(
            "connect" to ::connect,
            "disconnect" to ::disconnect,
            "register" to ::register,
            "send" to ::send,
            "get-chats" to ::getChats,
            "load-messages" to ::loadMessages,
            "load-clients" to ::loadClients,
            "load-chat" to ::loadChat,
            "login-history" to ::loginHistory,
            "chain" to ::chain,
        )
    }

    fun onMethodCallHandler(call: MethodCall, result: MethodChannel.Result) {
        executorService.execute {
            val handler = methodHandlerMap[call.method]
            if (handler != null) {
                taulight!!.clients.entries.removeIf { (_, mc) -> !mc.client.io().isConnected }

                try {
                    val res: Any? = handler(call)
                    result.success(mapOf("success" to res))
                } catch (e: Exception) {
                    M.LOGGER.error("Unhandled", e)
                    result.success(
                        mapOf(
                            "error" to mapOf(
                                "name" to e.javaClass.simpleName,
                                "message" to e.message
                            )
                        )
                    )
                }
            } else result.error("UNAVAILABLE", "Unknown method type", call.method)
        }
    }
}

fun connect(call: MethodCall): Map<String, String> {
    val uuid = call.argument<String>("uuid")!!
    val clientID = UUID.fromString(uuid)

    val linkString = call.argument<String>("link")!!
    val link = Links.parse(linkString)

    val address = connect(taulight!!, clientID, link)

    return mapOf("address" to address.toString(52525))
}

fun disconnect(call: MethodCall): String {
    val uuid: String = call.argument<String>("uuid")!!
    disconnect(taulight!!, uuid)
    return "disconnected"
}

fun register(call: MethodCall): Map<String, String> {
    val uuid: String = call.argument<String>("uuid")!!
    val nickname: String = call.argument<String>("nickname")!!
    val password: String = call.argument<String>("password")!!
    val device: String = call.argument<String>("device")!!

    val client = taulight!!.getClient(uuid)

    val response = register(client.client, nickname, password, device)
    return mapOf(
        "token" to response.token,
        "key-id" to response.keyID.toString()
    )
}

fun send(call: MethodCall): Map<String, String> {
    val uuid: UUID = UUID.fromString(call.argument<String>("uuid")!!)
    val chatID: UUID = UUID.fromString(call.argument<String>("chat-id")!!)
    val content: String = call.argument<String>("content")!!
    val repliedToMessagesString: List<String> = call.argument<List<String>>("replied-to-messages")!!
    val fileIDsString: List<String> = call.argument<List<String>>("file-id")!!

    val mc: MemberClient = taulight!!.getClient(uuid)
    val repliedToMessages: Set<UUID> = repliedToMessagesString.map { UUID.fromString(it) }.toSet()
    val fileIDs: Set<UUID> = fileIDsString.map { UUID.fromString(it) }.toSet()

    val chat = taulight!!.getChat(chatID) ?: loadChat(mc.client, chatID)

    return send(mc.client, chat, content, repliedToMessages, fileIDs)
}

fun getChats(call: MethodCall): List<Map<String, Any>> {
    val uuid: String = call.argument<String>("uuid")!!
    val mc = taulight!!.getClient(uuid)
    return getChats(mc.client)
}

fun loadMessages(call: MethodCall): Map<String, Any> {
    val uuid: String = call.argument<String>("uuid")!!
    val chatIDStr: String = call.argument<String>("chat-id")!!
    val index: Int = call.argument<Int>("index")!!
    val size: Int = call.argument<Int>("size")!!

    val client: SandnodeClient = taulight!!.getClient(uuid).client
    val chatID: UUID = UUID.fromString(chatIDStr)

    val paginated = loadMessages(client, chatID, index, size)

    val messages = paginated.objects
    return mapOf(
        "count" to paginated.totalCount,
        "messages" to messages.map {
            val map: MutableMap<String, Any> = mutableMapOf(
                "message" to taulight!!.objectMapper.convertValue(it, Map::class.java)
            )

            try {
                val decrypted: String
                val input: ChatMessageInputDTO = it.message
                if (input.keyID != null) {
                    val agent = client.node().agent()
                    val keyStorage = agent.config.loadDEK(client.address, input.keyID)
                    val decoded = Base64.decode(input.content, Base64.NO_WRAP)
                    decrypted = keyStorage.encryption().decrypt(decoded, keyStorage)
                } else {
                    decrypted = input.content
                }

                map["decrypted"] = decrypted
            } catch (e: KeyStorageNotFoundException) {
                M.LOGGER.error("Send to flutter without decrypting - {}, {}", client, it, e)
            }

            map
        }
    )
}

@Suppress("unused")
fun loadClients(ignoredCall: MethodCall): List<Map<String, String>> {
    return taulight!!.clients.entries.map { (clientID, mc) ->
        val client = mc.client
        val map = mutableMapOf(
            "uuid" to clientID.toString(),
            "address" to client.address.toString(),
            "link" to mc.link.toString(),
        )

        if (client.nickname != null) map["nickname"] = client.nickname!!

        map
    }
}

fun loadChat(call: MethodCall): Map<String, Any> {
    val uuid: String = call.argument<String>("uuid")!!
    val chatString: String = call.argument<String>("chat-id")!!

    val chatID: UUID = UUID.fromString(chatString)
    val mc = taulight!!.getClient(uuid)
    val client = mc.client
    val chat = loadChat(client, chatID)

    val map: MutableMap<String, Any> = mutableMapOf(
        "chat" to taulight!!.objectMapper.convertValue(chat, Map::class.java)!!
    )

    chat.lastMessage?.let {
        try {
            decrypt(client, chat)
            map["decrypted-last-message"] = chat.decryptedMessage!!
        } catch (e: KeyStorageNotFoundException) {
            ChatRunner.LOGGER.error("Send to flutter without decrypting - {}, {}", client, chat, e)
        }
    }
    return map
}

fun loginHistory(call: MethodCall): List<Map<String, Any>> {
    val uuid: String = call.argument<String>("uuid")!!
    val mc = taulight!!.getClient(uuid)
    return loginHistory(mc.client)
}

fun chain(call: MethodCall): Any? {
    val uuid: String = call.argument<String>("uuid")!!
    val full: String = call.argument<String>("method")!!
    val params: List<Any> = call.argument<List<Any>>("params") ?: emptyList()

    val splitted = full.split(".")

    val className = splitted[0]
    val methodName = splitted[1]

    val client: SandnodeClient = taulight!!.getClient(uuid).client

    var clazz: Class<*>
    try {
        clazz = Class.forName("net.result.taulight.chain.sender.$className")
    } catch (_: ClassNotFoundException) {
        clazz = Class.forName("net.result.sandnode.chain.sender.$className")
    }
    val declaredConstructor = clazz.getDeclaredConstructor(SandnodeClient::class.java)
    val method = clazz.methods
        .firstOrNull { it.name == methodName && it.parameterTypes.size == params.size }
        ?: throw ClassNotFoundException()

    val chain: Chain? = declaredConstructor.newInstance(client) as Chain?

    client.io().chainManager.linkChain(chain)
    try {
        val processedParams = params.map {
            if (it is String && uuidRegex.matches(it)) {
                UUID.fromString(it)
            } else {
                it
            }
        }

        val result = method.invoke(chain, *processedParams.toTypedArray())
        return when (result) {
            Unit -> null
            is FileDTO -> mapOf(
                "id" to result.id().toString(),
                "contentType" to result.contentType(),
                "avatarBase64" to Base64.encodeToString(result.body(), Base64.NO_WRAP)
            )
            else -> taulight!!.objectMapper.convertValue(result, Any::class.java)
        }
    } catch (e: InvocationTargetException) {
        throw e.cause ?: e
    } finally {
        client.io().chainManager.removeChain(chain)
    }
}
