package net.result.taulight.chain

import net.result.sandnode.chain.BSTClientChainManager
import net.result.sandnode.chain.ReceiverChain
import net.result.sandnode.chain.receiver.UnhandledMessageTypeClientChain
import net.result.sandnode.message.util.MessageType
import net.result.taulight.MemberClient
import net.result.taulight.Taulight
import net.result.taulight.chain.client.AndroidForwardClientChain
import net.result.taulight.message.TauMessageTypes

class AndroidClientChainManager(val mc: MemberClient, val taulight: Taulight) : BSTClientChainManager(mc.client) {
    override fun createChain(type: MessageType): ReceiverChain = when (type) {
        TauMessageTypes.FWD -> AndroidForwardClientChain(client, taulight, mc.uuid)
        else -> UnhandledMessageTypeClientChain(client)
    }

}
