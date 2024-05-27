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
  FlatList,
  PermissionsAndroid,
  Platform,
  SafeAreaView,
  StyleSheet,
  View,
} from 'react-native';
import {
  accept,
  call,
  callEvents,
  decline,
  getAudioDevices,
  register,
  setAudioDevice,
  terminate,
  useOutputAudioDevices,
} from './linphone';

function App(): React.JSX.Element {
  const [calling, setCalling] = React.useState(false);
  const [registered, setRegistered] = React.useState(false);
  const [active, setActive] = React.useState(false);

  const {devices, current} = useOutputAudioDevices();

  async function initLinphone() {
    try {
      await register({
        username: 'mateus',
        password: 'password',
        domain: '192.168.4.3',
      });

      console.log('register');
      setRegistered(true);
    } catch (error) {
      console.error('REGISTRATION ERROR', error);
    }
  }

  useEffect(() => {
    if (Platform.OS === 'android') {
      PermissionsAndroid.requestMultiple([
        'android.permission.RECORD_AUDIO',
        'android.permission.USE_SIP',
      ]);
    }

    initLinphone();
  }, []);

  useEffect(() => {
    let sub: EventSubscription;

    if (registered) {
      console.log('sub to events');
      // getAudioDevices().then(console.log);

      sub = callEvents.addListener('callstate', event => {
        console.log('[JS] event', event);

        if (event?.state === 'IncomingReceived') {
          setCalling(true);
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
      <SafeAreaView>
        <Button title="Accept" onPress={() => accept()} />
        <Button title="Decline" onPress={() => decline()} />
      </SafeAreaView>
    );
  }

  if (active) {
    return (
      <SafeAreaView>
        <Button title="Hangup" onPress={() => terminate()} />
        <FlatList
          data={devices}
          renderItem={({item, index}) => (
            <Button
              title={item.name}
              key={index}
              onPress={() => setAudioDevice(item.id)}
            />
          )}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView>
      <View>
        <Button title="Call" onPress={() => call('sip:teste@192.168.4.3')} />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({});

export default App;
