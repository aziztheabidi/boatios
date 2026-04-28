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

const pbxFiles = [];
for (const uuid in pbxObject) {
    if (!uuid.endsWith('_comment')) {
        let nameOrPath = pbxObject[uuid].path || pbxObject[uuid].name;
        if (nameOrPath && nameOrPath.startsWith('"')) {
             nameOrPath = nameOrPath.slice(1, -1);
        }
        if (nameOrPath && nameOrPath.endsWith('.swift')) {
            pbxFiles.push(nameOrPath);
        }
    }
}

console.log("--- Missing in PBXProj (On Disk but not in project) ---");
const missingInProj = diskFiles.filter(diskFile => {
    const fileName = path.basename(diskFile);
    return !pbxFiles.some(pbx => pbx.endsWith(fileName));
});
missingInProj.forEach(f => console.log(f));

console.log("\n--- Stale in PBXProj (In project but not on Disk) ---");
const staleInProj = pbxFiles.filter(pbxFile => {
    const fileName = path.basename(pbxFile);
    return !diskFiles.some(disk => disk.endsWith(fileName));
});
staleInProj.forEach(f => console.log(f));
