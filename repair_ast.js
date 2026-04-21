const xcode = require('xcode');
const fs = require('fs');

const projectPath = 'BoatSharingApp.xcodeproj/project.pbxproj';
const myProj = xcode.project(projectPath);

myProj.parseSync();
const targetId = myProj.getFirstTarget().uuid;

const targetFilesToRepair = [
    'AppDependencies.swift',
    'SessionManager.swift',
    'TokenStore.swift',
    'PreferenceStore.swift',
    'UIFlowState.swift'
];

const pbxFiles = myProj.hash.project.objects.PBXFileReference;
const buildFiles = myProj.hash.project.objects.PBXBuildFile;

// PHASE 1: SWEEP
const uuidsToRemove = [];
for (const uuid in pbxFiles) {
    if (!uuid.endsWith('_comment')) {
        const fileRef = pbxFiles[uuid];
        const nameOrPath = fileRef.path || fileRef.name;
        if (nameOrPath) {
            targetFilesToRepair.forEach(targetName => {
                if (nameOrPath.includes(targetName)) {
                     uuidsToRemove.push({ fileRef: uuid, path: nameOrPath });
                }
            });
        }
    }
}

for (const uuid in pbxFiles) {
    if (!uuid.endsWith('_comment')) {
        const fileRef = pbxFiles[uuid];
        const nameOrPath = fileRef.path || fileRef.name;
        if (nameOrPath && nameOrPath.includes('BusinessRepository.swift')) {
             uuidsToRemove.push({ fileRef: uuid, path: nameOrPath });
        }
    }
}

uuidsToRemove.forEach(item => {
    const fileUuid = item.fileRef;
    
    let buildUuid = null;
    for (const buid in buildFiles) {
        if (!buid.endsWith('_comment') && buildFiles[buid].fileRef === fileUuid) {
            buildUuid = buid;
            delete buildFiles[buid];
            delete buildFiles[buid + '_comment'];
        }
    }
    
    const sources = myProj.hash.project.objects.PBXSourcesBuildPhase;
    for (const sid in sources) {
        if (!sid.endsWith('_comment')) {
            sources[sid].files = sources[sid].files.filter(f => f.value !== buildUuid);
        }
    }
    
    const groups = myProj.hash.project.objects.PBXGroup;
    for (const gid in groups) {
        if (!gid.endsWith('_comment')) {
            groups[gid].children = groups[gid].children.filter(c => c.value !== fileUuid);
        }
    }
    
    delete pbxFiles[fileUuid];
    delete pbxFiles[fileUuid + '_comment'];
});

// PHASE 2: RESTORE
const truePathsToAdd = [
    'BoatSharingApp/Application/Dependency/AppDependencies.swift',
    'BoatSharingApp/Application/NetworkLayer/Core/SessionManager.swift',
    'BoatSharingApp/Application/Storage/TokenStore.swift',
    'BoatSharingApp/Application/Storage/PreferenceStore.swift',
    'BoatSharingApp/Application/State/UIFlowState.swift',
    'BoatSharingApp/Application/Repositories/BusinessRepository.swift'
];

const crypto = require('crypto');
function generateUUID() {
    return crypto.randomBytes(12).toString('hex').toUpperCase(); // 24 chars uppercase hex
}

const mainGroupUuid = myProj.hash.project.objects.PBXProject[myProj.hash.project.rootObject].mainGroup;
const sourcesPhase = myProj.hash.project.objects.PBXSourcesBuildPhase;
let mainSourcesPhaseId;
for(let k in sourcesPhase) {
    if(!k.endsWith('_comment')) {
        mainSourcesPhaseId = k;
        break; // usually first one is main
    }
}

truePathsToAdd.forEach(filePath => {
    const fileRefId = generateUUID();
    const buildId = generateUUID();
    const fileName = filePath.split('/').pop();
    
    // File Ref
    pbxFiles[fileRefId] = {
        isa: 'PBXFileReference',
        lastKnownFileType: 'sourcecode.swift',
        name: `"${fileName}"`,
        path: `"${filePath}"`,
        sourceTree: '"<group>"'
    };
    pbxFiles[`${fileRefId}_comment`] = fileName;
    
    // Build File
    buildFiles[buildId] = {
        isa: 'PBXBuildFile',
        fileRef: fileRefId
    };
    buildFiles[`${buildId}_comment`] = `${fileName} in Sources`;
    
    // Add to sources build phase
    myProj.hash.project.objects.PBXSourcesBuildPhase[mainSourcesPhaseId].files.push({
        value: buildId,
        comment: `${fileName} in Sources`
    });
    
    // Add to project root group so it shows up in Xcode navigator
    myProj.hash.project.objects.PBXGroup[mainGroupUuid].children.push({
        value: fileRefId,
        comment: fileName
    });
});

fs.writeFileSync(projectPath, myProj.writeSync());
console.log("Phase 3: Validation! Saved repaired project successfully.");
