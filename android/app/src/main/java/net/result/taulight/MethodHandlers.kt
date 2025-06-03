package net.result.taulight

import android.os.Build
import android.util.Base64
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.result.sandnode.chain.IChain
import net.result.sandnode.exception.error.KeyStorageNotFoundException
import net.result.sandnode.exception.error.SandnodeErrorException
import net.result.sandnode.hubagent.Agent
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
            "login" to ::login,
            "group-send" to ::groupSend,
            "dialog-send" to ::dialogSend,
            "get-chats" to ::getChats,
            "load-messages" to ::loadMessages,
            "load-clients" to ::loadClients,
            "load-chat" to ::loadChat,
            "get-channel-avatar" to ::getChannelAvatar,
            "get-dialog-avatar" to ::getDialogAvatar,
            "get-avatar" to ::getAvatar,
            "set-avatar" to ::setAvatar,
            "chain" to ::chain,
        )
    }

    fun onMethodCallHandler(call: MethodCall, result: MethodChannel.Result) {
        executorService.execute {
            val handler = methodHandlerMap[call.method]
            if (handler != null) {
                taulight!!.clients.entries.removeIf { (_, mc) -> !mc.client.io.isConnected }

                try {
                    val res: Any? = handler(call)
                    result.success(mapOf("success" to res))
                } catch (e: SandnodeErrorException) {
                    result.success(
                        mapOf(
                            "error" to mapOf(
                                "name" to e.javaClass.simpleName,
                                "message" to e.message
                            )
                        )
                    )
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

    val endpoint = connect(taulight!!, clientID, link)

    return mapOf("endpoint" to endpoint.toString(52525))
}

fun disconnect(call: MethodCall): String {
    val uuid: String = call.argument<String>("uuid")!!
    disconnect(taulight!!, uuid)
    return "disconnected"
}

fun register(call: MethodCall): Map<String, String?> {
    val uuid: String = call.argument<String>("uuid")!!
    val nickname: String = call.argument<String>("nickname")!!
    val password: String = call.argument<String>("password")!!
    val device: String = call.argument<String>("device")!!

    val client = taulight!!.getClient(uuid).client

    val response = register(client, nickname, password, device)
    return mapOf(
        "token" to response.token,
        "key-id" to response.keyID.toString()
    )
}

fun login(call: MethodCall): String {
    val uuid: String = call.argument<String>("uuid")!!
    val token: String = call.argument<String>("token")!!

    val client = taulight!!.getClient(uuid).client

    return login(client, token)
}

fun groupSend(call: MethodCall): String {
    val uuid: String = call.argument<String>("uuid")!!
    val chatID: String = call.argument<String>("chat-id")!!
    val content: String = call.argument<String>("content")!!
    val repliedToMessagesString: List<String> = call.argument<List<String>>("repliedToMessages")!!

    val mc: MemberClient = taulight!!.getClient(uuid)
    val repliedToMessages: Set<UUID> = repliedToMessagesString.map { UUID.fromString(it) }.toSet()

    return groupSend(mc.client, UUID.fromString(chatID), content, repliedToMessages).toString()
}

fun dialogSend(call: MethodCall): String {
    val uuid: String = call.argument<String>("uuid")!!
    val chatID: String = call.argument<String>("chat-id")!!
    val nickname: String = call.argument<String>("nickname")!!
    val content: String = call.argument<String>("content")!!
    val repliedToMessagesString: List<String> = call.argument<List<String>>("repliedToMessages")!!

    val mc: MemberClient = taulight!!.getClient(uuid)
    val repliedToMessages: Set<UUID> = repliedToMessagesString.map { UUID.fromString(it) }.toSet()

    return dialogSend(mc.client, nickname, UUID.fromString(chatID), content, repliedToMessages).toString()
}

fun getChats(call: MethodCall): List<Map<String, Any>> {
    val uuid: String = call.argument<String>("uuid")!!
    val client = taulight!!.getClient(uuid).client

    return getChats(client)
}

@Throws(Exception::class)
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
                    val agent = client.node as Agent
                    val keyStorage = agent.config.loadDEK(input.keyID)
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
        val map = mutableMapOf(
            "uuid" to clientID.toString(),
            "endpoint" to mc.client.endpoint.toString(),
            "link" to mc.link.toString(),
        )

        if (mc.nickname != null) map["nickname"] = mc.nickname!!

        map
    }
}

fun loadChat(call: MethodCall): Map<String, Any> {
    val uuid: String = call.argument<String>("uuid")!!
    val chatString: String = call.argument<String>("chat-id")!!

    val chatID: UUID = UUID.fromString(chatString)
    val client: SandnodeClient = taulight!!.getClient(uuid).client

    return loadChat(client, chatID)
}

fun getChannelAvatar(call: MethodCall): Map<String, String> {
    val uuid: String = call.argument<String>("uuid")!!
    val chatIDString: String = call.argument<String>("chat-id")!!

    val chatID: UUID = UUID.fromString(chatIDString)

    val client: SandnodeClient = taulight!!.getClient(uuid).client

    val file = getChannelAvatar(client, chatID)
    if (file == null) return mapOf()

    val contentType = file.contentType()
    val body = file.body()

    val base64Avatar = Base64.encodeToString(body, Base64.NO_WRAP)

    return mapOf(
        "contentType" to contentType,
        "avatarBase64" to base64Avatar
    )
}

fun getDialogAvatar(call: MethodCall): Map<String, String> {
    val uuid: String = call.argument<String>("uuid")!!
    val chatIDString: String = call.argument<String>("chat-id")!!

    val chatID: UUID = UUID.fromString(chatIDString)

    val client: SandnodeClient = taulight!!.getClient(uuid).client

    val file = getDialogAvatar(client, chatID)
    if (file == null) return mapOf()

    val contentType = file.contentType()
    val body = file.body()

    val base64Avatar = Base64.encodeToString(body, Base64.NO_WRAP)

    return mapOf(
        "contentType" to contentType,
        "avatarBase64" to base64Avatar
    )
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

    val chain: IChain? = declaredConstructor.newInstance(client) as IChain?

    client.io.chainManager.linkChain(chain)
    try {
        val processedParams = params.map { param ->
            if (param is String && uuidRegex.matches(param)) {
                UUID.fromString(param)
            } else {
                param
            }
        }

        val result = method.invoke(chain, *processedParams.toTypedArray())
        return if (result == Unit) {
            null
        } else {
            taulight!!.objectMapper.convertValue(result, Any::class.java)
        }
    } catch (e: InvocationTargetException) {
        throw e.cause ?: e
    } finally {
        client.io.chainManager.removeChain(chain)
    }
}

fun getAvatar(call: MethodCall): Map<String, String> {
    val uuid: String = call.argument<String>("uuid")!!
        val client = taulight!!.getClient(uuid).client

    try {
        val avatar = getAvatar(client)

        if (avatar != null) {
            val mimeType = avatar.contentType()
            val base64 = Base64.encodeToString(avatar.body(), Base64.NO_WRAP)
            return mapOf("contentType" to mimeType, "avatarBase64" to base64)
        }
    } catch (e: Exception) {
        println("Exception: ${e.javaClass.simpleName}")
    }
    return mapOf()
}

fun setAvatar(call: MethodCall): Boolean {
    val uuid: String = call.argument<String>("uuid")!!
    val path: String? = call.argument<String>("path")

    if (path.isNullOrEmpty()) {
        println("Usage: setAvatar <path>")
        return false
    }

    val client = taulight!!.getClient(uuid).client

    try {
        setAvatar(client, path)
        return true
    } catch (e: Exception) {
        println("Exception: ${e.javaClass.simpleName}")
    }

    return false
}
