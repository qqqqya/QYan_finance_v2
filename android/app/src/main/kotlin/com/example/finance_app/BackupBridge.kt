package com.example.finance_app

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors

class BackupFileProvider : FileProvider()

class BackupBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "finance/backup")
    private val io = Executors.newSingleThreadExecutor()
    private val prefs = activity.getSharedPreferences("backup_io_journal", 0)
    private var pending: MethodChannel.Result? = null
    private var saveBytes: ByteArray? = null
    private var saveName = ""
    private val limit = 32 * 1024 * 1024
    private val shareDir get() = File(activity.cacheDir, "backups_share")
    init {
        io.execute { cleanupInterruptedExport(); expireShares() }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "save" -> {
                    if (pending != null) { result.error("busy", "A file picker is already open", null); return@setMethodCallHandler }
                    val bytes = call.argument<ByteArray>("bytes")
                    val name = call.argument<String>("name")
                    if (bytes == null || name == null || bytes.size > limit) {
                        result.error("backupTooLarge", "Invalid backup size", null); return@setMethodCallHandler
                    }
                    pending = result; saveBytes = bytes; saveName = name
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/octet-stream"
                            putExtra(Intent.EXTRA_TITLE, name)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        }
                        activity.startActivityForResult(intent, 4201)
                    } catch (e: Exception) { pending = null; saveBytes = null; fail(result,e,"fileWrite") }
                }
                "open" -> {
                    if (pending != null) { result.error("busy", "A file picker is already open", null); return@setMethodCallHandler }
                    pending = result
                    try {
                        activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE); type = "*/*"
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        },4202)
                    } catch (e: Exception) { pending = null; fail(result,e,"fileRead") }
                }
                "share" -> io.execute {
                    try {
                        val uri = Uri.parse(call.argument<String>("uri") ?: throw IOException())
                        requireContent(uri)
                        val requested = File(call.argument<String>("name") ?: "backup.moneybak").name
                        val name = requested.ifBlank { "backup.moneybak" }
                        expireShares()
                        shareDir.mkdirs()
                        if ((shareDir.listFiles()?.size ?: 0) >= 10) throw IOException("Share cache full")
                        val file = File(shareDir, UUID.randomUUID().toString() + "_" + name)
                        try { file.outputStream().use { out -> out.write(read(uri)) } }
                        catch (e: Exception) { file.delete(); throw e }
                        val shared = FileProvider.getUriForFile(activity,activity.packageName+".backup_files",file)
                        activity.runOnUiThread {
                            try {
                                val intent = Intent(Intent.ACTION_SEND).apply {
                                    type = "application/octet-stream"
                                    putExtra(Intent.EXTRA_STREAM,shared)
                                    clipData = ClipData.newUri(activity.contentResolver,name,shared)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                activity.startActivity(Intent.createChooser(intent,null))
                                result.success(null) // Means chooser opened, not that a recipient sent it.
                            } catch (e: Exception) { fail(result,e,"fileShare") }
                        }
                    } catch (e: Exception) { activity.runOnUiThread { fail(result,e,"fileShare") } }
                }
                "purge" -> io.execute {
                    try {
                        if (shareDir.exists() && !shareDir.deleteRecursively()) throw IOException()
                        for (permission in activity.contentResolver.persistedUriPermissions) {
                            try { activity.contentResolver.releasePersistableUriPermission(permission.uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION) }
                            catch (_: Exception) { }
                        }
                        activity.runOnUiThread { result.success(null) }
                    } catch (e: Exception) { activity.runOnUiThread { fail(result,e,"cachePurge") } }
                }
                else -> result.notImplemented()
            }
        }
    }
    fun onResult(code: Int, resultCode: Int, data: Intent?) {
        if (code != 4201 && code != 4202) return
        val result = pending ?: return
        pending = null
        val bytes = saveBytes
        saveBytes = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) { result.success(null); return }
        val uri = data.data!!
        io.execute {
            try {
                requireContent(uri)
                if (code == 4202) {
                    val content = read(uri)
                    activity.runOnUiThread { result.success(content) }
                } else {
                    if (bytes == null) throw IOException()
                    val flags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    try { activity.contentResolver.takePersistableUriPermission(uri,flags) } catch (_: SecurityException) { }
                    // ACTION_CREATE_DOCUMENT creates a new document, never overwrites an existing one.
                    if (!prefs.edit().putString("pending_export",uri.toString()).commit()) throw IOException()
                    try {
                        activity.contentResolver.openOutputStream(uri,"wt").use { output ->
                            if (output == null) throw IOException()
                            output.write(bytes); output.flush()
                        }
                        val digest = MessageDigest.getInstance("SHA-256")
                        var verifiedSize = 0
                        activity.contentResolver.openInputStream(uri).use { input ->
                            if(input == null) throw IOException()
                            val chunk = ByteArray(8192)
                            while(true) {
                                val n = input.read(chunk)
                                if(n < 0) break
                                verifiedSize += n
                                if(verifiedSize > limit) throw BackupLimit()
                                digest.update(chunk,0,n)
                            }
                        }
                        if (verifiedSize != bytes.size || !MessageDigest.isEqual(
                            MessageDigest.getInstance("SHA-256").digest(bytes),digest.digest())) throw IOException()
                        if (!prefs.edit().remove("pending_export").commit()) throw IOException()
                    } catch (e: Exception) {
                        try { DocumentsContract.deleteDocument(activity.contentResolver,uri); prefs.edit().remove("pending_export").commit() }
                        catch (_: Exception) { } // Startup retries cleanup; never report success.
                        throw e
                    }
                    val name = displayName(uri) ?: saveName
                    val location = location(uri,name)
                    for (permission in activity.contentResolver.persistedUriPermissions) {
                        if (permission.uri != uri) try {
                            activity.contentResolver.releasePersistableUriPermission(permission.uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                        } catch (_: Exception) { }
                    }
                    activity.runOnUiThread { result.success(mapOf("name" to name,"uri" to uri.toString(),"location" to location,"size" to bytes.size)) }
                }
            } catch (e: Exception) { activity.runOnUiThread { fail(result,e,if(code == 4201) "fileWrite" else "fileRead") } }
        }
    }
    private fun requireContent(uri: Uri) { if(uri.scheme != "content") throw SecurityException() }
    private fun read(uri: Uri): ByteArray {
        activity.contentResolver.openInputStream(uri).use { input ->
            if(input == null) throw IOException()
            val out = ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            var count = 0
            while(true) {
                val n = input.read(buffer)
                if(n < 0) break
                count += n
                if(count > limit) throw BackupLimit()
                out.write(buffer,0,n)
            }
            return out.toByteArray()
        }
    }
    private fun displayName(uri: Uri): String? = try {
        activity.contentResolver.query(uri,arrayOf(OpenableColumns.DISPLAY_NAME),null,null,null)?.use { cursor ->
            if(cursor.moveToFirst()) cursor.getString(0) else null
        }
    } catch (_: Exception) { null }
    private fun location(uri: Uri,name: String): String {
        if(uri.authority == "com.android.externalstorage.documents") try {
            val id = DocumentsContract.getDocumentId(uri)
            return id.substringAfter(':',id)
        } catch (_: Exception) { }
        val provider = activity.packageManager.resolveContentProvider(uri.authority ?: "",0)
        return (provider?.loadLabel(activity.packageManager)?.toString() ?: uri.authority ?: "Documents") + " · " + name
    }
    private fun cleanupInterruptedExport() {
        val raw = prefs.getString("pending_export",null) ?: return
        try {
            DocumentsContract.deleteDocument(activity.contentResolver,Uri.parse(raw))
            prefs.edit().remove("pending_export").commit()
        } catch (_: Exception) { }
    }
    private fun expireShares() {
        shareDir.listFiles()?.filter { System.currentTimeMillis()-it.lastModified() > 24*60*60*1000L }?.forEach { it.delete() }
    }
    private fun fail(result: MethodChannel.Result,e: Exception,fallback: String) {
        val code = when {
            e is BackupLimit -> "backupTooLarge"
            e is SecurityException -> "filePermission"
            e.message?.contains("ENOSPC") == true || e.message?.contains("No space") == true -> "noSpace"
            else -> fallback
        }
        result.error(code,"Backup operation did not complete",null)
    }
    private class BackupLimit : IOException()
}
