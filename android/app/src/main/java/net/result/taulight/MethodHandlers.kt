package net.result.taulight

import android.annotation.TargetApi
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.result.sandnode.exception.error.SandnodeErrorException
import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.serverclient.SandnodeClient
import net.result.sandnode.util.IOController
import net.result.taulight.exception.ClientNotFoundException
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MethodHandlers(flutterEngine: FlutterEngine) {
    companion object {
        private val LOGGER: Logger = LogManager.getLogger(MethodHandlers::class.java)
    }

    private val methodHandlerMap: Map<String, (MethodCall) -> Any>
    private val taulight: Taulight

    private val executorService: ExecutorService

    private val runner: Runner

    init {
        executorService = Executors.newCachedThreadPool()

        val binaryMessenger: BinaryMessenger = flutterEngine.getDartExecutor().getBinaryMessenger()
        val CHANNEL: String = "net.result.taulight/messenger"

        val methodChannel: MethodChannel = MethodChannel(binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(this::onMethodCallHandler)

        taulight = Taulight(methodChannel)

        runner = Runner(taulight)

        methodHandlerMap = HashMap<String, (MethodCall) -> Any>()
        methodHandlerMap.put("connect", this::connect)
        methodHandlerMap.put("login", this::login)
        methodHandlerMap.put("register", this::register)
        methodHandlerMap.put("disconnect", this::disconnect)
        methodHandlerMap.put("send", this::send)
        methodHandlerMap.put("group", this::groupAdd)
        methodHandlerMap.put("get-chats", this::getChats)
        methodHandlerMap.put("load-messages", this::loadMessages)
        methodHandlerMap.put("load-clients", this::loadClient)
        methodHandlerMap.put("load-chat", this::loadChat)
        methodHandlerMap.put("create-channel", this::createChannel)
        methodHandlerMap.put("members", this::members)
        methodHandlerMap.put("add-member", this::addMember)
        methodHandlerMap.put("token", this::token)
        methodHandlerMap.put("check-code", this::checkCode)
        methodHandlerMap.put("use-code", this::useCode)
        methodHandlerMap.put("dialog", this::dialog)
        methodHandlerMap.put("leave", this::leave)
        methodHandlerMap.put("channel-codes", this::channelCodes)
        methodHandlerMap.put("react", this::react)
        methodHandlerMap.put("unreact", this::unreact)
    }

    @TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun onMethodCallHandler(call: MethodCall, result: MethodChannel.Result) {
        executorService.execute(java.lang.Runnable {
            val handler = methodHandlerMap.get(call.method)
            if (handler != null) {
                taulight.clients.entries.removeIf{ (uuid, mc) -> !mc.client.io.isConnected() }

                try {
                    val res: Any = handler(call)
                    result.success(mapOf("success" to res))
                } catch (e: SandnodeErrorException) {
                    result.success(mapOf(
                        "error" to mapOf(
                            "name" to e.javaClass.getSimpleName(),
                            "message" to e.message
                        )
                    ))
                } catch (e: java.lang.Exception) {
                    LOGGER.error("Unhandled", e)
                    result.success(mapOf(
                        "error" to mapOf(
                            "name" to e.javaClass.getSimpleName(),
                            "message" to e.message
                        )
                    ))
                }
            } else result.error("UNAVAILABLE", "Unknown method type", call.method)
        })
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun members(call: MethodCall): Any {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDStr: String = call.argument<String>("chat-id")!!

        val client: SandnodeClient = taulight.getClient(uuid).client
        val chatID: UUID = UUID.fromString(chatIDStr)

        return runner.members(client, chatID)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun connect(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val linkString: String = call.argument<String>("link")!!

        val link: SandnodeLinkRecord = net.result.sandnode.link.Links.parse(linkString)

        val clientID: UUID = UUID.fromString(uuid)

        return runner.connect(clientID, link)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun login(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val nickname: String = call.argument<String>("nickname")!!
        val password: String = call.argument<String>("password")!!

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.login(client, nickname, password)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun register(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val nickname: String = call.argument<String>("nickname")!!
        val password: String = call.argument<String>("password")!!

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.register(client, nickname, password)
    }

    @kotlin.Throws(ClientNotFoundException::class)
    private fun disconnect(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        return runner.disconnect(uuid)
    }

    @TargetApi(Build.VERSION_CODES.N)
    @kotlin.Throws(java.lang.Exception::class)
    private fun send(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val chatID: String = call.argument<String>("chat-id")!!
        val content: String = call.argument<String>("content")!!
        val repliedToMessagesString: List<String> =
            call.argument<List<String>>("repliedToMessages")!!

        val replies: Set<UUID> = repliedToMessagesString.map { UUID.fromString(it) }.toSet()

        val mc: MemberClient = taulight.getClient(uuid)
        val io: IOController = mc.client.io

        return runner.send(io, chatID, content, replies)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun groupAdd(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val group: String = call.argument<String>("group")!!

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.groupAdd(client, group)
    }

    /** @noinspection rawtypes*/
    @TargetApi(Build.VERSION_CODES.TIRAMISU)
    @kotlin.Throws(java.lang.Exception::class)
    private fun getChats(call: MethodCall): List<*> {
        val uuid: String = call.argument<String>("uuid")!!
        val client: SandnodeClient = taulight.getClient(uuid).client
        return runner.getChats(client)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun loadMessages(call: MethodCall): Map<String, Any> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatID_str: String = call.argument<String>("chat-id")!!
        val index: Int = call.argument<Int>("index")!!
        val size: Int = call.argument<Int>("size")!!

        val client: SandnodeClient = taulight.getClient(uuid).client
        val chatID: UUID = UUID.fromString(chatID_str)

        return runner.loadMessages(client, chatID, index, size)
    }

    @TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun loadClient(ignoredCall: MethodCall): List<Map<String, String>?> {
        return runner.loadClient()
    }

    @TargetApi(Build.VERSION_CODES.N)
    @kotlin.Throws(java.lang.Exception::class)
    private fun loadChat(call: MethodCall): Any {
        val uuid: String = call.argument<String>("uuid")!!
        val chat: String = call.argument<String>("chat-id")!!

        val chatID: UUID = UUID.fromString(chat)
        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.loadChat(client, chatID)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun createChannel(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val title: String = call.argument<String>("title")!!

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.createChannel(client, title)
    }

    @TargetApi(Build.VERSION_CODES.O)
    @kotlin.Throws(java.lang.Exception::class)
    private fun addMember(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDString: String = call.argument<String>("chat-id")!!
        val otherNickname: String = call.argument<String>("nickname")!!

        val chatID: UUID = UUID.fromString(chatIDString)

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.addMember(client, chatID, otherNickname)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun token(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val token: String = call.argument<String>("token")!!
        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.token(client, token)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun checkCode(call: MethodCall): Any {
        val uuid: String = call.argument<String>("uuid")!!
        val code: String = call.argument<String>("code")!!
        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.checkCode(client, code)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun useCode(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val code: String = call.argument<String>("code")!!

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.useCode(client, code)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun dialog(call: MethodCall): Map<String, String> {
        val uuid: String = call.argument<String>("uuid")!!
        val nickname: String = call.argument<String>("nickname")!!

        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.dialog(client, nickname)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun leave(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDStr: String = call.argument<String>("chat-id")!!

        val chatID: UUID = UUID.fromString(chatIDStr)
        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.leave(client, chatID)
    }

    /** @noinspection rawtypes
     */
    @TargetApi(Build.VERSION_CODES.N)
    @kotlin.Throws(java.lang.Exception::class)
    private fun channelCodes(call: MethodCall): List<*> {
        val uuid: String = call.argument<String>("uuid")!!
        val chatIDStr: String = call.argument<String>("chat-id")!!

        val chatID: UUID = UUID.fromString(chatIDStr)
        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.channelCodes(client, chatID)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun react(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val messageIDStr: String = call.argument<String>("message-id")!!
        val reactionType: String = call.argument<String>("reaction-type")!!

        val messageID: UUID = UUID.fromString(messageIDStr)
        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.react(client, messageID, reactionType)
    }

    @kotlin.Throws(java.lang.Exception::class)
    private fun unreact(call: MethodCall): String {
        val uuid: String = call.argument<String>("uuid")!!
        val messageIDStr: String = call.argument<String>("message-id")!!
        val reactionType: String = call.argument<String>("reaction-type")!!

        val messageID: UUID = UUID.fromString(messageIDStr)
        val client: SandnodeClient = taulight.getClient(uuid).client

        return runner.unreact(client, messageID, reactionType)
    }
}