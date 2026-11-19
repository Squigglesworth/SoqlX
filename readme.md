# SoqlX

SoqlX is a tool for developers using the Salesforce.com platform, it allows you to easily explore your schema,
write and run SOQL queries, make edits to data, and to run Apex code.


![schema viewer](https://www.pocketsoap.com/osx/soqlx/help/schema.png)


## In-app help

* **Completions show reference text.** The autocomplete popup has a documentation pane under the list: keywords,
  operators and date literals get a short description, functions show their signature, and fields, objects and
  relationships show their describe info (label, type, picklist values, help text, formula).
* **Hover in the schema viewer.** Resting the mouse on a field or an object title in the schema view shows the same
  describe info as a tooltip.
* **Query snippets.** `Query > Insert Snippet` has a library of starting points (relationships, aggregates, date
  literals, paging, SOSL, and so on). `{SObject}` in a snippet is replaced with the object selected in the sidebar.
  `Edit My Snippets…` creates `~/Library/Application Support/SoqlX/snippets.json` where you can add your own;
  it is re-read every time the menu opens. The format is the same as `AppExplorer/snippets.json`.

## Download

You can download the builds of the latest version of SoqlX from its [homepage](https://superfell.com/osx/soqlx/)

  
## Build

ZKSforce and Sparkle are managed via [Cocoa Pods](https://cocoapods.org), you'll need to run `pod install` once you've cloned
this repo. Fragaria is pulled in via git submodules, so you need to clone this repo, and fetch the submodules.

```bash
    git clone --recurse-submodules https://github.com/superfell/SoqlX
    pod install
    
    # or the long way.
    git clone https://github.com/superfell/SoqlX.git SoqlX
    cd SoqlX
    git submodule init
    git submodule update
    pod install
```

Now you can open the project in XCode, remember to open the workspace created by Cocoa Pods.
It requires a current Xcode and targets macOS 12 or later.

The Fragaria submodule still declares a 10.10 deployment target, which recent Xcode versions
reject, so from the command line pass the override:

```bash
    xcodebuild -workspace AppExplorer.xcworkspace -scheme SoqlXplorer build CODE_SIGN_IDENTITY=- MACOSX_DEPLOYMENT_TARGET=12.0
```

To build, re-sign and launch the Debug app in one step (the re-sign is needed because the
prebuilt Sparkle framework's signature doesn't match an ad hoc signed app):

```bash
    scripts/run-debug.sh
```

Building the SoqlXplorer target will build the dependencies, then SoqlX. You may find that the first
build of Fragaria fails with a "Command PhaseScriptExecution failed" error, just hit build again, and
this error goes away.

You should be able to run the built version of SoqlX at this point.
