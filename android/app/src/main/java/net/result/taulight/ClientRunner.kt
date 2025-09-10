package net.result.taulight

import net.result.sandnode.link.SandnodeLinkRecord
import java.util.*

fun connect(taulight: Taulight, clientID: UUID, link: SandnodeLinkRecord) {
    taulight.addClient(clientID, link)
}

fun disconnect(taulight: Taulight, uuid: String) {
    taulight.getClient(uuid).client.close()
}