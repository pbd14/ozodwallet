// package com.ozod.wallet.ozodwallet
// import android.os.Bundle
// import com.google.firebase.FirebaseApp
// import com.google.firebase.appcheck.FirebaseAppCheck;
// import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
// import io.flutter.embedding.android.FlutterActivity

// class MainActivity: FlutterActivity() {
//     override fun onCreate(savedInstanceState: Bundle?) {
//         FirebaseApp.initializeApp(/*context=*/this)
//         val firebaseAppCheck = FirebaseAppCheck.getInstance()
//         firebaseAppCheck.installAppCheckProviderFactory(
//             PlayIntegrityAppCheckProviderFactory.getInstance()
//         )
//         super.onCreate(savedInstanceState)
//     }

    
// }

package com.ozod.wallet.ozodwallet
import android.os.Bundle
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck;
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        FirebaseApp.initializeApp(/*context=*/this)
        val firebaseAppCheck = FirebaseAppCheck.getInstance()
        firebaseAppCheck.installAppCheckProviderFactory(
            DebugAppCheckProviderFactory.getInstance()
        )
        super.onCreate(savedInstanceState)
    }

    
}
