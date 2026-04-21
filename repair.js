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

// 1. Manually identify stale UUIDs for these files
const uuidsToRemove = [];
for (const uuid in pbxFiles) {
    if (!uuid.endsWith('_comment')) {
        const fileRef = pbxFiles[uuid];
        const nameOrPath = fileRef.path || fileRef.name;
        if (nameOrPath) {
            targetFilesToRepair.forEach(targetName => {
                if (nameOrPath.includes(targetName)) {
                     console.log(`Found stale reference to remove: ${nameOrPath} (UUID: ${uuid})`);
                     uuidsToRemove.push({ fileRef: uuid, path: nameOrPath });
                }
            });
        }
    }
}

// Ensure BusinessRepository.swift isn't duplicated
for (const uuid in pbxFiles) {
    if (!uuid.endsWith('_comment')) {
        const fileRef = pbxFiles[uuid];
        const nameOrPath = fileRef.path || fileRef.name;
        if (nameOrPath && nameOrPath.includes('BusinessRepository.swift')) {
             console.log(`Found stale reference to remove: ${nameOrPath} (UUID: ${uuid})`);
             uuidsToRemove.push({ fileRef: uuid, path: nameOrPath });
        }
    }
}

// 2. Erase them from the project AST
uuidsToRemove.forEach(item => {
    // We intentionally don't trust the internal `removeSourceFile` method for broken relative paths
    // So we manually clean up the core structures.
    const fileUuid = item.fileRef;
    
    // Remove from PBXBuildFile
    let buildUuid = null;
    for (const buid in buildFiles) {
        if (!buid.endsWith('_comment') && buildFiles[buid].fileRef === fileUuid) {
            buildUuid = buid;
            delete buildFiles[buid];
            delete buildFiles[buid + '_comment'];
        }
    }
    
    // Remove from Sources Build Phase
    const sources = myProj.hash.project.objects.PBXSourcesBuildPhase;
    for (const sid in sources) {
        if (!sid.endsWith('_comment')) {
            sources[sid].files = sources[sid].files.filter(f => f.value !== buildUuid);
        }
    }
    
    // Remove from groups
    const groups = myProj.hash.project.objects.PBXGroup;
    for (const gid in groups) {
        if (!gid.endsWith('_comment')) {
            groups[gid].children = groups[gid].children.filter(c => c.value !== fileUuid);
        }
    }
    
    // Remove from File References
    delete pbxFiles[fileUuid];
    delete pbxFiles[fileUuid + '_comment'];
});

console.log("Phase 1: Cleanup completed. Proceeding to Phase 2: Restoration.");

// 3. Add them back accurately using their true disk paths
const truePathsToAdd = [
    'BoatSharingApp/Application/Dependency/AppDependencies.swift',
    'BoatSharingApp/Application/NetworkLayer/Core/SessionManager.swift',
    'BoatSharingApp/Application/Storage/TokenStore.swift',
    'BoatSharingApp/Application/Storage/PreferenceStore.swift',
    'BoatSharingApp/Application/State/UIFlowState.swift',
    'BoatSharingApp/Application/Repositories/BusinessRepository.swift'
];

truePathsToAdd.forEach(filePath => {
    console.log(`Adding ${filePath} to target ${targetId}`);
    myProj.addSourceFile(filePath, { target: targetId });
});

// 4. Validate SPM isn't destroyed
const spm = myProj.hash.project.objects.XCRemoteSwiftPackageReference;
console.log("SPM Packages Count:", Object.keys(spm || {}).length / 2);

fs.writeFileSync(projectPath, myProj.writeSync());
console.log("Phase 3: Validation! Saved repaired project successfully.");
