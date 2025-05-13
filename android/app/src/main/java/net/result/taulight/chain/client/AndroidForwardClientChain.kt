package net.result.taulight.chain.client

import android.os.Build
import androidx.annotation.RequiresApi
import net.result.sandnode.util.IOController
import net.result.taulight.chain.receiver.ForwardClientChain
import net.result.taulight.dto.ChatMessageViewDTO
import net.result.taulight.message.types.ForwardResponse
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger

class AndroidForwardClientChain(
    io: IOController,
    val onMessage: (ChatMessageViewDTO, Boolean) -> Unit
) : ForwardClientChain(io) {

    companion object {
        private val LOGGER: Logger = LogManager.getLogger(AndroidForwardClientChain::class.java)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onMessage(response: ForwardResponse) {
        LOGGER.info(response)
        val message: ChatMessageViewDTO = response.serverMessage
        onMessage(message, response.isYourSession)
    }
}
