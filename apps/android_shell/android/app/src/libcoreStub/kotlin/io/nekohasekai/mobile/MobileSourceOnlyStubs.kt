package io.nekohasekai.mobile

object Mobile {
    fun touch() = Unit

    fun setup(
        baseDirectory: String,
        workingDirectory: String,
        tempDirectory: String,
        debug: Boolean,
    ) = Unit

    fun parse(finalPath: String, tempPath: String, debug: Boolean) = Unit
}
