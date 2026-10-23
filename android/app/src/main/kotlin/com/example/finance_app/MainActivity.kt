package com.example.finance_app

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var backups: BackupBridge? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        backups = BackupBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
    @Deprecated("Android activity result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        backups?.onResult(requestCode, resultCode, data)
    }
}
