# Nevus App - Technical Documentation

A comprehensive Flutter application designed to help people track and monitor their moles over time. The app allows users to take photos, identify individual moles, create a history of changes for each mole, and locate mole positions on a human figure for comprehensive tracking.

## 🎯 Features

- **Photo Management**: Take and store photos in a private gallery accessible only through the app
- **Mole Tracking**: Identify and track individual moles with detailed annotations
- **Campaign System**: Organize photos by date into campaigns for systematic monitoring
- **Spot Annotations**: Mark and annotate specific moles on photos with size and position data
- **User Management**: Support for multiple user accounts with secure local storage
- **Fitzpatrick Scale Integration**: Built-in skin type assessment for personalized risk evaluation
- **Export Functionality**: Export mole data and photos for medical consultations
- **Metadata Extraction**: Automatic extraction of photo metadata including capture date

## 🏗️ Architecture

### Data Models

- **Photo**: Core data structure containing image path, capture date, body region, and spot annotations
- **Mole**: Individual mole entities with unique IDs, descriptions, and tracking history
- **Campaign**: Time-based groupings of photos for systematic monitoring
- **Spot**: Annotations on photos that mark mole locations with size and position data
- **User**: User account information with secure local storage

### Directory Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── campaign.dart
│   ├── mole.dart
│   ├── photo.dart
│   ├── spot.dart
│   └── user.dart
├── screens/                  # UI screens
│   ├── auth_screen.dart
│   ├── camera_screen.dart
│   ├── campaigns_screen.dart
│   ├── campaign_detail_screen.dart
│   ├── edit_account_screen.dart
│   ├── fitzpatrick_info_screen.dart
│   ├── home_screen.dart
│   ├── mole_detail_screen.dart
│   ├── mole_list_screen.dart
│   ├── photo_gallery_screen.dart
│   └── single_photo_screen.dart
├── services/                 # Business logic services
│   ├── campaign_service.dart
│   ├── export_service.dart
│   └── photo_metadata_service.dart
├── storage/                  # Data persistence
│   ├── campaign_storage.dart
│   ├── photo_storage.dart
│   └── user_storage.dart
├── utils/                    # Utility functions
│   └── dialog_utils.dart
└── widgets/                  # Reusable UI components
    ├── app_bar_title.dart
    ├── interactive_photo_viewer.dart
    ├── mark_mode_controls.dart
    ├── photo_grid_item.dart
    ├── photo_info_panel.dart
    └── spot_widget.dart
```

## 🛠️ Technical Stack

- **Framework**: Flutter 3.8.1+
- **Language**: Dart
- **Storage**: Local JSON files with structured data organization
- **Camera**: Native camera integration with metadata extraction
- **Image Processing**: Support for EXIF data extraction and photo manipulation
- **File Management**: Secure local file system storage

### Key Dependencies

- `camera`: Device camera access and photo capture
- `image_picker`: Alternative photo selection methods
- `path_provider`: File system path management
- `file_picker`: File selection capabilities
- `share_plus`: Data export and sharing functionality
- `exif`: Photo metadata extraction
- `intl`: Date formatting and internationalization
- `archive`: Data compression for exports

## Data Model
Each user has a personal folder named after the user where all data is stored. When a user doesn't log in, the account will be managed as a guest user and the data will be stored in a folder named "guest". The image data inside each user folder is organized in campaign folders (all photos relative to one campaign are stored in the same campaign folder).
All data is stored in JSON files that are loaded and saved when entering or exiting a screen. The JSON files are stored directly inside the user folder.

/app_documents/
└── users/
    ├── guest/
    │   ├── photos.json
    │   ├── campaigns.json
    │   ├── moles.json
    │   └── campaigns/
    │       ├── campaign_001/
    │       │   ├── photo1.jpg
    │       │   └── photo2.jpg
    │       └── campaign_002/
    └── john_doe/
        ├── photos.json
        ├── campaigns.json
        ├── moles.json
        └── campaigns/
            └── campaign_001/
            
### Photo
Photos are linked to only one campaign. Each image can contain more than one mole and has a list of spots that identify each mole and its position. Each photo contains a description that identifies which region of the body the picture represents.

### Spot
Spots are annotations on a specific photo that highlight moles. Each spot contains information about the mole it identifies, such as an ID, its position, and its size.

### Campaign
Campaigns are linked to a date and represent the group of photos taken at a specific moment (day, week) to track your moles.

### Mole
Every mole has a unique ID, a short string that describes it, a long description, and an automatic method that retrieves all the photos where it appears.

### User
User accounts store personal information and preferences, with support for multiple accounts on the same device.

## 📱 User Interface Screens

### Authentication Screen (auth_screen)
From here you can access the app: there is a box where you need to insert your username and password and then a button to log in. If you don't have an account yet, there's a "plus" button in the top right corner of the screen. From here you'll get to another page where you can create your first account or another one.

#### Add or Edit an Account
Here you can create your first account or add a new one, but also modify an already existing account. As a matter of fact, the app lets you handle multiple accounts on the same device. Also, all the data given to Nevus is strictly kept inside the app, avoiding that your private information might get released to public platforms. You can access this page from the "plus" button in the log in screen, or from the menu, clicking "edit account". In this page you'll find a box that asks for some personal information, such as gender, age etc., but also for a username and password. At the end of the page there's a save/create button, depending on whether you are adding or modifying an account.

### Home Screen (home_screen)
Here you see an image of a human figure, where in the future you'll be able to place the pictures of your moles. In this way every user will be able to create an accessible map of their moles, which will surely help with tracking. Additionally, in the homepage there are two buttons: one to access the camera and one to access the gallery, where all the photos are stored. Here you can also find the most recent campaigns that have been created. To see all campaigns there's a specific button; with another button you can go to the mole list.

### Campaign List (campaigns_screen)
Here you have a list of all the campaigns that have ever been created by a user.

### Camera Screen (camera_screen)
On this page you can take pictures that will show up in the gallery. Once you shoot a photo, a message will appear saying: "Picture saved!", along with a button that will transfer you to the gallery screen. If an image can't be taken, another message will appear saying: "Error taking picture".

### Campaign Detail Screen (campaign_detail_screen)
Here you will find all the images that were taken, unless they were deleted. You can click on the photos to see some info, like when the picture was taken and the name of the picture. By default, the images' names are all blank, but you can modify them by clicking on a button called: "Edit name".

#### Single Photo Screen (single_photo_screen)
Here you can see some information about a single photo, like the date when the picture was taken or all the annotations. On this page you can add and edit the spots that highlight the moles.

### Mole List Screen (mole_list_screen)
Here are all the moles, with a representative image and key characteristic information used to distinguish one mole from another.

### Mole Detail Screen (mole_detail_screen)
Here there's a focus on a single mole: on this page you can find all the information and annotations regarding a single mole.

## 🔒 Privacy & Security

- All data is stored locally on the device
- No cloud storage or external data transmission
- Private photo gallery separate from device's main photo library
- User account data encrypted and stored securely
- Support for guest accounts for anonymous usage

## 📊 Data Organization

```
/app_documents/
└── users/
    ├── guest/
    │   ├── photos.json
    │   ├── campaigns.json
    │   ├── moles.json
    │   └── campaigns/
    │       ├── campaign_001/
    │       │   ├── photo1.jpg
    │       │   └── photo2.jpg
    │       └── campaign_002/
    └── [username]/
        ├── photos.json
        ├── campaigns.json
        ├── moles.json
        └── campaigns/
            └── campaign_001/
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK compatible with Flutter version
- Android Studio / Xcode for mobile deployment
- Device with camera capability

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure platform-specific settings if needed
4. Run `flutter run` to launch the application

### Building

- **Android**: `flutter build apk` or `flutter build appbundle`
- **iOS**: `flutter build ios`
- **Other platforms**: See Flutter documentation for specific build commands

## ⚠️ Medical Disclaimer

This application is designed for tracking and documentation purposes only. It does not provide medical diagnosis or replace professional medical advice. Users should:

- Consult healthcare providers for medical concerns
- Follow dermatologist recommendations for mole monitoring
- Use this app as a supplementary tool, not a medical device
- Seek immediate medical attention for concerning changes in moles

## 🤝 Contributing

This is a personal project for mole tracking and monitoring. For questions or suggestions, please refer to the documentation or contact the maintainer.