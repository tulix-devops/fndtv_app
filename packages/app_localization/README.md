### Usage

Now localization package's getters became non nullable. In order to get localization message you type:

```dart
context.s.localizationName,
```
You will switch `localizationName` with desired localization name

### How to install
Open ```pubspec.yaml``` file and enter following line under dependecies:

```yaml
  taw_localization:
    path: ../taw_localization
```    

### How to re-generate
First, you need to navigate to application directory(Skip if you are in application directory): 

```
cd src/insurance_app
```

In order to re-generate localization you can run command:

```
make loc
```

### Where is new keys must be added
New keys will be entered to files **`app_ar.arb`** and **`app_en.arb`**

This files located in `src/insurance_app/packages/taw_localization/lib/l10n` folder

