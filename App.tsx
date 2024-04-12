/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useEffect} from 'react';
import {
  Button,
  EventSubscription,
  PermissionsAndroid,
  StyleSheet,
  View,
} from 'react-native';
import {
  accept,
  call,
  callEvents,
  decline,
  register,
  terminate,
} from './linphone';
import RNCallKeep from 'react-native-callkeep';

function App(): React.JSX.Element {
  const [calling, setCalling] = React.useState(false);
  const [registered, setRegistered] = React.useState(false);
  const [active, setActive] = React.useState(false);

  async function initLinphone() {
    try {
      await register({
        username: 'mateus',
        password: 'password',
        domain: 'testes.mindtech.com.br',
      });

      console.log('register');
      setRegistered(true);
    } catch (error) {
      console.error('REGISTRATION ERROR', error);
    }
  }

  function initCallkeep() {
    RNCallKeep.setup({
      android: {
        alertTitle: 'Permissions required',
        alertDescription:
          'This application needs to access your phone accounts',
        cancelButton: 'Cancel',
        okButton: 'ok',
        additionalPermissions: [],
      },
      ios: {
        appName: 'LinhponeTest',
      },
    });

    RNCallKeep.setAvailable(true);

    RNCallKeep.addEventListener('answerCall', accept);
    RNCallKeep.addEventListener('endCall', terminate);
    RNCallKeep.addEventListener('didDisplayIncomingCall', event => {
      console.log(event);
    });
    RNCallKeep.addEventListener('createIncomingConnectionFailed', event => {
      console.log(event);
    });
  }

  useEffect(() => {
    PermissionsAndroid.requestMultiple([
      'android.permission.RECORD_AUDIO',
      'android.permission.USE_SIP',
    ]);

    initLinphone().then(initCallkeep);
  }, []);

  useEffect(() => {
    let sub: EventSubscription;

    if (registered) {
      console.log('sub to events');

      sub = callEvents.addListener('callstate', event => {
        console.log('[JS] event', event);

        if (event?.state === 'IncomingReceived') {
          setCalling(true);

          RNCallKeep.displayIncomingCall(
            '123',
            'mateus',
            'mateus',
            'generic',
            false,
          );
        } else if (event?.state === 'End') {
          setCalling(false);
          setActive(false);
        } else if (event?.state === 'Connected') {
          setActive(true);
        }
      });
    }

    return () => {
      sub?.remove();
    };
  }, [registered]);

  if (calling) {
    return (
      <View>
        <Button title="Accept" onPress={() => accept()} />
        <Button title="Decline" onPress={() => decline()} />
      </View>
    );
  }

  if (active) {
    return (
      <View>
        <Button title="Hangup" onPress={() => terminate()} />
      </View>
    );
  }

  return (
    <View>
      <Button
        title="Call"
        onPress={() => call('sip:mateus2@testes.mindtech.com.br')}
      />
    </View>
  );
}

const styles = StyleSheet.create({});

export default App;
