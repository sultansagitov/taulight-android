package net.result.taulight

import net.result.sandnode.encryption.KeyStorageRegistry
import net.result.taulight.hubagent.TauAgent
import java.util.*

class AndroidAgent(keyStorageRegistry: KeyStorageRegistry, val taulight: Taulight, val uuid: UUID)
        : TauAgent(keyStorageRegistry) {

    override fun close() {
        taulight.sendToFlutter("disconnect", mapOf("uuid" to uuid.toString()))
    }
}
