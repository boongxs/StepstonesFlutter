# Stepstones Media Organizer
Stepstones is a local media organizer built in Flutter. It provides a way for users to manage and
browse their local collections of media files.<br>
Heavily inspired by Hladikes' [Pastery](https://github.com/Hladikes/pastery) project<br><br>
![Screenshot 2026-02-23 231853](https://github.com/user-attachments/assets/f75a5871-0da6-4850-89a8-58b9734ad4ff)

## Features
- **Media Library Management:** Select any folder to act as a media library. The application saves your selection for future sessions.
- **Automatic Data Synchronization:** On startup, the application automatically scans the selected media folder to find new files and cleans up database records for deleted files.
- **Responsive Layout:** A dynamic grid layout that adjusts to your window size, ensuring a clean presentation.
- **Interactive Overlay:** Hovering over any media item reveals an overlay with four commands:
  - **Copy:** Copies the file to the system clipboard, allowing it to be pasted in other applications.
  - **Edit Tags:** Add or edit space-separated tags to organize and easily find your media.
  - **Enlarge:** View media files directly in Stepstones, automatically scaling the enlarged version to fit application window.
  - **Delete:** Permanently delete the file from your disk after a confirmation.
- **Real-time Tag Filtering:** A debounced search bar filters your entire library as you search.
- **Infinite Scrolling:** Browse massive media collections without performance drops. Media items are loaded smoothly and seamlessly as you scroll down the page, keeping memory usage low.
- **Media Bundling:** Select and export multiple media items, along with their associates tags, into a single `.stepstone` package. This portable bundle can be easily backed up or imported to transfer your collection to another computer. 
- **Logs View:** Access a dedicated, built-in application log viewer to monitor background tasks, troubleshoot potential issues, and track the status of file operations in real-time
- **Selection Mode:** Enable multi-select to manage your library in bulk. Quickly highlight multiple media items at once to either batch delete them or package them together into a portable bundle.

## Getting Started
1. Head over to the Releases page.
2. Download the `Stepstones_Setup_v1.0.2_Windows.exe` file from the latest release.
3. Run the installer and follow the on-screen instructions.
