Installation & App Configuration
----------------------

### Step 1. Download
- Download the latest [Xcode 11](xcode) app. Version 11 or greater. 
- Download SMART Markers and all its submodules. 
    - Using Git: `$ git clone --recursive https://github.com/SMARTMarkers/smartmarkers-framework-ios`
- Make sure the submodules are downloaded. 
    - [ResearchKit](rk) and [Swift-SMART](ss) required in its entirety

### Step 2. New App setup
- Open Xcode and create a new project with your app preferences (iPhone or iPad or both)
- Add or drag the following files in Xcode's project directory tab along side the app's project. 
    1. `SMARTMarkers.xcodeproj` 
    2. `ResearchKit.xcodeproj`
    3. `Swift-SMART.xcodeproj` 
- Alternatively, multiple apps (xcodeprojects) can be grouped together by in a shared **workspace**  (`.xworkspace`). [Read more](workspace)

### Step 3. Build and Compile
Build and compile all three submodules (SMARTMarkers, ResearchKit, Swift-SMART)

### Step 4. Embedd Framework binaries
View the general tab of the app and select **Target**.  Find the **Embedded Binaries** section and click **+** to add the compiled binaries of the three frameworks.
1. `SMARTMarkers.framework`
2. `ResearchKit.framework` 
3. `SMART.framework`
    
### Step 5. Build & Run App
At this point, the app should be able to compile and run in the iOS simulator. `import SMARTMarkers` into app delegate and compile again.

### Check [Instruments Sample App](sampleapp) to learn more.

[xcode]: https://developer.apple.com/xcode/
[rk]: https://github.com/researchkit/researchkit
[ss]: https://github.com/smart-on-fhir/Swift-SMART
[workspace]: https://developer.apple.com/library/archive/featuredarticles/XcodeConcepts/Concept-Workspace.html
[sampleapp]: #
