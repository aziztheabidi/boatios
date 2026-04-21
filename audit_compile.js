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

const pbxFiles = myProj.hash.project.objects.PBXFileReference;
const buildFiles = myProj.hash.project.objects.PBXBuildFile;
const sourcesPhase = myProj.hash.project.objects.PBXSourcesBuildPhase;

let mainSourcesPhaseId;
for(let k in sourcesPhase) {
    if(!k.endsWith('_comment')) {
        mainSourcesPhaseId = k;
        break;
    }
}

const compiledBuildFileUUIDs = new Set(sourcesPhase[mainSourcesPhaseId].files.map(f => f.value));

// Build a set of fileRef UUIDs that are in the compile target
const compiledFileRefUUIDs = new Set();
for (const buid in buildFiles) {
    if (!buid.endsWith('_comment') && compiledBuildFileUUIDs.has(buid)) {
        compiledFileRefUUIDs.add(buildFiles[buid].fileRef);
    }
}

// Build a map of fileRef UUID -> path for swift files
const compiledPaths = new Set();
for (const uuid in pbxFiles) {
    if (!uuid.endsWith('_comment') && compiledFileRefUUIDs.has(uuid)) {
        let p = pbxFiles[uuid].path || pbxFiles[uuid].name || '';
        if (p.startsWith('"')) p = p.slice(1, -1);
        compiledPaths.add(path.basename(p));
    }
}

const missingFromCompile = diskFiles.filter(diskFile => {
    const baseName = path.basename(diskFile);
    return !compiledPaths.has(baseName);
});

console.log(`Total on disk: ${diskFiles.length}`);
console.log(`Total in compile target: ${compiledPaths.size}`);
console.log(`\n--- Files on disk NOT in compile target (${missingFromCompile.length}) ---`);
missingFromCompile.forEach(f => console.log(f));
