package com.example.google_places_flutter

import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.AutocompletePrediction
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class GooglePlacesFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler {
    companion object {
        /** Standard Google Maps / Places meta-data name (set in the host app manifest). */
        private const val MANIFEST_API_KEY = "com.google.android.geo.API_KEY"
    }

    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "places_sdk_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "searchPlace" -> handleSearchPlace(call, result)
            "getPlaceDetails" -> handleGetPlaceDetails(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post(block)
        }
    }

    private fun resolveApiKey(argument: String?): String {
        argument?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
        return readApiKeyFromManifest()
    }

    private fun readApiKeyFromManifest(): String {
        return try {
            val appInfo =
                applicationContext.packageManager.getApplicationInfo(
                    applicationContext.packageName,
                    PackageManager.GET_META_DATA,
                )
            appInfo.metaData?.getString(MANIFEST_API_KEY)?.trim().orEmpty()
        } catch (_: Exception) {
            ""
        }
    }

    private fun ensurePlaces(apiKey: String) {
        if (!Places.isInitialized()) {
            Places.initializeWithNewPlacesApiEnabled(applicationContext, apiKey)
        }
    }

    private fun placesClient(apiKey: String): PlacesClient {
        ensurePlaces(apiKey)
        return Places.createClient(applicationContext)
    }

    private fun handleSearchPlace(
        call: MethodCall,
        result: Result,
    ) {
        val query = call.argument<String>("query")?.trim().orEmpty()
        val apiKey = resolveApiKey(call.argument<String>("apiKey"))
        val countryCode = call.argument<String>("countryCode")?.trim()?.uppercase()
        val limit = (call.argument<Number>("limit")?.toInt() ?: 10).coerceIn(1, 20)

        if (query.isEmpty()) {
            result.error("INVALID_ARGUMENT", "query must not be empty", null)
            return
        }
        if (apiKey.isEmpty()) {
            result.error(
                "INVALID_ARGUMENT",
                "apiKey is required: pass apiKey from Dart or set $MANIFEST_API_KEY in AndroidManifest.xml",
                null,
            )
            return
        }

        val builder =
            FindAutocompletePredictionsRequest
                .builder()
                .setQuery(query)
        if (!countryCode.isNullOrEmpty()) {
            builder.setCountries(listOf(countryCode))
        }
        val request = builder.build()

        placesClient(apiKey)
            .findAutocompletePredictions(request)
            .addOnCompleteListener { task ->
                runOnMain {
                    if (task.isSuccessful) {
                        val predictions = task.result?.autocompletePredictions.orEmpty()
                        val out =
                            predictions
                                .take(limit)
                                .map { p -> predictionToMap(p) }
                        result.success(out)
                    } else {
                        val msg = task.exception?.message ?: "Unknown error"
                        result.error("PLACE_SEARCH_FAILED", msg, null)
                    }
                }
            }
    }

    private fun predictionToMap(p: AutocompletePrediction): Map<String, Any?> =
        mapOf(
            "placeId" to p.placeId,
            "primaryText" to p.getPrimaryText(null).toString(),
            "secondaryText" to p.getSecondaryText(null).toString(),
            "fullText" to p.getFullText(null).toString(),
            "types" to (p.types ?: emptyList()),
        )

    private fun handleGetPlaceDetails(
        call: MethodCall,
        result: Result,
    ) {
        val placeId = call.argument<String>("placeId")?.trim().orEmpty()
        val apiKey = resolveApiKey(call.argument<String>("apiKey"))

        if (placeId.isEmpty()) {
            result.error("INVALID_ARGUMENT", "placeId must not be empty", null)
            return
        }
        if (apiKey.isEmpty()) {
            result.error(
                "INVALID_ARGUMENT",
                "apiKey is required: pass apiKey from Dart or set $MANIFEST_API_KEY in AndroidManifest.xml",
                null,
            )
            return
        }

        val fields =
            listOf(
                Place.Field.ID,
                Place.Field.DISPLAY_NAME,
                Place.Field.FORMATTED_ADDRESS,
                Place.Field.LOCATION,
                Place.Field.NATIONAL_PHONE_NUMBER,
                Place.Field.WEBSITE_URI,
                Place.Field.RATING,
                Place.Field.USER_RATING_COUNT,
                Place.Field.OPENING_HOURS,
                Place.Field.BUSINESS_STATUS,
                Place.Field.TYPES,
            )

        val request = FetchPlaceRequest.newInstance(placeId, fields)

        placesClient(apiKey)
            .fetchPlace(request)
            .addOnCompleteListener { task ->
                runOnMain {
                    if (task.isSuccessful) {
                        val place = task.result?.place
                        if (place != null) {
                            result.success(placeToMap(place))
                        } else {
                            result.error("PLACE_DETAILS_EMPTY", "No place in response", null)
                        }
                    } else {
                        val msg = task.exception?.message ?: "Unknown error"
                        result.error("PLACE_DETAILS_FAILED", msg, null)
                    }
                }
            }
    }

    private fun placeToMap(place: Place): Map<String, Any?> {
        val latLng = place.location
        val weekdayText = place.openingHours?.weekdayText

        return mapOf(
            "placeId" to place.id,
            "name" to place.displayName,
            "formattedAddress" to place.formattedAddress,
            "latitude" to latLng?.latitude,
            "longitude" to latLng?.longitude,
            "phoneNumber" to place.nationalPhoneNumber,
            "website" to place.websiteUri?.toString(),
            "rating" to place.rating,
            "userRatingsTotal" to place.userRatingCount,
            "businessStatus" to place.businessStatus?.name,
            "types" to (place.placeTypes ?: emptyList()),
            "weekdayText" to weekdayText,
        )
    }
}
