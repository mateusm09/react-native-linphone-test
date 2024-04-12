package com.linphonetest
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.bridge.WritableMap

import org.linphone.core.*

class LinphoneModule(reactContext: ReactApplicationContext): ReactContextBaseJavaModule(reactContext) {
    override fun getName() = "LinphoneModule"

    private val TAG = "LinphoneModule"
    private var core: Core = Factory.instance().createCore(null, null, reactApplicationContext)

    private val coreListener: CoreListener = object : CoreListenerStub( ) {
        override fun onCallStateChanged(
            core: Core,
            call: Call,
            state: Call.State?,
            message: String
        ) {
            Log.d(TAG, "onCallStateChanged: $state $message")

            val params = Arguments.createMap().apply {
                putString("state", state.toString())
                putString("message", message)
            }
            sendEvent(reactContext, "callstate", params)
        }
    }

    /**
     * React Native Event Emitter
     * */

    private var listenerCount = 0;

    private fun sendEvent(reactContext: ReactApplicationContext, eventName: String, params: WritableMap) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java).emit(eventName, params)
    }

    @ReactMethod fun addListener(_eventName: String) {
        if( listenerCount == 0) core.addListener(coreListener)
        listenerCount += 1;
    }

    @ReactMethod fun removeListener() {
        listenerCount -= 1;
        if( listenerCount == 0) core.removeListener(coreListener)
    }

    @ReactMethod fun removeListeners() {
        listenerCount = 0;
        core.removeListener(coreListener)
    }

    /**
     * End of React native Event Emitter
     * */

    @ReactMethod fun register(username: String, password: String, domain: String, transport: String, promise: Promise) {
        val authInfo = Factory.instance().createAuthInfo(username, null, password, null, null, null);
        val accountParams = core.createAccountParams();

        val identity = Factory.instance().createAddress("sip:${username}@${domain}")
        accountParams.identityAddress = identity;

        val address = Factory.instance().createAddress("sip:${domain}")

        address?.transport = TransportType.valueOf(transport)
        accountParams.serverAddress = address
        accountParams.isRegisterEnabled = true

        val account = core.createAccount(accountParams)
        core.addAuthInfo(authInfo)
        core.addAccount(account)
        core.defaultAccount = account

        val listener = { _: Account, state: RegistrationState, message: String ->
            if (state !== RegistrationState.Ok && state !== RegistrationState.Progress) {
                promise.reject(state.toString(), message)
            } else if (state == RegistrationState.Ok) {
                promise.resolve("Registration successful")
            }
        }

        account.addListener(listener)
        core.start()
    }

    @ReactMethod fun unregister(promise: Promise) {
        val account = core.defaultAccount
        account ?: return

        val params = account.params
        val clonedParams = params.clone()

        clonedParams.isRegisterEnabled = false
        account.params = clonedParams

        account.addListener{ _, state, message ->
            if (state !== RegistrationState.Cleared && state !== RegistrationState.Progress) {
                promise.reject(state.toString(), message)
            } else if (state == RegistrationState.Cleared) {
                promise.resolve("Unregister successful")
            }
        }
    }

    @ReactMethod fun delete(promise: Promise) {
        val account = core.defaultAccount
        account ?: return

        core.removeAccount(account)

        promise.resolve("Delete successful")
    }

    @ReactMethod fun accept() {
        core.currentCall?.accept()
    }

    @ReactMethod fun terminate() {
        core.currentCall?.terminate()
    }

    @ReactMethod fun decline() {
        core.currentCall?.decline(Reason.Declined)
    }

    @ReactMethod fun call(address: String, promise: Promise) {
        val callParams = core.createCallParams(null)
        callParams ?: return promise.reject("Call-creation", "Call params creation failed")

        callParams.mediaEncryption = MediaEncryption.SRTP

        val remoteAddress = Factory.instance().createAddress(address)
        remoteAddress ?: return promise.reject("Call-creation", "Address creation failed")

        val call = core.inviteAddressWithParams(remoteAddress, callParams)

        if (call == null) {
            promise.reject("Call-creation", "Call invite failed")
        } else {
            promise.resolve("Call successful")
        }
    }
}
