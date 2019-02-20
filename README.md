# 🌎🐶 LocDog
iPhone fake location tool for cheating in PokemonGO and alike, debugging your location-based apps or fooling NSA.
Based on [this project](https://github.com/gbmksquare/Pokemon-GO-Controller-for-Mac)
Woof-woof!

## Description
To use the tool you would need Xcode installed and have a free Apple Developer account from developer.apple.com

### The suite consists of 4 parts:
1. *Walker* macOS app
2. *Locator* iOS app
3. GPX file
4. The Script

#### Walker
It's a macOS app used to control the simulated location. 
Use arrows to control your movement and right-click for plotting routes.
Hit space bar to start/stop route.
Use Follow button to make the camera follow your movement.
![Screenshot](https://i.imgur.com/lHBb3Hx.png)

#### Locator
Locator is the app you need to install to your iPhone for the simulation to work.
It will be used as a proxy app to push location updates to the device.
All the apps will be affected, so you may as well fake your location for Apple services like Find Friends or Find my iPhone.

#### GPX file
The GPX file is a simple XML file used by Xcode to simulate the location.
This file is shared by Walker and Locator. Walker writes to it, then Xcode reads from it and pushes the location with Locator.

#### The Script
It's a simple Apple Script file for automating location updates.
Basically, every time a change occures in the GPX file, you have to manually go to *Debug* -> *Simulate Location* and select *Simulated Location.gpx* in *Xcode*. By playing this script macOS would do it for you.

## Usage
1. Clone or download this repository
2. Open *Walker.xcworkspac*e, select your developer credentials in the project's file General tab (usual steps)
3. Do the same for *Locator.xcworkspace* ( + select your device as a target )
4. Run *Walker*, make it find your location or point it manually by right-clicking and selecting "Teleport Here"
5. In the **Walker window**, slightly change your location by using arrow keys or right-click 
6. Run *Locator*, wait untill it loads.
7. In the **Locator window**, go to *Debug* -> *Simulate Location* and select *Simulated Locatin.gpx* (use Add GPX File.. and browse to the root folder if there's no such item)
8. Make sure that *Locator* is running and your iPhone using the location you pointed in step 4
9. Repeat step 5 and 7 to watch the location change and get the feel of it
10. In the root folder, open and run *Continuous Location Simulation.scpt* and **make sure Locator window is topmost in Xcode** (you would probably have to allow Script Editor to Accessibility control in system settings)
11. Switch to *Walker* app, now the location will be continuosly updated automagically. If it stops working, make sure Locator is running and its window is topmost in Xcode. Unfortunately, AppleScript does not allow automating action in menu bars of unfocused windows.
12. Finally, rejoice!
