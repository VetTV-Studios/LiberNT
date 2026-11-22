/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * PROJECT:  VetTV Retro OS
 * FILE:     modules/vettv/vetvdm/vetvdm/host_ntvdm.c
 * PURPOSE:  NTVDM fallback command line for vetvdm.exe.
 *
 * Copyright (C) 2026 VetTV
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 */

#include "host.h"

#include "win32.h"

WCHAR *
host_command_ntvdm(const host *st)
{
    WCHAR *cmd;
    WCHAR quoted[MAX_PATH * 2];
    DWORD used = 0;
    const WCHAR *app;

    cmd = (WCHAR *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY,
                            VETVDM_CMDLINE_CCH * sizeof(WCHAR));
    if (!cmd)
        return NULL;
    if (st->cmd.tail && st->cmd.tail[0])
    {
        if (!wappend(cmd, VETVDM_CMDLINE_CCH, &used, st->cmd.tail))
        {
            HeapFree(GetProcessHeap(), 0, cmd);
            return NULL;
        }
        return cmd;
    }
    app = st->image;
    if (vetvdm_quote_win32(app, quoted, MAX_PATH * 2) != VETVDM_OK ||
        !wappend(cmd, VETVDM_CMDLINE_CCH, &used, quoted))
    {
        HeapFree(GetProcessHeap(), 0, cmd);
        return NULL;
    }
    return cmd;
}

/*
 * LiberNT: the NTVDM fallback is only usable when ntvdm.exe exists. LiberNT
 * ships no NTVDM on any arch, and 64-bit NT has no V86 mode at all, so a
 * 64-bit vetvdm.exe (or a 32-bit one under WoW64) never falls back to it.
 * Without this guard vetvdm would re-run the DOS image itself (the hook
 * skips vetvdm.exe) and the amd64 kernel32 would fail it with
 * ERROR_EXE_MACHINE_TYPE_MISMATCH.
 */
typedef BOOL (WINAPI *is_wow64_fn)(HANDLE, PBOOL);

int
host_ntvdm_present(void)
{
    WCHAR path[MAX_PATH];
    UINT n;
    DWORD attr;
    BOOL wow = FALSE;
    is_wow64_fn is_wow64;

    if (sizeof(void *) > 4)
        return 0;
    is_wow64 = (is_wow64_fn)(void *)GetProcAddress(GetModuleHandleW(L"kernel32.dll"),
                                                   "IsWow64Process");
    if (is_wow64 && is_wow64(GetCurrentProcess(), &wow) && wow)
        return 0;
    n = GetSystemDirectoryW(path, MAX_PATH);
    if (!n || n + 11 >= MAX_PATH)
        return 0;
    lstrcatW(path, L"\\ntvdm.exe");
    attr = GetFileAttributesW(path);
    return (attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY)) ? 1 : 0;
}
