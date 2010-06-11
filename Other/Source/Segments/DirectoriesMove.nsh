${SegmentFile}

!macro _DirectoriesMove_Start
	${IfThen} $0 != - ${|} StrCpy $0 $DataDirectory\$0 ${|}
	${ParseLocations} $1
!macroend

${SegmentPrePrimary}
	${ForEachINIPair} DirectoriesMove $0 $1
		!insertmacro _DirectoriesMove_Start

		; Backup data from a local installation
		${If} ${FileExists} $1
			${DebugMsg} "Backing up $1 to $1-BackupBy$AppID"
			Rename $1 $1-BackupBy$AppID
		${EndIf}

		; If the key is -, don't move/copy to the target directory.
		; If portable data exists move/copy it to the target directory.
		${If} $0 == -
			CreateDirectory $1
			${DebugMsg} "DirectoriesMove key -, so only creating the directory $1 (no file copy)."
		${ElseIf} ${FileExists} $0\*.*
			; See if the parent local directory exists. If not, create it and
			; note down to delete it at the end if it's empty.
			${GetParent} $1 $4
			${IfNot} ${FileExists} $4
				CreateDirectory $4
				WriteINIStr $DataDirectory\PortableApps.comLauncherRuntimeData-$BaseName.ini DirectoriesMove RemoveIfEmpty:$4 true
			${EndIf}

			${GetRoot} $0 $2 ; compare
			${GetRoot} $1 $3 ; drive
			${If} $2 == $3   ; letters
				${DebugMsg} "Renaming directory $0 to $1"
				Rename $0 $1 ; same volume, rename OK
			${Else}
				${DebugMsg} "Copying $0\*.* to $1\*.*"
				CreateDirectory $1
				CopyFiles /SILENT $0\*.* $1
			${EndIf}
		${Else}
			; Nothing to copy, so just create the directory, ready for use.
			CreateDirectory $1
			${DebugMsg} "$DataDirectory\$0\*.* does not exist, so not copying it to $1.$\r$\n(Note for developers: if you want default data, remember to put files in App\DefaultData\$0)"
		${EndIf}
	${NextINIPair}
!macroend

${SegmentPostPrimary}
	${ForEachINIPair} DirectoriesMove $0 $1
		!insertmacro _DirectoriesMove_Start

		; If the key is "-", don't copy it back
		; Also if not in Live mode, copy the data back to the Data directory.
		${If} $0 == -
			${DebugMsg} "DirectoriesMove key -, so not keeping data from $1."
		${ElseIf} $RunLocally != true
			${GetRoot} $0 $2 ; compare
			${GetRoot} $1 $3 ; drive
			${If} $2 == $3   ; letters
				${DebugMsg} "Renaming directory $1 to $0"
				Rename $1 $0 ; same volume, rename OK
			${ElseIf} ${FileExists} $1
				${DebugMsg} "Copying $1\*.* to $0\*.*"
				RMDir /R $0
				CreateDirectory $0
				CopyFiles /SILENT $1\*.* $0
			${EndIf}
		${EndIf}
		; And then remove it from the runtime location
		${DebugMsg} "Removing portable settings directory from run location ($1)."
		RMDir /R $1

		; If the parent directory we put the directory in locally didn't exist
		; before, delete it if it's empty.
		${GetParent} $1 $4
		ReadINIStr $5 $DataDirectory\PortableApps.comLauncherRuntimeData-$BaseName.ini DirectoriesMove RemoveIfEmpty:$4
		${If} $5 == true
			RMDir $4
		${EndIf}

		; And move that backup of any local data from earlier if it exists.
		${If} ${FileExists} $1-BackupBy$AppID
			${DebugMsg} "Moving local settings from $1-BackupBy$AppID to $1."
			Rename $1-BackupBy$AppID $1
		${EndIf}
	${NextINIPair}
!macroend
