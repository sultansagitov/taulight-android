package net.result.taulight.exception

import java.util.*

class ClientNotFoundException(uuid: UUID) : Exception(uuid.toString())
