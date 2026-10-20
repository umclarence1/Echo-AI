import fs from 'node:fs/promises';
import {FileBlob,PresentationFile} from '@oai/artifact-tool';
const p=await PresentationFile.importPptx(await FileBlob.load('C:/Users/Papa Offei/Downloads/ICAST/ICAST2026_Presentation_Template_.pptx'));
await fs.mkdir('.icast-build/template',{recursive:true});
console.log((await p.inspect({kind:'layout',maxChars:12000})).ndjson);
for(let i=0;i<p.slides.items.length;i++){
 const s=p.slides.items[i];
 await fs.writeFile(`.icast-build/template/${i+1}.png`,new Uint8Array(await (await s.export({format:'png',scale:1})).arrayBuffer()));
 await fs.writeFile(`.icast-build/template/${i+1}.json`,await (await s.export({format:'layout',detail:'full'})).text());
 console.log(i+1,JSON.stringify(s.shapes.items.map(x=>({id:x.id,name:x.name,text:x.text.toString(),pos:x.position,style:x.text.style}))), 'TABLES',s.tables.items.length,'CHARTS',s.charts.items.length);
}
