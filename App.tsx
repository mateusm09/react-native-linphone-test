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
import {accept, callEvents, register, unregister} from './linphone';

function App(): React.JSX.Element {
  const [calling, setCalling] = React.useState(false);
  const [registered, setRegistered] = React.useState(false);

  useEffect(() => {
    PermissionsAndroid.requestMultiple([
      'android.permission.RECORD_AUDIO',
      'android.permission.USE_SIP',
    ]);

    register({
      username: 'mateus',
      password: 'password',
      domain: 'testes.mindtech.com.br',
    })
      .then(res => {
        console.log('register', res);

        setRegistered(true);
      })
      .catch(err => {
        console.log('error', err);
      });
  }, []);

  useEffect(() => {
    let sub: EventSubscription;

    if (registered) {
      sub = callEvents.addListener('callstate', event => {
        console.log('[JS] event', event);

        if (event?.state === 'IncomingReceived') {
          setCalling(true);
        }
      });
    }

    return () => {
      sub?.remove();
    };
  }, [registered]);

  return (
    <View>
      {calling ? <Button title="Accept" onPress={() => accept()} /> : false}
    </View>
  );
}

const styles = StyleSheet.create({});

export default App;
