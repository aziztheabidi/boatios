const xcode = require('xcode');
const fs = require('fs');
const path = require('path');

const projectPath = 'BoatSharingApp.xcodeproj/project.pbxproj';
const myProj = xcode.project(projectPath);

myProj.parseSync();

const pbxFiles = myProj.hash.project.objects.PBXFileReference;
const buildFiles = myProj.hash.project.objects.PBXBuildFile;
const sourcesPhases = myProj.hash.project.objects.PBXSourcesBuildPhase;

// Find main target's sources phase
let mainSourcesPhase;
for (const uuid in sourcesPhases) {
    if (!uuid.endsWith('_comment')) {
        mainSourcesPhase = sourcesPhases[uuid];
        break; // Assuming first one is main target
    }
}

const compiledFileUUIDs = mainSourcesPhase.files.map(f => f.value);

const unlinkedFiles = [];
for (const uuid in pbxFiles) {
    if (!uuid.endsWith('_comment')) {
        const fileRef = pbxFiles[uuid];
        if (fileRef.lastKnownFileType && fileRef.lastKnownFileType.includes('swift')) {
            // Check if this fileRef uuid provides a PBXBuildFile that is in the Sources build phase
            let hasBuildFile = false;
            let buildFileUUID = null;
            for (const buildUUID in buildFiles) {
                if (!buildUUID.endsWith('_comment') && buildFiles[buildUUID].fileRef === uuid) {
                    hasBuildFile = true;
                    buildFileUUID = buildUUID;
                    break;
                }
            }
            
            if (!hasBuildFile || !compiledFileUUIDs.includes(buildFileUUID)) {
                unlinkedFiles.push(fileRef.path || fileRef.name);
            }
        }
    }
}

console.log("--- Files in Project but NOT linked in Target (PBXSourcesBuildPhase) ---");
unlinkedFiles.forEach(f => console.log(f));
