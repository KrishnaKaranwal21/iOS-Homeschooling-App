#!/usr/bin/env python3
"""Refresh full-project and feature ZIP snapshots from the current source checkout."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib
import subprocess

root = Path(__file__).resolve().parent.parent
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
branch = subprocess.check_output(['git', 'branch', '--show-current'], cwd=root, text=True).strip()
source_note = (f'Source branch: {branch}\nSource commit: {commit}\n'
               'Progress UI: Day / Week / Month, including archived weeks\n'
               'Home UI: daily tasks, automatic saving and animated completion\n'
               'This is a ZIP snapshot. Prefer the repository source for ongoing development.\n').encode()


def source_files(directory):
    return [p for p in sorted((root / directory).rglob('*')) if p.is_file() and p.suffix != '.pyc'
            and not any(part.startswith('.') or part in ('xcuserdata', '__pycache__') for part in p.relative_to(root).parts)]


def refresh(name, prefix, mode):
    archive = root / 'Exports' / name
    # Preserve the existing feature bundle's integration layout and explanatory README.
    with ZipFile(archive) as old:
        payload = {n[len(prefix):]: old.read(n) for n in old.namelist()
                   if n.startswith(prefix) and not n.endswith('/')}
    if mode == 'full':
        payload = {n: data for n, data in payload.items() if n == 'README-EXPORT.md'}
        for directory in ['Homeschool', 'Homeschool.xcodeproj', 'Scripts', 'Tests', 'DesignNotes']:
            for path in source_files(directory):
                payload[path.relative_to(root).as_posix()] = path.read_bytes()
        if b'IOS_SIMULATOR_ID can select' not in payload['README-EXPORT.md']:
            payload['README-EXPORT.md'] += (b'\nThe shell checks use the iOS simulator SDK. Boot a simulator first; '
                                      b'IOS_SIMULATOR_ID can select a particular simulator.\n')
    else:
        included = set()
        for name_in_bundle in list(payload):
            for marker in ['Homeschool/', 'Scripts/', 'Tests/', 'DesignNotes/']:
                if '/' + marker in '/' + name_in_bundle:
                    relative = marker + name_in_bundle.split(marker, 1)[1]
                    path = root / relative
                    if path.is_file():
                        payload[name_in_bundle] = path.read_bytes()
                        included.add(relative)
                    else:
                        del payload[name_in_bundle]
                    break
        for directory in ['Homeschool/Core', 'Homeschool/Features/Home', 'Tests', 'Scripts']:
            for path in source_files(directory):
                relative = path.relative_to(root).as_posix()
                if relative in included:
                    continue
                section = 'SupportingSource/' if mode == 'progress' else 'Source/'
                if '/Features/Home/' in relative:
                    section = 'IntegrationReferences/'
                payload[section + relative] = path.read_bytes()
                included.add(relative)
        if b'Local chats, hosted events and attachment bytes now persist' not in payload['README.md']:
            payload['README.md'] += (b'\nLocal chats, hosted events and attachment bytes now persist on device. '
                                 b'Current shared services are included as integration references. '
                                 b'The full project remains the recommended runnable app.\n')
    payload['EXPORT-SOURCE.txt'] = source_note
    payload.pop('SHA256SUMS.txt', None)
    payload['SHA256SUMS.txt'] = ''.join(
        f'{hashlib.sha256(data).hexdigest()}  {name}\n' for name, data in sorted(payload.items())
    ).encode()
    temporary = archive.with_suffix('.zip.tmp')
    with ZipFile(temporary, 'w', compression=ZIP_DEFLATED, compresslevel=9) as output:
        for name, data in sorted(payload.items()):
            info = ZipInfo(prefix + name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            output.writestr(info, data)
    temporary.replace(archive)
    print(f'Refreshed {archive.name}: {len(payload)} files, source {commit[:7]}')


if __name__ == '__main__':
    refresh('HomeSchool-App.zip', 'HomeSchool-App/', 'full')
    refresh('Progress-Section.zip', 'ProgressSection/', 'progress')
    refresh('Gather-Section.zip', 'GatherSection/', 'gather')
