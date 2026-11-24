package cc.picnote.app

import android.app.SearchManager
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cc.picnote.app/gmail")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> result.success(openGmail(call.argument<String>("query")))
                    else -> result.notImplemented()
                }
            }
    }

    /** Opens the Gmail app, searching for [query] when Gmail takes a search
     *  intent, on its inbox otherwise. False when Gmail is not installed. */
    private fun openGmail(query: String?): Boolean {
        if (query != null) {
            val search = Intent(Intent.ACTION_SEARCH)
                .setPackage(GMAIL)
                .putExtra(SearchManager.QUERY, query)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (search.resolveActivity(packageManager) != null && tryStart(search)) return true
        }
        val launch = packageManager.getLaunchIntentForPackage(GMAIL) ?: return false
        return tryStart(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun tryStart(intent: Intent): Boolean = try {
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    private companion object {
        const val GMAIL = "com.google.android.gm"
    }
}
