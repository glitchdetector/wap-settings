# Webadmin Settings Menu

![](https://puu.sh/ECSC4.png)

A flexible settings panel for controlling console variables (convars).

Allows resources to define their own list of entries for the panel.

![](https://puu.sh/ECSwG.png)

## Features

 - Support for most (if not all) types of console variables
 - Security in place to prevent unauthorized access
 - Security in place to prevent unauthorized changes
 - Security in place to prevent changes if the user does not have required permission levels
 - Custom entries added by resource file
 - Custom entries added by resource manifest
 - Ability to show entries based on origin resource
 - Ability to show entries based on origin file in resource

 And more

## Download
https://github.com/glitchdetector/wap-settings

## Dependency
https://forum.fivem.net/t/release-api-webadmin-lua-plugin-factory/865295

## Developers Note

### Entry definitions

#### Heading / Category
![](https://puu.sh/ECSzI.png)
```
Title[, Subtitle]
```
Appears as a header / category separator

#### Boolean
![](https://puu.sh/ECSzx.png)
```
Title, Convar, "CV_BOOL", Default[, Label]
```
True / False input in the form of a checkbox

#### Number Input (Manual)
![](https://puu.sh/ECSzO.png)
```
Title, Convar, "CV_INT", Default[, Min, Max]
```
Manual number input with optional minimum and maximum

#### Number Input (Slider)
![](https://puu.sh/ECSzS.png)
```
Title, Convar, "CV_SLIDER", Default, Min, Max
```
Slider number input

#### Number Input (Slider & Manual)
![](https://puu.sh/ECSzX.png)
```
Title, Convar, "CV_COMBI", Default, Min, Max
```
Number input with slider and manual input

#### Text Input
![](https://puu.sh/ECSA2.png)
```
Title, Convar, "CV_STRING", Default
```
Normal text input

#### Text Input (Hidden)
![](https://puu.sh/ECSBf.png)
```
Title, Convar, "CV_PASSWORD", Default
```
Masked text input

#### Dropdown Selection
![](https://puu.sh/ECSAF.png)
```
Title, Convar, "CV_MULTI", Items[{name, value}]
```
A drop-down selection menu
The first entry in Items is the default value
Automatically selects the current convar value if it appears in the list

### Adding entries



There are two methods to add entries:

#### Resource File (JSON)
Create a json file in your resource with the following structure:
```
[
    ["Title", "Subtitle"],
    ["Text", "my_text_entry", "CV_STRING", "Default"],
    ...
]
```
Now add your file as a `convar_json` entry. (f.ex: `convar_json 'my_convars.json'`)

#### Resource Manifest (LUA)
You can also add the entries directly in your manifest file!
The same structure is used, but you can use a Lua table instead:
```
convar_category 'Title' {
    'Subtitle',
    {
        {"Text", "my_text_entry", "CV_STRING", "Default"},
        ...
    }
}
```
