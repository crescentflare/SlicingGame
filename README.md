# Slicing game

An open source project developing a mix of mobile app and game in a framework which stores the app structure in several JSON pages.


## The JSON framework

The app will be built with components and modules which can be inflated from JSON. Together they form JSON pages for building screens. These pages can be shared between iOS and Android when unifying the component properties and layout system.

**Note:** the framework relies on symlinks to share files between the 2 platforms. For MacOS and Linux-based operating systems this will be supported out of the box. Microsoft Windows 10 also supports symlinks, but may require some additional setup in the operating system and GIT client. 


## The development server

Inside the repository there is a NodeJS-based development server which can be used to host the page files for the apps to load (when using the server or hot reloading configuration). After installing NodeJS, start the server from one of the command files (depending on your operating system). This will open a terminal showing which IP-address the server runs on. Place the address (including port) in the browser to verify that it works.

### Enabling the development server in the app

The app contains a debug menu which can be opened by shaking the device (iOS) or long-pressing on the center of the action bar (Android). The menu provides options to specify the URL of the server and where the app loads it pages from. The URL should match the address of the development server. Set the page loading mode to server or to the hotreload server to change pages without restarting the app.

### Hot reloading pages

When the server and apps are configured and hot reloading is enabled, the apps will update the screen almost instantly after a page has been changed (it's also possible to connect multiple devices to the same server). The app will continuously poll the server to check for a page update, and an SHA256 hashing mechanism prevents the page to be updated when there are no changes. The server keeps the connection open until the requested page file is changed or when it times out (which is 10 seconds per request by default).
