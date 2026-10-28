# FastBackUp_2.0

**FastBackUp_2.0** is a lightweight Windows backup and restore utility written in Windows Batch and PowerShell. It creates ZIP archives of individual files or folders, splits large archives into smaller parts, and lets you restore data later.

Created by **Bratislav Cvetković**. Distributed under the MIT License; see [LICENSE.txt](LICENSE.txt).

## Features

- Back up an individual file or an entire folder.
- Create ZIP archives using the Windows `tar.exe` utility.
- Verify the ZIP archive before splitting it.
- Split large ZIP archives into parts of approximately 3.5 GiB each, suitable for storage media with file-size limits such as FAT32.
- Join the archive parts when restoring and verify the resulting ZIP archive.
- Choose whether to extract the restored files immediately or keep the joined ZIP for manual extraction.
- Remember the 20 most recent successfully completed operations, including both backups and restores. Select an item to repeat it.
- Store operation history in the current user's local application data folder and write a log to the Windows temporary folder.
- Use Windows folder and file selection dialogs.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell, included with Windows.
- The Windows `tar.exe` utility, normally available at `%WINDIR%\System32\tar.exe`.
- The two program files must remain together in the same folder.

No third-party archiving utility is required by the script.

## Getting started

1. Download or clone this repository, or download the ZIP package from the project's Releases page.
2. Extract the files into a folder.
3. Keep `FastBackUp_2.0.bat` and `FastBackUp_2.0.ps1` in the same folder.
4. Double-click `FastBackUp.bat` to start the program.
5. Choose an option from the menu:
   - **1 — Repeat one of the last 20 operations**
   - **2 — Create a new backup**
   - **3 — Restore data from a backup**
   - **4 — Exit**

## Backup process

1. Select an individual file or a folder.
2. Select the destination folder where the backup should be stored.
3. Choose a location and name for the temporary working folder used to assemble the ZIP archive.
4. Confirm or edit the suggested backup name.
5. FastBackUp creates and verifies a ZIP archive, splits it into numbered parts, and stores the parts and information files in a timestamped backup folder.

The backup folder contains the split archive parts and information files describing the backup. Do not rename or remove individual `.zip.001`, `.zip.002`, and subsequent parts if you intend to restore the archive.

## Restore process

1. Choose the folder containing the split backup archive parts.
2. Select a temporary working folder.
3. FastBackUp joins the parts into a ZIP archive and verifies it.
4. Choose whether to extract the files now. If you choose not to extract, the joined ZIP remains in the temporary working folder for manual extraction.
5. If extracting, select the destination parent folder. FastBackUp creates a subfolder named after the backup.

If the destination subfolder already exists, the program asks before continuing. Review the destination carefully before confirming, especially when restoring important files.

## Operation history

FastBackUp keeps the 20 most recent successfully completed backup and restore operations. The newest operation appears first. When a new operation is saved and the history already contains 20 entries, the oldest **history entry** is removed. This does not delete any backup archive or restored files.

The history file is stored at:

`%LOCALAPPDATA%\FastBackUp\history.json`

The log file is stored at:

`%TEMP%\FastBackUp.log`

History entries store paths used by the operation. Replaying an entry requires the relevant source, backup folder, destination, and temporary folder to still exist. A repeated backup creates a new timestamped backup rather than overwriting the previous backup.

## Important notes

- Keep more than one copy of important data. A backup on the same physical drive as the original data may not protect against drive failure.
- Verify that the selected source and destination are correct before starting an operation.
- Restoring extracts files into a subfolder named after the backup; it does not intentionally extract directly into the selected parent folder.
- The program is provided as-is. Test it with non-critical files before relying on it for important data.
- The script uses the built-in Windows `tar.exe`. Availability and behavior may vary on modified or older Windows installations.

## Files

- `FastBackUp_2.0.bat` — launches the program and displays the main menu.
- `FastBackUp_2.0.ps1` — implements backup, archive splitting, restore, and operation history.
- `README.md` — documentation.
- `LICENSE.txt` — MIT License.

## License

This project is licensed under the MIT License. See [LICENSE.txt](LICENSE.txt) for the full text.
