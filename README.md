
# FastBackUp

FastBackUp is a Windows backup and restore utility built with PowerShell and a batch-file launcher. It can create ZIP archives from a selected file or folder, split large archives into numbered parts, and join those parts again when restoring data.

## Features

- Back up a single file or an entire folder.
- Select source files, folders, backup destinations, and temporary locations using Windows dialogs.
- Choose the name of the temporary working folder.
- Create ZIP archives using the Windows `tar.exe` utility.
- Test ZIP archives before splitting them.
- Split large ZIP archives into numbered parts of up to 3.5 GiB each.
- Store archive parts in a dedicated backup folder.
- Join numbered parts into a single ZIP archive during restoration.
- Test the reassembled archive before extraction.
- Extract restored files immediately or keep the ZIP archive for manual extraction.
- Record operations and errors in a log file.
- Display operation results and elapsed time.

## Project Files

Keep these two files in the same directory:

- `FastBackUp.bat` — launches the program and displays the main menu.
- `FastBackUp.ps1` — contains the backup and restore functionality.

The batch file expects `FastBackUp.ps1` to be located in the same directory.

## Requirements

- Windows.
- Windows PowerShell.
- The Windows `tar.exe` utility, normally located at `%WINDIR%\System32\tar.exe`.
- Permission to read the source files and write to the selected backup and temporary locations.

The supplied batch launcher runs PowerShell with `-ExecutionPolicy Bypass` for that invocation. Review the script before running it, especially if it came from an untrusted source.

## Installation

1. Download `FastBackUp.bat` and `FastBackUp.ps1`.
2. Place both files in the same folder.
3. Review the PowerShell script before running it.
4. Double-click `FastBackUp.bat`.

## Main Menu

The program provides three options:

- `1` — Create a backup.
- `2` — Restore data from a backup.
- `3` — Exit.

## Creating a Backup

1. Run `FastBackUp.bat`.
2. Select option `1`.
3. Choose the source type:
   - `1` — Select an individual file.
   - `2` — Select a folder.
   - `3` — Cancel.
4. Use the Windows dialog to select the file or folder.
5. Select the destination folder where the backup folder will be created.
6. Enter a name for the temporary working folder, or keep the suggested name `RezervnaKopijaTemp`.
7. Select the location for the temporary folder.
8. Review the suggested backup name. The default name includes the source name and a timestamp; change it if needed.
9. Wait while the program creates the ZIP archive, tests it, and splits it into numbered parts.
10. When the operation finishes, check the completion message and backup location.

A backup folder contains numbered archive parts, for example:

- `<backup-name>.zip.001`
- `<backup-name>.zip.002`
- Additional numbered parts if necessary.

It also contains:

- `FastBackUp_info.txt` — backup details and timing information.
- `USPEH.txt` — a success marker written after a successful backup.

The temporary ZIP archive is deleted after the archive has been split successfully.

## Restoring a Backup

1. Run `FastBackUp.bat`.
2. Select option `2`.
3. Select the folder that directly contains the numbered archive parts.
4. Enter a name for the temporary working folder, or keep `RezervnaKopijaTemp`.
5. Select the location for the temporary folder.
6. FastBackUp joins the numbered parts into one ZIP archive.
7. The program tests the reassembled ZIP archive.
8. Choose whether to extract the files immediately:
   - **Yes** — select a destination and extract the archive.
   - **No** — leave the joined ZIP file in the temporary folder for manual extraction.
9. If the target restore folder already exists, follow the program's prompt.

The joined ZIP archive remains in the temporary folder after extraction. You can delete it manually when it is no longer needed.

## Archive Parts and FAT32 Storage

FastBackUp splits archives into parts of up to 3.5 GiB (3.5 × 1024³ bytes). This can make large backups easier to store on FAT32-formatted drives, which cannot store a single file larger than 4 GiB.

Keep all numbered parts together. Do not rename, delete, or modify them.

A complete sequence starts with `.zip.001` and continues consecutively, for example:

- `<backup-name>.zip.001`
- `<backup-name>.zip.002`
- `<backup-name>.zip.003`

A missing or damaged part can prevent restoration.

## Logs and Backup Information

The program writes its operation log to:

`%TEMP%\FastBackUp.log`

Each completed backup contains `FastBackUp_info.txt` and `USPEH.txt`.

If an operation fails, check the displayed error message and the log file. Remove personal paths or sensitive information before sharing logs publicly.

## Troubleshooting

### FastBackUp.ps1 cannot be found

Make sure `FastBackUp.bat` and `FastBackUp.ps1` are in the same directory and that the PowerShell file is named exactly `FastBackUp.ps1`.

### The program cannot find tar.exe

Check that `%WINDIR%\System32\tar.exe` exists on your Windows installation.

### The selected backup folder does not contain .zip.001

Select the folder that directly contains the numbered archive parts, not its parent folder.

### The reassembled ZIP archive fails validation

The archive may be incomplete or damaged. Check that every numbered part is present and unchanged. If possible, create a new backup from the original source.

### There is not enough temporary storage

The program creates a complete ZIP archive before splitting it. During restoration, the parts are joined into a single ZIP file before extraction. Make sure the selected temporary location has enough free space.

## Limitations and Safety Notes

- Test restoration periodically, preferably with non-critical files, before relying on a backup for important data.
- FastBackUp does not encrypt or password-protect ZIP archives.
- The current version does not automatically delete older backup folders. Manage backup retention manually.
- The current interface messages are primarily in Serbian.
- Archive creation, testing, and extraction rely on the Windows `tar.exe` utility. Behavior may depend on the Windows version and its bundled utility.
- Keep an additional copy of important data. A backup stored on only one device or drive may be lost if that device fails.

## License

This project is distributed under the MIT License. See the `LICENSE` file for the complete license text.

## Disclaimer

FastBackUp is provided "as is", without warranty of any kind. Use it at your own risk. Test that backups can be restored before relying on them for important data.
