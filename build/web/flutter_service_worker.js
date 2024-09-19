'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "bf87385a3e7a9f1c914adc28b391ffec",
"assets/AssetManifest.bin.json": "d97e16133319e349a2c662884fe0c5ec",
"assets/AssetManifest.json": "5d4d5e6c55fab1137a363f89539bc9e7",
"assets/assets/images/arrow_up.png": "4071794cac3c6d02883801165b50d8d8",
"assets/assets/images/backgroundPicture.png": "e22a26ce237d6808f442fb239fceea56",
"assets/assets/images/blogo.png": "ddda767ee53929629972c477363bb21e",
"assets/assets/images/calendar.png": "0587107ddba55236bb7e2f21dc3a1d22",
"assets/assets/images/call.png": "217dabfb1fd1a47a03649b87d7011017",
"assets/assets/images/cameraflip.png": "746016ab3fd3b5ba73c0001fcbe6af66",
"assets/assets/images/capture.png": "440bd6daa01b8187e6a6a31c3a41ee55",
"assets/assets/images/check.png": "69b40f53c8753de22d41cc78ec31e52c",
"assets/assets/images/circle.png": "0ccdd54c15023ff0f66d63146c151e9f",
"assets/assets/images/clock.png": "41fadb4a03008afcc48c2927efb045ba",
"assets/assets/images/clock_seguridad.png": "d43f53fb2555897029e83801efea3f47",
"assets/assets/images/close.png": "a5f99e46f7d6c335c2437656993de6ec",
"assets/assets/images/codigo.png": "20bad1a33cc7cfb71ca5a441c5b7145f",
"assets/assets/images/delivered.png": "ce8409927d1944209daacba71d535f72",
"assets/assets/images/downloading.png": "f812b23212ce937eaeead0d7494f8ce6",
"assets/assets/images/favicon.png": "4f1cb2cac2370cd5050681232e8575a8",
"assets/assets/images/flashauto.png": "0fe0abcdcc107fb64d0c1d1dc2a4f246",
"assets/assets/images/flashoff.png": "3e788169402717a9f68535f3eb98bbc2",
"assets/assets/images/icon.png": "ec2b31eef0b24a67af0270cdd90f6637",
"assets/assets/images/info.png": "aeb7178af567a3fda67984cccf7ca742",
"assets/assets/images/kmh.png": "19fc44818ef6d7aa4e62aefa1a9e09c7",
"assets/assets/images/list.png": "d97da1f5525919b6bcd7edfcbcfc0025",
"assets/assets/images/mapa.png": "02b8c5d79e6cf1fcc44fc8a8914b6683",
"assets/assets/images/notification.png": "70431e149de9426280d55d91c25b929a",
"assets/assets/images/person.png": "9200f5b1ff6aef97b729801a8c0f0507",
"assets/assets/images/pin.png": "45e60530e2f2d5a26b504d1ff5eb36d3",
"assets/assets/images/pin0.png": "b20542d204a31d48fb16e0302084333c",
"assets/assets/images/pin1.png": "dbe4ad96a7a7f7386c69ae27f0792102",
"assets/assets/images/pin2.png": "d050224d55746cf70b40cbb4d4cd0d98",
"assets/assets/images/pin3.png": "595cf4519fe858adf2f1bc6ce4092749",
"assets/assets/images/pin4.png": "60e6276db50ef39b2494c07512a6210b",
"assets/assets/images/pin5.png": "b20542d204a31d48fb16e0302084333c",
"assets/assets/images/pin_my_location.png": "317f88c894f291feec79ab1ad9617cea",
"assets/assets/images/pin_principal.png": "49bf3ebc6ae8f69804b44f818934269f",
"assets/assets/images/reload.png": "f1b0f4b52381975b32a56b349772c383",
"assets/assets/images/share.png": "7a1930e0716df65eef4c86098900873d",
"assets/assets/images/speed_limit.png": "194965addb9a2018412b79150f6f58ab",
"assets/assets/images/splash.png": "8ced40115790b155440de9b18c4bddb4",
"assets/assets/images/stop.png": "a81d121a33d55e0567e14f16fc2a6d09",
"assets/assets/images/store.png": "228943d33739ebbcc6fb7f5d9ad93e1d",
"assets/assets/images/truck64.png": "b09fd1b3d8302ddc50224e57cce5761d",
"assets/assets/images/UltimaMilla.png": "0cc0ff31b5044e8c30a3ff564f9df693",
"assets/assets/images/uncheck.png": "e8dfad4193bb7fa3afb76cdfc61c127c",
"assets/FontManifest.json": "ad1a2b33dc8645a9ec31ed1b1f6b573a",
"assets/fonts/MaterialIcons-Regular.otf": "b0c58ed9227a13860aaa91716ad5b1d4",
"assets/NOTICES": "e3f2e92a32bb0032038e7eea6bdeca65",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "89ed8f4e49bcdfc0b5bfc9b24591e347",
"assets/packages/flutter_feather_icons/fonts/feather.ttf": "40469726c5ed792185741388e68dd9e8",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "c86fbd9e7b17accae76e5ad116583dc4",
"canvaskit/canvaskit.js.symbols": "38cba9233b92472a36ff011dc21c2c9f",
"canvaskit/canvaskit.wasm": "3d2a2d663e8c5111ac61a46367f751ac",
"canvaskit/chromium/canvaskit.js": "43787ac5098c648979c27c13c6f804c3",
"canvaskit/chromium/canvaskit.js.symbols": "4525682ef039faeb11f24f37436dca06",
"canvaskit/chromium/canvaskit.wasm": "f5934e694f12929ed56a671617acd254",
"canvaskit/skwasm.js": "445e9e400085faead4493be2224d95aa",
"canvaskit/skwasm.js.symbols": "741d50ffba71f89345996b0aa8426af8",
"canvaskit/skwasm.wasm": "e42815763c5d05bba43f9d0337fa7d84",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "c71a09214cb6f5f8996a531350400a9a",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "56bd7d7c1a8d54d802305b0c053480d8",
"/": "56bd7d7c1a8d54d802305b0c053480d8",
"main.dart.js": "9281f3ef01b9b437e7d3b0044cc72c99",
"manifest.json": "44263cbdb88ce09d95b12329880b46bb",
"version.json": "3b9e7e2b2e91c663d83f3857c25a0e02"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
