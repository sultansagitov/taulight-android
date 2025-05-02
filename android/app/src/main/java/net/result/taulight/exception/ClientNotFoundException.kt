package net.result.taulight.exception

import java.util.UUID

class ClientNotFoundException(uuid: UUID) : Exception(uuid.toString())
