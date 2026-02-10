# React Native + Expo Stack Module

> Framework-specific knowledge for React Native projects using Expo SDK 54+. Add to your project's `debugging.md` or `tech-stack.md`.

## Project Structure

### Expo Router (File-based routing)

```
app/
  _layout.tsx          → Root layout (navigation container)
  index.tsx            → Home screen (/)
  (tabs)/
    _layout.tsx        → Tab navigator layout
    home.tsx           → Tab screen
    profile.tsx        → Tab screen
  [id].tsx             → Dynamic route (/123)
  (auth)/
    login.tsx          → Grouped route (no URL segment for "auth")
    register.tsx
```

### Managed vs Bare Workflow

| Aspect | Managed (Expo Go / EAS) | Bare (expo prebuild) |
|--------|-------------------------|----------------------|
| Native code access | No (unless using dev client) | Yes |
| Build process | EAS Build or `expo export` | `npx expo run:ios/android` |
| When to eject | Need custom native module | Starting with bare is fine too |
| Config | `app.json` / `app.config.js` | `app.json` + native project files |

**Recommendation:** Start with managed workflow. Use `expo-dev-client` when you need custom native modules instead of fully ejecting.

## Metro Bundler Cache Issues

**The #1 debugging step for unexplainable React Native errors is clearing the Metro cache.**

```bash
# Clear Metro cache
npx expo start --clear

# Nuclear option: clear everything
rm -rf node_modules .expo
npm install
npx expo start --clear

# If using yarn
rm -rf node_modules .expo
yarn install
npx expo start --clear
```

### When to Clear Cache

- After installing/removing a native module
- After changing `babel.config.js` or `metro.config.js`
- When you see "Unable to resolve module" for a module that clearly exists
- After switching branches with different dependencies
- When the app shows stale code that you've already changed
- Unexplainable red screen errors that don't match your current code

## Path Aliases

### Setup with TypeScript

```javascript
// babel.config.js
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      ['module-resolver', {
        alias: {
          '@': './src',
          '@components': './src/components',
          '@utils': './src/utils',
        },
      }],
    ],
  };
};
```

```json
// tsconfig.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@utils/*": ["src/utils/*"]
    }
  }
}
```

**Gotcha:** Both `babel.config.js` AND `tsconfig.json` must be updated. TypeScript handles type checking, Babel handles actual resolution. If you only update one, you'll get errors in the other system.

**Gotcha:** After changing `babel.config.js`, you MUST restart Metro with `--clear` flag.

## Reanimated Setup

React Native Reanimated requires a Babel plugin and specific setup:

```javascript
// babel.config.js
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      // Other plugins...
      'react-native-reanimated/plugin', // MUST be last
    ],
  };
};
```

### Common Reanimated Errors

**`Error: Reanimated 2 failed to create a worklet...`**
- The Babel plugin is missing or not last in the plugins array
- Fix: Add plugin as the LAST entry, clear Metro cache

**`TypeError: _ReanimatedModule.default.installCoreFunctions is not a function`**
- Version mismatch between Reanimated and Expo SDK
- Fix: Use the version specified by your Expo SDK: `npx expo install react-native-reanimated`

**`Cannot read property 'installCoreFunctions' of undefined` on web**
- Reanimated web support needs extra config
- Fix: Ensure `react-native-reanimated/plugin` is in babel config, then clear cache

### Worklet Rules

```typescript
// Functions run on the UI thread must be worklets
const animatedStyle = useAnimatedStyle(() => {
  // This runs on UI thread - no JS thread access
  return {
    transform: [{ translateX: offset.value }],
  };
}); // Automatically becomes a worklet via the plugin

// Explicit worklet annotation
function myHelper(value: number) {
  'worklet';
  return value * 2;
}
```

**Gotcha:** Worklets cannot access regular JavaScript closures, state, or call non-worklet functions. They can only access shared values (`.value`) and other worklets.

## Native Module Linking

### Auto-linking (Expo SDK 54+)

Most modules auto-link. After installing:

```bash
npx expo install [package-name]   # Ensures compatible version
npx expo prebuild --clean          # Regenerates native projects (bare workflow)
```

### When Auto-linking Fails

1. Check the package supports your Expo SDK version
2. Check for required config plugins in `app.json`:
   ```json
   {
     "expo": {
       "plugins": [
         ["expo-camera", { "cameraPermission": "Allow camera access" }],
         ["expo-location", { "locationAlwaysPermission": "Allow location access" }]
       ]
     }
   }
   ```
3. For bare workflow: `cd ios && pod install && cd ..`

### Config Plugins (Expo)

Config plugins modify native project files at build time without touching native code directly:

```javascript
// app.config.js
export default {
  expo: {
    plugins: [
      ['expo-build-properties', {
        ios: { deploymentTarget: '15.0' },
        android: { compileSdkVersion: 34 },
      }],
    ],
  },
};
```

## OTA Updates

### EAS Update

```bash
# Publish an update
eas update --branch production --message "Fix login bug"

# Check update status
eas update:list
```

### Update Gotchas

- OTA updates can only change **JavaScript and assets** — native code changes require a new build
- If you add a new native module, you MUST create a new build (OTA won't work)
- Updates are branch-based — make sure you're updating the correct branch
- Test updates on a staging branch before pushing to production

### Runtime Version Strategy

```json
{
  "expo": {
    "runtimeVersion": {
      "policy": "appVersion"
    }
  }
}
```

Use `appVersion` policy for most apps. Switch to `sdkVersion` or a custom policy only if you need fine-grained control.

## Platform-Specific Code

### File-based

```
Button.tsx              → Default (both platforms)
Button.ios.tsx          → iOS only
Button.android.tsx      → Android only
Button.web.tsx          → Web only
```

Metro automatically resolves the correct file per platform.

### Inline

```typescript
import { Platform } from 'react-native';

const styles = StyleSheet.create({
  container: {
    paddingTop: Platform.OS === 'ios' ? 44 : 0,
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 2 } },
      android: { elevation: 4 },
      web: { boxShadow: '0 2px 4px rgba(0,0,0,0.1)' },
    }),
  },
});
```

## Debugging

### Expo Dev Tools

- **Shake device** or **Ctrl+M (Android) / Cmd+D (iOS)** → Open dev menu
- **React DevTools:** `npx react-devtools` in a separate terminal
- **Network inspector:** Enable in dev menu (Expo SDK 49+)

### Flipper (Bare workflow)

```bash
# Flipper is being deprecated in favor of Expo's built-in tools
# For new projects, use Expo dev tools instead
# For existing Flipper setups:
brew install --cask flipper  # macOS
```

### Console Logging

```typescript
// Logs appear in terminal running Metro
console.log('Debug value:', someValue);

// For objects, JSON.stringify for readability
console.log('State:', JSON.stringify(state, null, 2));
```

**Gotcha:** `console.log` in production significantly impacts performance. Use `__DEV__` guard:

```typescript
if (__DEV__) {
  console.log('Debug info');
}
```

## Common Crash Patterns

### `Invariant Violation: View config getter callback for component "X" must be a function`
- A native component isn't linked properly
- Fix: `npx expo install [package]`, then rebuild native app

### `Error: Cannot find native module 'ExpoModulesCore'`
- Expo modules not installed or linked
- Fix: `npx expo install expo-modules-core`, then rebuild

### `com.facebook.react.bridge.ReadableNativeMap cannot be cast to...` (Android)
- Passing wrong prop types to a native component
- Fix: Check prop types match what the native component expects

### `[TypeError: Network request failed]`
- iOS blocks HTTP (non-HTTPS) by default (App Transport Security)
- Android 9+ blocks cleartext traffic by default
- Fix: Use HTTPS, or configure exceptions in `app.json`:
  ```json
  {
    "expo": {
      "ios": { "infoPlist": { "NSAppTransportSecurity": { "NSAllowsArbitraryLoads": true } } },
      "android": { "usesCleartextTraffic": true }
    }
  }
  ```

### Blank White Screen (no error)
1. Check Metro terminal for errors
2. Shake device to open dev menu — is the dev menu working?
3. Clear Metro cache: `npx expo start --clear`
4. Check that your root layout/entry point is exporting a component

### `EMFILE: too many open files` (macOS)
```bash
# Install watchman
brew install watchman

# Or increase file limit
ulimit -n 4096
```

### Navigation/Routing Errors

**`Error: Couldn't find a navigation object`**
- Using navigation hooks outside of a navigator
- Fix: Ensure the component is rendered inside a `NavigationContainer` or Expo Router layout

**Screen flickers or renders twice**
- Usually caused by multiple navigation containers
- Fix: Only one `NavigationContainer` (Expo Router handles this automatically)

## Performance Tips

### FlatList Optimization

```typescript
<FlatList
  data={items}
  renderItem={renderItem}
  keyExtractor={(item) => item.id}
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
  maxToRenderPerBatch={10}
  windowSize={5}
  removeClippedSubviews={true}
/>
```

### Image Optimization

```bash
npx expo install expo-image
```

```typescript
// Use expo-image instead of React Native's Image
import { Image } from 'expo-image';

<Image
  source={uri}
  contentFit="cover"
  placeholder={blurhash}
  transition={200}
/>
```

### Avoid Anonymous Functions in Render

```typescript
// BAD: Creates new function every render
<Button onPress={() => handlePress(item.id)} />

// GOOD: Memoized or extracted
const handlePress = useCallback((id) => { ... }, []);
```

## Environment Variables

```bash
# .env
EXPO_PUBLIC_API_URL=https://api.example.com
SECRET_KEY=not-exposed-to-client
```

- `EXPO_PUBLIC_` prefix makes variables available in client code (similar to `NEXT_PUBLIC_`)
- Variables are inlined at build time
- After changing `.env`, restart Metro with `--clear`
