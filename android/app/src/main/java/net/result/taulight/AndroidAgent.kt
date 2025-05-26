package net.result.taulight

import net.result.sandnode.encryption.KeyStorageRegistry
import net.result.taulight.hubagent.TauAgent
import java.util.*

class AndroidAgent(val taulight: Taulight, val uuid: UUID) : TauAgent(KeyStorageRegistry()) {

    override fun close() {
        taulight.sendToFlutter("disconnect", mapOf("uuid" to uuid.toString()))
    }
}
