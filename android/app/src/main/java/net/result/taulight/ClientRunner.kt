package net.result.taulight

import net.result.sandnode.link.SandnodeLinkRecord
import java.util.*

fun connect(taulight: Taulight, clientID: UUID, link: SandnodeLinkRecord, fetch: Boolean): SandnodeLinkRecord {
    val mc = taulight.addClient(clientID, link, fetch)
    return SandnodeLinkRecord.fromClient(mc.client)
}

fun disconnect(taulight: Taulight, uuid: String) {
    taulight.getClient(uuid).client.close()
}