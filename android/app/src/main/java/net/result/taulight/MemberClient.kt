package net.result.taulight

import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.serverclient.SandnodeClient

class MemberClient(val client: SandnodeClient, val link: SandnodeLinkRecord) {
    var nickname: String? = null
}
