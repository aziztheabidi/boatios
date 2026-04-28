const xcode = require('xcode');
const fs = require('fs');
const path = require('path');

const projectPath = 'BoatSharingApp.xcodeproj/project.pbxproj';
const myProj = xcode.project(projectPath);

myProj.parseSync();

function getAllSwiftFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const filePath = path.join(dir, file);
    if (fs.statSync(filePath).isDirectory()) {
      if (!filePath.includes('.xcassets') && !filePath.includes('.xcodeproj') && !filePath.includes('node_modules')) {
        getAllSwiftFiles(filePath, fileList);
      }
    } else {
      if (file.endsWith('.swift')) {
        fileList.push(filePath.replace(/\\/g, '/'));
      }
    }
  }
  return fileList;
}

const diskFiles = getAllSwiftFiles('BoatSharingApp');
const pbxObject = myProj.hash.project.objects.PBXFileReference;
const buildFiles = myProj.hash.project.objects.PBXBuildFile;
const sourcesPhase = myProj.hash.project.objects.PBXSourcesBuildPhase;

let mainSourcesPhaseId;
for(let k in sourcesPhase) {
    if(!k.endsWith('_comment')) {
        mainSourcesPhaseId = k;
        break; // usually first one is main
    }
}

const compiledFileUUIDs = sourcesPhase[mainSourcesPhaseId].files.map(f => f.value);

const pathsLinkedToCompile = [];
for (const uuid in pbxObject) {
    if (!uuid.endsWith('_comment')) {
        const fileRef = pbxObject[uuid];
        if (fileRef.lastKnownFileType && fileRef.lastKnownFileType.includes('swift')) {
            let hasBuildFile = false;
            let buildFileUUID = null;
            for (const buildUUID in buildFiles) {
                if (!buildUUID.endsWith('_comment') && buildFiles[buildUUID].fileRef === uuid) {
                    hasBuildFile = true;
                    buildFileUUID = buildUUID;
                    break;
                }
            }
            if (hasBuildFile && compiledFileUUIDs.includes(buildFileUUID)) {
                let p = fileRef.path || fileRef.name;
                if(p.startsWith('"')) p = p.slice(1,-1);
                pathsLinkedToCompile.push(p);
            }
        }
    }
}

const untrackedSwiftFiles = diskFiles.filter(diskFile => {
    const fileName = path.basename(diskFile);
    return !pathsLinkedToCompile.some(compiledPath => compiledPath.endsWith(fileName));
});

console.log(JSON.stringify(untrackedSwiftFiles, null, 2));
