package net.result.taulight

import android.os.Build
import androidx.annotation.RequiresApi

import net.result.sandnode.link.SandnodeLinkRecord
import net.result.sandnode.serverclient.SandnodeClient

import java.util.Optional

class MemberClient(val client: SandnodeClient, val link: SandnodeLinkRecord) {
    var nickname: String? = null
}
