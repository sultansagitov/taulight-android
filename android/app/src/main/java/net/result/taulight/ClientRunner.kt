package net.result.taulight

import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.util.Endpoint
import java.util.UUID

fun connect(taulight: Taulight, clientID: UUID, link: SandnodeLinkRecord): Endpoint {
    taulight.addClient(clientID, link)
    return link.endpoint()
}

fun disconnect(taulight: Taulight, uuid: String) {
    val client = taulight.getClient(uuid).client
    client.close()
}