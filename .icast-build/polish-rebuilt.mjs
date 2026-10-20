import fs from 'node:fs/promises';
import {Presentation,PresentationFile} from '@oai/artifact-tool';
process.on('uncaughtException',e=>{console.error(e.message,e.stack?.split('\n').filter(x=>x.includes('polish-rebuilt')).join('\n'));process.exit(1)});
const proto=JSON.parse(await fs.readFile('.icast-build/rebuilt/presentation.json','utf8'));
for(const im of proto.images??[])if(im.data)im.data=Uint8Array.from(Object.values(im.data));
for(const font of proto.fonts??[])for(const f of font.embeddedFonts??[])if(f.data)f.data=Uint8Array.from(Object.values(f.data));
const p=await Presentation.load(proto);
const s=p.slides.items[2];
for(const [name,value] of [['Question one','How does lower prevalence affect\nretrieval across pathologies and models?'],['Question two','Does contrastive adaptation improve\nretrieval over classification when both\nstart from the same SwAV checkpoint?']]){
 const q=s.shapes.items.find(x=>x.name===name);q.text=value;q.text.style={fontFamily:'Roboto',fontSize:28,color:'#29333F'};
}
const q=p.slides.items[9].shapes.items.find(x=>x.name==='Significance statement');q.text='Conditions show a\nsignificant SupCon gain\nover SwAV-CLS.';q.text.style={fontFamily:'Roboto',fontSize:27,color:'#29333F'};
const label=p.slides.items[8].shapes.add({name:'Endpoint metric label',geometry:'textbox',position:{left:72,top:112,width:1136,height:28},fill:'none',line:{fill:'none',width:0}});label.text='Mean Precision@10 at 5% and 0.5% target prevalence';label.text.style={fontFamily:'Roboto',fontSize:21,color:'#566377'};
await(await PresentationFile.exportPptx(p)).save('.icast-build/rebuilt/candidate-polished.pptx');
for(let i=0;i<p.slides.items.length;i++)await fs.writeFile(`.icast-build/rebuilt/final-${i+1}.png`,new Uint8Array(await(await p.slides.items[i].export({format:'png',scale:1})).arrayBuffer()));
console.log('POLISHED');
