package net.result.taulight

import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.util.Address
import java.util.UUID

fun connect(taulight: Taulight, clientID: UUID, link: SandnodeLinkRecord): Address {
    taulight.addClient(clientID, link)
    return link.address()
}

fun disconnect(taulight: Taulight, uuid: String) {
    val client = taulight.getClient(uuid).client
    client.close()
}