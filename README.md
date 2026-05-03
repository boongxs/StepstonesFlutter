# Stepstones Media Organizer
Stepstones is a local media organizer built in Flutter. It provides a way for users to manage and
browse their local collections of media files.<br>
Heavily inspired by Hladikes' [Pastery](https://github.com/Hladikes/pastery) project<br><br>
<img width="1917" height="1001" alt="Screenshot 2026-05-03 163423" src="https://github.com/user-attachments/assets/f19a4751-48da-4a1a-9af0-fd071b479749" />


## Features
- **Media Library Management:** Select any folder to act as a media library. The application saves your selection for future sessions.
- **Automatic Data Synchronization:** On startup, the application automatically scans the selected media folder to find new files and cleans up database records for deleted files.
- **Responsive Layout:** A dynamic grid layout that adjusts to your window size, ensuring a clean presentation.
- **Interactive Overlay:** Hovering over any media item reveals an overlay with four commands:
  - **Copy:** Copies the file to the system clipboard, allowing it to be pasted in other applications.
  - **Enlarge:** View media files directly in Stepstones, automatically scaling the enlarged version to fit application window.
  - **Delete:** Permanently delete the file from your disk after a confirmation.
- **Infinite Scrolling:** Browse massive media collections without performance drops. Media items are loaded smoothly and seamlessly as you scroll down the page, keeping memory usage low.
- **Media Bundling:** Select and export multiple media items, along with their associated tags, into a single `.stepstone` package. This portable bundle can be easily backed up or imported to transfer your collection to another computer. 
- **Logs View:** Access a dedicated, built-in application log viewer to monitor background tasks, troubleshoot potential issues, and track the status of file operations in real-time
- **Selection Mode:** Enable multi-select to manage your library in bulk. Quickly highlight multiple media items at once to either batch delete them or package them together into a portable bundle.
- **Tag Editing:** Assign space-separated tags to any media item directly from the Enlarge view. You can then use the search bar to filter your library by tags, quickly finding the file you're looking for.
- **Duplicate Detection:** When a newly added file is visually similar to an existing one, you can then inspect the pair side by side and choose whether to keep or discard.

## Installation
Download the latest installer from the [Releases](../../releases/latest) page.
